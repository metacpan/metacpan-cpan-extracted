package SQL::Inserter;

use 5.008;
use strict;
use warnings;

use Carp;
use Exporter 'import';

=head1 NAME

SQL::Inserter - Efficient buffered DBI inserter and fast INSERT SQL builder

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

our @EXPORT_OK = qw(simple_insert multi_insert_sql);

=head1 SYNOPSIS

  use SQL::Inserter;

  my $sql = SQL::Inserter->new(
    dbh    => $dbh,
    table  => 'table',
    cols   => [qw/col1 col2.../],
    buffer => 100?   # Default buffer is 100 rows
  );

  # Fastest method: pass single or multiple rows of data as an array
  $sql->insert($col1_row1, $col2_row1, $col1_row2...);

  # You can manually flush the buffer at any time with no argument on insert
  # (otherwise there is auto-flush on the object's destruction)
  $sql->insert();

  # Alternative, pass a single row as a hash, allows SQL code passed as
  # references instead of values (no need to define cols in constructor)
  $sql->insert({
    column1 => $data1,
    column2 => \'NOW()',
    ...
  });

  # There are also functions to just get the SQL statement and its bind vars
  # similar to SQL::Abstract or SQL::Maker insert, but with much less overhead:
  my ($sql, @bind) = simple_insert($table, {col1=>$val...});

  # Multi-row variant:
  my ($sql, @bind) = simple_insert($table, [{col1=>$val1...},{col1=>$val2...},...]);

  # Or, construct an SQL statement with placeholders for a given number of rows:
  my $sql = multi_insert_sql('table', [qw/col1 col2.../], $num_of_rows);

=head1 DESCRIPTION

SQL::Inserter's main lightweight OO interface will let you do L<DBI> inserts as
efficiently as possible by managing a multi-row buffer and prepared statements.

You only have to select the number of rows for the buffered writes (default is 100)
and choose whether to pass your data in arrays (fastest, requires all data to be bind
values, will execute the same prepared statement every time the buffer is full) or
hashes (allows SQL code apart from plain values).

It also provides lightweight functions that return the SQL queries to be used manually,
similar to C<SQL::Abstract::insert>, but much faster.

C<INSERT IGNORE> and C<ON DUPLICATE KEY UPDATE> variants supported for MySQL/MariaDB.

=head1 EXPORTS

On request: C<simple_insert> C<multi_insert_sql>.

=head1 CONSTRUCTOR

=head2 C<new>

  my $sql = SQL::Inserter->new(
    dbh        => $dbh,
    table      => $table,
    cols       => \@column_names?,
    buffer     => 100?,
    duplicates => $ignore_or_update?,
    null_undef => $convert_undef_to_NULL?
  );

Creates an object to insert data to a specific table. Buffering is enabled by default
and anything left on it will be written when the object falls out of scope / is destroyed.

Required parameters:

=over 4

=item * C<dbh> : A L<DBI> database handle.

=item * C<table> : The name of the db table to insert to. See L</"NOTES"> if you
are using a restricted word for a table name.

=back

Optional parameters:

=over 4

=item * C<cols> : The names of the columns to insert. It is required if arrays are
used to pass the data. With hashes they are optional (the order will be followed
if they are defined). See L</"NOTES"> if you are using any restricted words for
column names.

=item * C<buffer> : Max number of rows to be held in buffer before there is a write.
The buffer flushes (writes contents) when the object is destroyed. Setting it to 1
writes each row separately (least efficient). For small rows you can set buffer to
thousands. The default is a (conservative) 100 which works with big data rows.

=item * C<duplicates> : For MySQL, define as C<'ignore'> or C<'update'> to get an
C<INSERT IGNORE> or C<ON DUPLICATE KEY UPDATE> query respectively. See L</"NOTES">
for details on the latter.

=item * C<null_undef> : Applies to the hash inserts only. If true, any undefined
values will be converted to SQL's C<NULL> (similar to the C<SQL::Abstract> default).
The default behaviour will leave an undef as the bind variable, which may either
create an empty string in the db or give an error depending on your column type and
db settings.

=back

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};
    bless($self, $class);

    $self->{dbh}    = $args{dbh} || croak("dbh parameter (db handle) required.");
    $self->{table}  = $args{table} || croak("table parameter required.");
    $self->{cols}   = $args{cols};
    $self->{buffer} = $args{buffer} || 100;
    $self->{dupes}  = $args{duplicates};
    $self->{null}   = $args{null_undef};
    if ($self->{dupes}) {
        $self->{ignore} = 1 if $self->{dupes} eq "ignore";
        $self->{update} = 1 if $self->{dupes} eq "update";
    }
    $self->_cleanup();

    return $self;
}

=head1 METHODS

=head2 insert

  # Fastest array method. Only bind data is passed.
  my $ret = $sql->insert(@column_data_array);

  # Alternative, allows SQL code as values in addition to bind variables
  my $ret = $sql->insert(\%row_data);

  # No parameters will force emtying of buffer (db write)
  my $ret = $sql->insert();

The main insert method. Returns the return value of the last C<execute> statement
if there was one called, 0 otherwise (buffer not full.

It works in two main modes, by passing an array or a hashref:

=over 4

=item Array mode

Pass the data for one or more rows in a flat array, buffering will work automatically
based on your C<buffer> settings. Obviously your C<@column_data_array> has to contain
a multiple of the number of C<cols> defined on the constructor.

This is the fastest mode, but it only allows simple bind values. Any undefined values
will be passed directly to DBI->execute, which may or may not be what you expect -
there will not be any explicit conversion to SQL C<NULL>.

=item Hash mode

Pass a reference to a hash containing the column names & values for a single row
of data. If C<cols> was not defined on the constructor, the columns from the first
data row will be used instead. For subsequent rows any extra columns will be disregarded
and any missing columns will be considered to have an C<undef> (which can be
automatically converted to C<NULL> if the C<null_undef> option was set).

=item Flushing the buffer

Calling C<insert> with no arguments forces a write to the db, flushing the buffer.
You don't have to call this manually as the buffer will be flushed when the object
is destroyed (e.g. your object falls out of scope).

=item Mixing modes

You can theoretically mix modes, but only when the buffer is empty e.g. you can start
with the array mode, flush the buffer and continue with hash mode (C<cols> will be
defined from the array mode). Or you can start with hash mode (so C<cols> will be defined
from the very first hash), and after flushing the buffer you can switch to array mode.

=back

=cut

sub insert {
    my $self = shift;

    return $self->_hash_insert(@_) if $_[0] and ref($_[0]);

    my $ret = 0;
    if (@_) {

        croak("Calling insert without a hash requires cols defined in constructor")
            unless $self->{cols};
    
        croak("Insert arguments must be multiple of cols")
            if scalar(@_) % scalar @{$self->{cols}};

        croak("Insert was previously called with hash argument (still in buffer)")
            if $self->{hash_buffer};

        while (@_) {
            my $rows = scalar(@_) / scalar @{$self->{cols}};
            my $left = $self->{buffer} - $self->{buffer_counter}; # Space left in buffer

            if ($rows > $left) { # Can't fit buffer
                my $max = $left * scalar @{$self->{cols}};
                push @{$self->{bind}}, splice(@_,0,$max);
                $self->{buffer_counter} = $self->{buffer};
            } else {
                push @{$self->{bind}}, splice(@_);
                $self->{buffer_counter} += $rows;
            }
            $ret = $self->_write_full_buffer() if $self->{buffer_counter} == $self->{buffer};
        }
    } elsif ($self->{buffer_counter}) { # Empty the buffer
        $ret = $self->_empty_buffer();
    }
    return $ret;
}

=head1 ATTRIBUTES

=head2 C<last_retval>

  my $val = $sql->{last_retval}

The return value of the last DBI C<execute()> is stored in this attribute. On a successful
insert it should contain the number of rows of that statement. Note that an C<insert>
call, depending on the buffering, may call C<execute()> zero, one or more times.

=head2 C<row_total>

  my $total = $sql->{row_total}

Basically a running total of the return values, for successful inserts it shows you
how many rows were inserted into the database. It will be undef if no C<execute()> has
been called.

=head2 C<buffer_counter>

  my $count = $sql->{buffer_counter}

Check how many un-inserted data rows the buffer currently holds.

=head1 FUNCTIONS

=head2 simple_insert

  # Single row
  my ($sql, @bind) = simple_insert($table, \%fieldvals, \%options);

  # Multi-row
  my ($sql, @bind) = simple_insert($table, [\%fieldvals_row1,...], \%options);

Returns the SQL statement and bind variable array for a hash containing the row
columns and values. Values are treated as bind variables unless they are references
to SQL code strings. E.g. :

  my ($sql, @bind) = simple_insert('table', {foo=>"bar",when=>\"NOW()"});
  ### INSERT INTO table (foo, when) VALUES (?,NOW())

The function also accepts an array of hashes to allow multi-row inserts:

  my ($sql, @bind) = simple_insert('table', [{foo=>"foo"},{foo=>"bar"}]);
  ### INSERT INTO table (foo) VALUES (?),(?)

The first row (element in array) needs to contain the superset of all the columns
that you want to insert, if some of your rows have undefined column data.

Options:

=over 4
 
=item * C<null_undef> : If true, any undefined values will be converted to SQL's
C<NULL> (similar to the C<SQL::Abstract> default). The default behaviour will leave
an undef as the bind variable, which may either create an empty string in the db or
give an error depending on your column type and db settings.

=item * C<duplicates> : For MySQL, define as C<'ignore'> or C<'update'> to get an
C<INSERT IGNORE> or C<ON DUPLICATE KEY UPDATE> query respectively. See L</"NOTES">
for details on the latter.

=back

=cut

sub simple_insert {
    my $table  = shift;
    my $fields = shift;
    my $opt    = shift;

    my ($placeh, @bind, @cols);
    if (ref($fields) eq 'ARRAY') {
        @cols = keys %{$fields->[0]};
        my @rows;
        foreach my $f (@$fields) {
            my ($row, @b) = _row_placeholders($f, \@cols, $opt->{null_undef});
            push @rows, $row;
            push @bind, @b;
        }
        $placeh = join(",\n", @rows);
    } else {
        @cols = keys %$fields;
        ($placeh, @bind) = _row_placeholders($fields, \@cols, $opt->{null_undef});
    }

    return _create_insert_sql(
        $table, \@cols, $placeh, $opt->{duplicates}
    ), @bind;
}

=head2 multi_insert_sql

 my $sql = multi_insert_sql(
     $table,
     \@columns,         # names of table columns
     $num_of_rows?,     # default = 1
     $duplicates?       # can be set as ignore/update in case of duplicate key (MySQL)
 );

Builds bulk insert query (single insert is possible too), with ability for
ignore/on duplicate key update variants for MySQL.

Requires at least the name of the table C<$table> and an arrayref with the column
names C<\@columns>. See L</"NOTES"> if you want to quote table or column names.

Optional parameters:

=over 4
 
=item * C<$num_of_rows> : By default it returns SQL with bind value placeholders
for a single row. You can define any number of rows to use with multi-row bind
variable arrays.

=item * C<$duplicate> : For MySQL, passing C<'ignore'> as the 4th argument returns
an C<INSERT IGNORE> query. Passing C<'update'> as the argument returns a query
containing an `ON DUPLICATE KEY UPDATE` clause (see L</"NOTES"> for further details).

=back

=cut

sub multi_insert_sql {
    my $table    = shift;
    my $columns  = shift;
    my $num_rows = shift || 1;
    my $dupe     = shift;

    return unless $table && $columns && @$columns;

    my $placeholders =
        join(",\n", ('(' . join(',', ('?') x @$columns) . ')') x $num_rows);

    return _create_insert_sql($table, $columns, $placeholders, $dupe);
}

## Private methods

sub _hash_insert {
    my $self   = shift;
    my $fields = shift;
    my $ret    = 0;

    croak("Insert was previously called with an array argument (still in buffer)")
        if $self->{buffer_counter} && !$self->{hash_buffer};

    $self->{buffer_counter}++;
    $self->{cols} = [keys %$fields] if !defined($self->{cols});
    my ($row, @bind) = _row_placeholders($fields, $self->{cols}, $self->{null});
    push @{$self->{hash_buffer}}, $row;
    push @{$self->{bind}}, @bind;

    $ret = $self->_write_hash_buffer() if $self->{buffer_counter} == $self->{buffer};

    return $ret;
}

sub _write_full_buffer {
    my $self = shift;

    $self->{full_buffer_insert} = $self->_prepare_full_buffer_insert()
        if !$self->{full_buffer_insert};

    $self->_execute($self->{full_buffer_insert});
    $self->_cleanup();

    return $self->{last_retval};
}

sub _prepare_full_buffer_insert {
    my $self = shift;
    $self->{full_buffer_insert} = $self->{dbh}->prepare(
        multi_insert_sql(map {$self->{$_}} qw/table cols buffer dupes/)
    );
}

sub _empty_buffer {
    my $self = shift;

    return $self->_write_hash_buffer() if $self->{hash_buffer};

    my $rows = scalar(@{$self->{bind}}) / scalar @{$self->{cols}};
    my $sth  = $self->{dbh}->prepare(
        multi_insert_sql(
             $self->{table},
             $self->{cols},
             $rows,
             $self->{dupes}
         )
    );
    $self->_execute($sth);
    $self->_cleanup();

    return $self->{last_retval};
}

sub _write_hash_buffer {
    my $self = shift;

    my $placeh = join(",\n", @{$self->{hash_buffer}});
    my $sth    = $self->{dbh}->prepare(
        _create_insert_sql(
            $self->{table}, $self->{cols}, $placeh, $self->{dupes}
        )
    );
    $self->_execute($sth);
    $self->_cleanup();

    return $self->{last_retval};
}

sub _execute {
    my $self = shift;
    my $sth  = shift;

    $self->{row_total}   = 0 if !defined($self->{row_total});
    $self->{last_retval} = $sth->execute(@{$self->{bind}});
    $self->{row_total} += $self->{last_retval} if $self->{last_retval};
}

sub _cleanup {
    my $self = shift;
    $self->{bind}           = undef;
    $self->{hash_buffer}    = undef;
    $self->{buffer_counter} = 0;
}

sub DESTROY {
    my $self = shift;
    # Empty buffer
    $self->_empty_buffer() if $self->{buffer_counter};
}

## Private functions

sub _create_insert_sql {
    my $table   = shift;
    my $columns = shift;
    my $placeh  = shift;
    my $dupe    = shift || "";

    my $ignore = ($dupe eq 'ignore') ? ' IGNORE' : '';
    my $cols   = join(',', @$columns);
    my $sql    = "INSERT$ignore INTO $table ($cols)\nVALUES $placeh";

    $sql .= _on_duplicate_key_update($columns) if $dupe eq 'update';

    return $sql;
}

sub _row_placeholders {
    my $fields = shift;
    my $cols   = shift;
    my $null   = shift;
    my @bind   = ();
    my $sql    = "(";

    my $val;

    foreach my $key (@$cols) {
        $fields->{$key} = \"NULL" if $null && !defined($fields->{$key});

        if (ref($fields->{$key})) {
            $val = ${$fields->{$key}};
        } else {
            $val = "?";
            push @bind, $fields->{$key};
        }
        $sql .= "$val,";
    }

    chop($sql) if @$cols;

    return "$sql)", @bind;
}

sub _on_duplicate_key_update {
    my $columns = shift;
    return "\nON DUPLICATE KEY UPDATE "
        . join(',', map {"$_=VALUES($_)"} @$columns);
}

=head1 NOTES

=head2 Using reserved words as object names

If you are using reserved words as table/column names (which is strongly discouraged),
just include the appropriate delimiter in the C<table> or C<cols> parameter. E.g. for
MySQL with columns named C<from> and C<to> you can do:

 cols => [qw/`from` `to`/]

For PostgreSQL or Oracle you'd do C<[qw/"from" "to"/]>, for SQL Server C<[qw/[from] [to]/]> etc.

=head2 On duplicate key update

The C<duplicates =E<gt> 'update'> option creates an C<ON DUPLICATE KEY UPDATE> clause
for the query. E.g.:

 my $sql = multi_insert_sql('table_name', [qw/col1 col2/], 2, 'update');

will produce:

 ## INSERT INTO table_name (col1,col2) VALUES (?,?),(?,?) ON DUPLICATE KEY UPDATE col1=VALUES(col1),col2=VALUES(col2)

Note that as of MySQL 8.0.20 the C<VALUES> in C<UPDATE> is deprecated (row alias is
used instead), so this functionality might need to be updated some day if C<VALUES> is
removed completely.

=head2 Output whitespace

No spaces are added to the output string beyond the minimum. However, there is a new
line (C<\n>) added for each row of value placeholders - mainly to easily count the
number of rows from the string.
Also, the C<ON DUPLICATE KEY UPDATE> clause is on a new line.

=head2 Error handling

The module does not do any error handling on C<prepare>/C<execute> statements,
you should use L<DBI>'s C<RaiseError> and C<HandleErrror>.

=head2 Performance

The OO interface has minimal overhead. The only consideration is that if your rows
do not contain particularly large amounts of data, you may want to increase the buffer
size which is at a modest 100 rows.

Internally, to construct the prepared statements it uses similar logic to the public
functions. C<simple_insert> is of particular interest as it is a minimalistic function
that may replace (similar interface / feature set) the C<insert> functions from
C<SQL::Abstract> or C<SQL::Maker> while being over 40x faster than the former and
around 3x faster than the latter. The included C<bench/benchmark.pl> script gives
an idea (results on an M1 Pro Macbook):

 Compare SQL::Abstract, SQL::Maker, simple_insert:
                     Rate Abstract Abstract cached Maker Maker cached simple_insert
 Abstract          4207/s       --             -6%  -90%         -91%          -98%
 Abstract cached   4482/s       7%              --  -90%         -90%          -98%
 Maker            44245/s     952%            887%    --          -4%          -76%
 Maker cached     46205/s     998%            931%    4%           --          -75%
 simple_insert   187398/s    4355%           4081%  324%         306%            --
 
 Compare simple_insert, multi_insert_sql for single row:
                      Rate    simple_insert multi_insert_sql
 simple_insert    190037/s               --             -76%
 multi_insert_sql 797596/s             320%               --

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests either on L<GitHub|https://github.com/SpareRoom/SQL-Inserter> (preferred), or on RT
(via the email <bug-sql-inserter at rt.cpan.org>, or L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Inserter>).

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 GIT

L<https://github.com/SpareRoom/SQL-Inserter>

=head1 CPAN

L<https://metacpan.org/pod/SQL::Inserter>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2023, SpareRoom

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of SQL::Inserter
