#
# from directory above this, use e.g.,
#
#    $ prove -l lib t/prove.t
#

package Org::ReadTables v0.0.4 {

    use v5.38;
    use List::Util qw(any);

    use feature 'signatures';
    no warnings qw(experimental::signatures);

    ################
    # Parse tables from an Org-mode file into our database
    #
    ################

    use Org::Parser;

    sub new ($class, %args) {
        my $self = bless {}, $class;
        foreach my $arg (qw(dbh table tables cb cb_table)) {
            $self->{$arg} = $args{$arg} if defined $args{$arg};
        }
        if (defined $self->{dbh}) {
            if (ref $self->{dbh}) {
                if (!$self->{dbh}->can('insert')) {
                    warn "Database handle should provide an 'insert' method";
                }
            } else {
                warn "'dbh' should be a database handle";
            }
        }
        return $self;
    }

    sub errors ($self) {
        return $self->{errors};
    }

    sub inserted ($self, $table = undef) {
        if (defined $table) {
            return defined $self->{inserted} && exists $self->{inserted}->{$table} ? $self->{inserted}->{$table} : undef;
        } else {
            return $self->{inserted};  # All tables
        }
        return $self->{inserted};
    }

    sub saved ($self, $table = undef) {
        if (defined $table) {
            return defined $self->{saved} && exists $self->{saved}->{$table} ? $self->{saved}->{$table} : undef;
        } else {
            return $self->{saved};  # All tables
        }
    }

    sub secondary ($self, $table = undef) {
        if (defined $table) {
            return defined $self->{alt} && exists $self->{alt}->{$table} ? $self->{alt}->{$table} : undef;
        } else {
            return $self->{alt};  # All tables
        }
    }

    sub parse ($self, $text, $default_table = undef) {

        state $table; # as a 'state' so the nested 'walk' subroutine can use it
        state $db;
        state $errors = [];
        state $inserted = 0; # 'state' so it can be seen by 'walk'
        state $saved; # ...and by 'flush_row'
        state $self_copy;
        state $fixed_columns;
        state $pivot;
        state $data_column;
        state $caption;

        sub flush_row {
            my ($columns, $values) = @_;
            my $save_fields;
            return unless defined $table && length($table);
            foreach my $generated ( 0 .. (defined $pivot ? scalar $pivot->{column_ids}->@* -1 : 0) ) {
                $save_fields = { defined $fixed_columns ? %$fixed_columns : () }; # Start with a copy of any fixed columns
                if (defined $pivot) {
                    # Save ordinary columns
                    foreach my $c ($pivot->{ordinary_column_ids}->@*) {
                        $save_fields->{$columns->[$c]} = $values->[$c];
                    }
                    $save_fields->{$pivot->{column_name}} = $pivot->{columns}->[$generated];
                    next unless defined ( $save_fields->{$pivot->{data_column}} = $values->[$pivot->{column_ids}->[$generated]]);
                } else {
                    @{$save_fields}{@{$columns}} = @{$values};
                }
                if ( defined $self_copy->{cb} ) {
                    if ( $self_copy->{cb}->($table, $save_fields) ) {
                        do { push @{$saved->{$table}}, $save_fields; 1; };
                        $inserted++;
                    }
                } elsif ( defined $db ?
                          eval { $db->insert($table, $save_fields); 1; } :
                          do { push @{$saved->{$table}}, $save_fields; 1; } ) {
                    $inserted++;
                } else {
                    push @{$errors} , [ $save_fields, $@ ];
                }
            }
        }

        sub walk {
            # Ignore leading TableHLine
            # Find first row(s) with TableCell and accumulate column names
            # Require a TableHLine to proceed
            # For each TableRow, accumulate column values and save row.
            #
            # NOTE: Must call an extra time with a 'fake' TableRow afterwards,
            # to flush the final row.

            my ($el, $level) = @_;

            state $in_header;
            state $found_header_row;
            state $column;
            state $is_data_row;
            state @columns;
            state @values;
            if ((ref $el) =~ /Table\z/i) {
                $in_header = 1;
                $found_header_row = 0;
                $inserted = 0;
                @columns = ();
                @values = ();
                $pivot = defined $data_column ? {data_column => $data_column} : undef;
            } elsif ((ref $el) =~ /TableHLine\z/i) {
                if ($found_header_row) {
                    #
                    # Skip this table if the callback returns a false value.
                    #
                    @columns = map {lc} @columns if $in_header;
                    my @reported_columns = @columns;
                    if (defined $pivot) { # Remove pivoted columns
                        if (defined $pivot->{data_column} && (!exists $pivot->{column_ids} || !scalar $pivot->{column_ids}->@*)) {
                            # 'data' was used as a fixed value, without any pivot columns being defined.
                            $fixed_columns->{'data'} = $pivot->{data_column};
                            undef $pivot;
                        } else {
                            foreach my $c (0..$#columns) { # Exclude pivoted columns from ordinary processing
                                push $pivot->{ordinary_column_ids}->@*, $c unless any { $_==$c } $pivot->{column_ids}->@*;
                            }
                            @reported_columns = map { $columns[$_] } $pivot->{ordinary_column_ids}->@*;
                            if (defined $pivot->{alt}) {
                                $self_copy->{alt}->{$table} = { lc($pivot->{column_name}) => $pivot->{alt} };
                            }
                        }
                    }
                    if ($in_header && defined $self_copy->{cb_table}) {
                        undef $table unless $self_copy->{cb_table}->({ name => $table,
                                                                       nameref => \$table, # Modifiable
                                                                       ( defined $fixed_columns ? (fixed => $fixed_columns) : ()),
                                                                       columns => \@columns,
                                                                       caption => $caption,
                                                                   });
                    }
                    $in_header = 0;
                }
            } elsif ((ref $el) =~ /TableRow\z/i) {
                if ($in_header) {
                    foreach my $c (0 .. scalar @columns-1) {
                        if ($columns[$c] =~ /(.+)>/) {
                            last unless defined $pivot; # Skip this row if no usable data column
                            if (!defined $pivot->{column_name}) {  # Create new pivot table
                                $pivot->{column_name} = $1;
                                $pivot->{column_ids} = [grep { $_ != $c && defined $columns[$_] } 0 .. scalar @columns-1];
                                $pivot->{columns} = [@columns[$pivot->{column_ids}->@*]];
                                last;
                            } else { # Define a secondary table
                                my $row_name = $1;
                                foreach my $cci (0 .. scalar $pivot->{column_ids}->@* -1 ) { #
                                    my $cc = ($pivot->{column_ids}->[$cci]);
                                    my $col_key = lc( $pivot->{columns}->[$cci] );
                                    my $row_key = lc( $row_name );
                                    my $val = \$pivot->{alt}->{$col_key}->{$row_key};
                                    $$val = length $$val ? "$$val $columns[$cc]" : $columns[$cc];
                                }
                            }
                        }
                    }
                }
                if ($is_data_row) { # Flush previous row
                    flush_row (\@columns, \@values);
                    $is_data_row = 0;
                }
                $found_header_row = 1;
                $column = -1;
                @values = ();
            } elsif ((ref $el) =~ /TableCell\z/i) {
                $column++;
            } elsif ((ref $el) =~ /Text\z/i) {
                if ($in_header) {
                    $columns[$column] = $el->as_string;
                } else {
                    $values[$column] = $el->as_string;
                    $is_data_row = 1;
                }
                $is_data_row = 1 unless ($in_header);
            }
        }

        my $orgp = Org::Parser->new;
        my $org_doc = $orgp->parse($text);
        my @tables = $org_doc->find('Table');
        $self_copy = $self;
        $saved = {};
        $errors = [];
        $db = $self->{dbh};

        foreach my $t (@tables) {
            # Look for NAME property as Settings element in
            # prev_siblings; also look for PROPERTIES drawer
            # (containing NAME property) in prev_siblings, ignoring
            # whitespace-only Text elements
            undef $table;
            my $prev_elem = $t->prev_sibling;
            undef $fixed_columns;
            undef $pivot;
            undef $data_column;

            if (defined $prev_elem) {
            ELEMENT:
                while (defined $prev_elem) {
                    # Only regard settings and drawers between headlines or tables.
                    last ELEMENT if ref $prev_elem eq 'Org::Element::Table';
                    # Formerly we looked for a
                    # 'Org::Element::Headline' here, but actually that
                    # would always be the *parent* element.  Perhaps
                    # we want to default to
                    # »$t->headline->title->as_string« ?

                    # NOTE: Internal links (»#+NAME: sometable«) are
                    # always followed by all-whitespace Text (see
                    # t/drawer.t in Org::Parser). Ignore them.
                    next ELEMENT if ref $prev_elem eq 'Org::Element::Text' &&
                        $prev_elem->as_string =~ /^\s*\z/;

                    if (ref $prev_elem eq 'Org::Element::Setting') {
                        # e.g., »#+NAME: sometable«
                        if ($prev_elem-> name =~ /^name\z/i) {
                            $table = $prev_elem->args->[0];
                        } elsif ($prev_elem-> name =~ /^data\z/i) {
                            $data_column = $prev_elem->args->[0];
                        } elsif ($prev_elem-> name =~ /^caption\z/i) {
                            $caption = $prev_elem->args->[0];
                        } elsif ($prev_elem->name =~ /^property\z/i && scalar @{$prev_elem->args} > 1) {
                            # Double quotes may be used around a
                            # string with spaces; otherwise this will
                            # add a single space between words.
                            $fixed_columns->{$prev_elem->args->[0]} =
                              join(' ',@{$prev_elem->args}[1..scalar @{$prev_elem->args}-1]);
                        }
                    } elsif (ref $prev_elem eq 'Org::Element::Drawer') {
                        # We regard the internal-link-target syntax
                        # «#+NAME: some_table» as meaning, Insert the
                        # following orgmode table into database table
                        # `some_table` (see orgmode manual §4.2
                        # "Internal Links")
                        #
                        # TODO: Verify column names and skip
                        # non-existent ones; otherwise, adding
                        # properties that do not map to sql column
                        # names will result in errors and no rows
                        # inserted!
                        #
                        foreach my $k ( keys %{$prev_elem->properties} ) {
                            if ($k =~ /^name\z/i) {
                                $table = $prev_elem->properties->{$k};
                            } elsif ($k =~ /^data\z/i) {
                                $data_column = $prev_elem->properties->{$k};
                            } else {
                                $fixed_columns->{$k} = $prev_elem->properties->{$k};
                            }
                        }
                        last ELEMENT unless !defined $table;
                        # Only process one drawer. If neither NAME nor
                        # default table (from new() or in parse()
                        # call) is given, this attached table will be
                        # skipped (see below).
                    }
                }
                continue {
                    $prev_elem = $prev_elem->prev_sibling;
                }
            }
            $table //= $default_table // $self->{table};

            # TODO: When NAME property is encountered, check against our `table` or
            # `tables` attributes to verify we can load this data
            next unless defined $table;
            if (defined $self->{tables} && ref $self->{tables} eq 'ARRAY') {
                next unless any { $table eq $_ } @{$self->{tables}};
            }

            $t->walk(\&walk);                     # Process all rows in this table
            walk(Org::Element::TableRow->new, 0); # Flush last row in final table
            $self->{errors} = $errors;
            $self->{inserted}->{$table} += $inserted ;
            $self->{saved} = $saved;
        }
        return $inserted;
    }

};

1;

=encoding utf8

=head1 NAME

Org::ReadTables - Import Org Mode tables into arrays, or
directly into database tables

=head1 SYNOPSIS

    use Org::ReadTables;

    my $op = Org::ReadTables->new( dbh => $dbh,
                                   table => 'example',
                                   tables => ['a_table']
                                 );
    # or:
    # When called without a 'dbh' argument, saves values
    # which can be retrieved via the 'saved' method.
    #
    my $op = Org::ReadTables->new( cb => \&row_callback,
                                   cb_table => \&table_callback,
                                 );
    # then:
    $op->parse( $mojo_file->slurp );

=head1 DESCRIPTION

L<Org::ReadTables> loads data from one or more C<Emacs> Org Mode
tables in an org file into a L<DBI> style database which supports the
C<SQL::Abstract/insert> method.  The underlying C<DBD> must also
support the C<returning> option for insertion.

For example, given the following .org file:

  #+NAME: LCCN_Serial
  | LCCN       | Publication           | City    | Start_Date |   End_Date |
  |------------+-----------------------+---------+------------+------------|
  | sn92024097 | Adahooniłigii         | Phoenix |            |            |
  | sn87062098 | Arizona Daily Citizen | Tucson  |            |            |
  | sn84020558 | Arizona Republican    | Phoenix |            | 1930-11-10 |
  | sn83045137 | Arizona Republic      | Phoenix | 1930-11-11 |            |

and a database containing a table called lccn_serial, the C<parse>
method would insert four rows into it, in the fields whose names are
given in the column headings.

The C<NAME:> org attribute specifies the table name; a default value
may be passed in the C<table> parameter to the C<new> method.
Additionally, a C<tables> array may be passed by reference against
which the names of such tables will be validated; table names not
listed will have their org tables skipped.

Table names may also be specified in a C<Name> property (not
case-sensitive) in an Orgmode Drawer preceding the table.  For
example:

    :PROPERTIES:
    :Name: Locos
    :END:
    | Wheel Arrangement | Locomotive Type |
    |-------------------+-----------------|
    | oo-oo>            | American        |
    | ooo-oo>           | Mogul           |

Additionally, with the Drawer format, fixed column values may
optionally be specified:

    :PROPERTIES:
    :Name: Locos
    :Country: .us
    :END:
    | Wheel Arrangement | Locomotive Type |
    |-------------------+-----------------|
    | oo-oo>            | American        |
    | ooo-oo>           | Mogul           |

which would have the effect of adding a 'country' column to the right
of each record, all having the value '.us'.

=head2 Pivot Tables

When it is desirable to enter data two-dimensionally, a construct like
this may be used:

    :PROPERTIES:
    :Name: sizes
    :Data: size_desc
    |     class> |     A |   B   |  C  |
    |  size_code |       |       |     |
    |------------+-------+-------+-----|
    |          1 |   1-2 | 22-26 |     |
    |          2 |   3-4 | 26-30 | XS  |
    |          3 |   5-6 | 30-34 | S   |

where the `Data` property determines which field (column) is assigned
the pivoted value. The above table would generate eight data records
for the `sizes` table:

    size_code='1', class='A', size_desc='1-2'
    size_code='1', class='B', size_desc='22-26'
    size_code='2', class='A', size_desc='3-4'
    size_code='2', class='B', size_desc='26-30'
    size_code='2', class='C', size_desc='XS'
    size_code='3', class='A', size_desc='5-6'
    size_code='3', class='B', size_desc='30-34'
    size_code='3', class='C', size_desc='S'

Note that no record is created for class 'C' with size_code '1' as
that entry in the pivot table is blank.

Values in consecutive rows with the same field name will be
concatenated, separated by a space. Train names in the table below
will be "Texas Eagle" and "Southwest Chief" for example.

    | Train_no>   | 21    | 22    | 3         | 4         |
    | Train_name> | Texas | Texas | Southwest | Southwest |
    | Train_name> | Eagle | Eagle | Chief     | Chief     |
    | Station     |       |       |           |           |
    |-------------+-------+-------+-----------+-----------|

Also note, renaming pivot columns in the table callback is not
permitted.

=head1 ATTRIBUTES

L<Org::ReadTables> implements the following attributes.

=head2 inserted

Returns a hashref, each element's key being the name of a table into
which rows were inserted, and its value being the number of rows
inserted into that table.

=head2 errors

Returns a reference to an array, each entry in which itself be an
array whose values are:

=over 4

=item
a hash (the column names and values to be inserted), and

=item
the resulting error report from that insertion

=back

=head1 METHODS

=head2 new

Creates a new Org::ReadTables object.  Parameters include:

=head3 dbh

should be an open database handle from, e.g., L<DBD::SQLite>,
L<Mojo::SQLite> or L<Mojo::Pg>.  Each row to be saved will invoke the
'insert' method of this handle (or, more generally, class instance);
no other methods will be called, so any object that has provides
'insert' may be used. For each found record, the insert() method of
this object will be called.  Note that no protection is given here
against invalid column names or other database errors.

=head3 cb

Reference to a callback function to be called for each found record,
in tables which are processed.  Parameters passed are the name of the
table, and a reference to a hash of the record's column-names and
values.  The function should return the count of records successfully
saved (either 0 or 1, usually).

=head3 cb_table

Reference to a callback function to be called at the start of
processing of a new table, as they are found in the orgfile.
The callback will be passed one argument, a hash with keys:

=over

=item *

name: A string with the name of the table

=item *

nameref: A reference to the table-name string.  This may be changed by
the callback.

=item *

columns: A reference to the array of the names of the columns in the
table.  The contents of the referred array may be maniuplated to match
the actual database field names, for example.

=item *

fixed: A reference to a hash of fixed column key/values. This may also
be changed by the callback.

=item *

caption: The caption, if any, attached above the table itself

=item *

data_column: The name of the data column in a pivot table

=back

...and should return a true value if the table is to be processed or
saved, or a false or 'undef' value to skip the table (the 'cb'
callback will not be called for rows in such tables).

=head3 table

(optional) the default table name, which will be used for all unnamed
tables.  Use an Orgmode property C<NAME> before each table to name it,
as:

    #+NAME: PostalAbbrev
    | Code | State   |
    |------+---------|
    | AZ   | Arizona |
    | FL   | Florida |
    | KS   | Kansas  |

=head3 tables

(optional) a reference to a list of valid table names to process
(others will be ignored).  If C<tables> is not given, C<table> should
be present; otherwise for input not containing an Orgmode C<NAME>
property, no processing will occur.

=head2 parse

  $op->parse($text, [$default_table]);

Parses the given text which should be in Org Mode format.  It is the
caller's responsibility to slurp a file or other data source.  The
optional second parameter will be used as the default name of any
table not having an Orgmode C<NAME> property, overriding any C<table>
value provided via the C<new> method.

=head2 saved

  $op->saved();
  $op->saved->($selected_table);

Returns a hash of the tables read; each key is a table name, the value
being an array of hashes of the rows.  If a table name is passed,
returns the array of hashes only for that particular table, or undef
if no such table existed in any input.

=head2 inserted

  $op->inserted();
  $op->inserted->($selected_table);

With no parameter, returns a hash of the tables processed and a count
of rows found (and presumably inserted) in each.  With a parameter,
returns the count of rows for that table, or undef if no such table
was processed.

=head1 BUGS

Report any issues to the author.

=head1 AUTHOR

William Lindley, C<wlindley@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2025, William Lindley.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Org::Parser>, L<https://orgmode.org/>

=cut
