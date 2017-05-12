package Parse::Taxonomy::MaterializedPath;
use strict;
use parent qw( Parse::Taxonomy );
use Carp;
use Text::CSV_XS;
use Scalar::Util qw( reftype );
use List::Util qw( max );
use Cwd;
our $VERSION = '0.24';
use Parse::Taxonomy::Auxiliary qw(
    path_check_fields
    components_check_fields
);

=head1 NAME

Parse::Taxonomy::MaterializedPath - Validate a file for use as a path-based taxonomy

=head1 SYNOPSIS

    use Parse::Taxonomy::MaterializedPath;

    # 'file' interface: reads a CSV file for you

    $source = "./t/data/alpha.csv";
    $self = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );

    # 'components' interface:  as if you've already read a
    # CSV file and now have Perl array references to header and data rows

    $self = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => $fields,
            data_records    => $data_records,
        }
    } );

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Parse::Taxonomy::MaterializedPath constructor.

=item * Arguments

Single hash reference.  There are two possible interfaces: C<file> and C<components>.

=over 4

=item 1 C<file> interface

    $source = "./t/data/alpha.csv";
    $self = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
        path_col_idx    => 0,
        path_col_sep    => '|',
        %TextCSVoptions,
    } );

Elements in the hash reference are keyed on:

=over 4

=item * C<file>

Absolute or relative path to the incoming taxonomy file.
B<Required> for this interface.

=item * C<path_col_idx>

If the column to be used as the "path" column in the incoming taxonomy file is
B<not> the first column, this option must be set to the integer representing
the "path" column's index position (count starts at 0).  Optional; defaults to C<0>.

=item * C<path_col_sep>

If the string used to distinguish components of the path in the path column in
the incoming taxonomy file is not a pipe (C<|>), this option must be set.
Optional; defaults to C<|>.

=item *  Text::CSV_XS options

Any other options which could normally be passed to C<Text::CSV_XS-E<gt>new()> will
be passed through to that module's constructor.  On the recommendation of the
Text::CSV documentation, C<binary> is always set to a true value.

=back

=item 2 C<components> interface

    $self = Parse::Taxonomy::MaterializedPath->new( {
        components  => {
            fields          => $fields,
            data_records    => $data_records,
        }
    } );

Elements in this hash are keyed on:

=over 4

=item * C<components>

This element is B<required> for the
C<components> interface. The value of this element is a hash reference with two keys, C<fields> and
C<data_records>.  C<fields> is a reference to an array holding the field or
column names for the data set.  C<data_records> is a reference to an array of
array references, each of the latter arrayrefs holding one record or row from
the data set.

=item * C<path_col_idx>

Same as in C<file> interface above.

=item * C<path_col_sep>

Same as in C<file> interface above.

=back

=back

=item * Return Value

Parse::Taxonomy::MaterializedPath object.

=item * Comment

C<new()> will throw an exception under any of the following conditions:

=over 4

=item * Argument to C<new()> is not a reference.

=item * Argument to C<new()> is not a hash reference.

=item * In the C<file> interface, unable to locate the file which is the value of the C<file> element.

=item * Argument to C<path_col_idx> element is not an integer.

=item * Argument to C<path_col_idx> is greater than the index number of the
last element in the header row of the incoming taxonomy file, I<i.e.,> the
C<path_col_idx> is wrong.

=item * The same field is found more than once in the header row of the
incoming taxonomy file.

=item * Unable to open or close the incoming taxonomy file for reading.

=item * In the column designated as the "path" column, the same value is
observed more than once.

=item * C<id>, C<parent_id>, C<name>, C<lft> and C<rgh> are reserved terms.
One or more columns is named with a reserved term.

=item * A non-parent node's parent node cannot be located in the incoming taxonomy file.

=item * A data row has a number of fields different from the number of fields
in the header row.

=back

=back

=cut

sub new {
    my ($class, $args) = @_;
    my $data;

    croak "Argument to 'new()' must be hashref"
        unless (ref($args) and reftype($args) eq 'HASH');
    my $argscount = 0;
    $argscount++ if $args->{file};
    $argscount++ if $args->{components};
    croak "Argument to 'new()' must have either 'file' or 'components' element"
        if ($argscount == 0);
    croak "Argument to 'new()' must have either 'file' or 'components' element but not both"
        if ($argscount == 2);

    if (exists $args->{path_col_idx}) {
        croak "Argument to 'path_col_idx' must be integer"
            unless $args->{path_col_idx} =~ m/^\d+$/;
    }
    $data->{path_col_idx} = delete $args->{path_col_idx} || 0;
    $data->{path_col_sep} = exists $args->{path_col_sep}
        ? $args->{path_col_sep}
        : '|';
    if (exists $args->{path_col_sep}) {
        $data->{path_col_sep} = $args->{path_col_sep};
        delete $args->{path_col_sep};
    }
    else {
        $data->{path_col_sep} = '|';
    }

    if ($args->{components}) {
        croak "Value of 'components' element must be hashref"
            unless (ref($args->{components}) and reftype($args->{components}) eq 'HASH');
        for my $k ( qw| fields data_records | ) {
            croak "Value of 'components' element must have '$k' key-value pair"
                unless exists $args->{components}->{$k};
            croak "Value of '$k' element must be arrayref"
                unless (ref($args->{components}->{$k}) and
                    reftype($args->{components}->{$k}) eq 'ARRAY');
        }
        for my $row (@{$args->{components}->{data_records}}) {
            croak "Each element in 'data_records' array must be arrayref"
                unless (ref($row) and reftype($row) eq 'ARRAY');
        }
        # We don't want to stick $args->{components} into the object as is.
        # Rather, we want to insert 'fields' and 'data_records' for
        # consistency with the 'file' interface.  But to do that we first need
        # to impose the same validations that we do for the 'file' interface.
        # We also need to populate 'path_col'.
        _prepare_fields($data, $args->{components}->{fields}, 1);
        my $these_data_records = $args->{components}->{data_records};
        delete $args->{components};
        _prepare_data_records($data, $these_data_records, $args);
    }
    else {
        croak "Cannot locate file '$args->{file}'"
            unless (-f $args->{file});
        $data->{file} = delete $args->{file};

        # We've now handled all the Parse::Taxonomy::MaterializedPath-specific options.
        # Any remaining options are assumed to be intended for Text::CSV_XS::new().

        $args->{binary} = 1;
        my $csv = Text::CSV_XS->new ( $args )
            or croak "Cannot use CSV: ".Text::CSV_XS->error_diag ();
        open my $IN, "<", $data->{file}
            or croak "Unable to open '$data->{file}' for reading";
        my $header_ref = $csv->getline($IN);

        _prepare_fields($data, $header_ref);
        my $data_records = $csv->getline_all($IN);
        close $IN or croak "Unable to close after reading";
        _prepare_data_records($data, $data_records, $args);
    }

    while (my ($k,$v) = each %{$args}) {
        $data->{$k} = $v;
    }
    my %row_analysis = ();
    for my $el (@{$data->{data_records}}) {
        my $rowkey = $el->[$data->{path_col_idx}];
        $row_analysis{$rowkey} = split(/\Q$data->{path_col_sep}\E/, $rowkey);
    }
    $data->{row_analysis} = \%row_analysis;
    return bless $data, $class;
}

sub _prepare_fields {
    my ($data, $fields_ref, $components) = @_;
    if (! $components) {
        _check_path_col_idx($data, $fields_ref, 0);
        path_check_fields($data, $fields_ref);
    }
    else {
        _check_path_col_idx($data, $fields_ref, 1);
        components_check_fields($data, $fields_ref);
    }

    my %fields_seen = map { $_ => 1 } @{$fields_ref};
    my @bad_fields = ();
    for my $reserved ( qw| id parent_id name lft rgh | ) {
        push @bad_fields, $reserved if $fields_seen{$reserved};
    }
    my $msg = "Bad column names: <@bad_fields>.  These are reserved for ";
    $msg .= "Parse::Taxonomy's internal use; please rename";
    croak $msg if @bad_fields;

    $data->{fields} = $fields_ref;
    $data->{path_col} = $data->{fields}->[$data->{path_col_idx}];
    return $data;
}

sub _check_path_col_idx {
    my ($data, $fields_ref, $components) = @_;
    my $error_msg = "Argument to 'path_col_idx' exceeds index of last field in ";
    $error_msg .= $components
        ? "'fields' array ref"
        : "header row in '$data->{file}'";

    croak $error_msg if $data->{path_col_idx} > $#{$fields_ref};
}

sub _prepare_data_records {
    # Confirm each row's path starts with path_col_sep:
    # Confirm no duplicate entries in column holding path:
    # Confirm all rows have same number of columns as header:
    my ($data, $data_records, $args) = @_;
    my $error_msg;
    my @bad_path_cols = ();
    my @bad_count_records = ();
    my %paths_seen = ();
    my $field_count = scalar(@{$data->{fields}});
    for my $rec (@{$data_records}) {
        unless ($rec->[$data->{path_col_idx}] =~ m/^\Q$data->{path_col_sep}\E/) {
            push @bad_path_cols, $rec->[$data->{path_col_idx}];
        }
        $paths_seen{$rec->[$data->{path_col_idx}]}++;
        my $this_row_count = scalar(@{$rec});
        if ($this_row_count != $field_count) {
            push @bad_count_records,
                [ $rec->[$data->{path_col_idx}], $this_row_count ];
        }
    }
    $error_msg = <<IMPROPER_PATH;
The value of the column designated as path must start with the path column separator.
Rows with the following paths fail to do so:
IMPROPER_PATH
    for my $path (@bad_path_cols) {
        $error_msg .= "  $path\n";
    }
    croak $error_msg if @bad_path_cols;

    my @dupe_paths = ();
    for my $path (sort keys %paths_seen) {
        push @dupe_paths, $path if $paths_seen{$path} > 1;
    }
    $error_msg = <<ERROR_MSG_DUPE;
No duplicate entries are permitted in column designated as path.
The following entries appear the number of times shown:
ERROR_MSG_DUPE
    for my $path (@dupe_paths) {
        $error_msg .= "  $path:" . sprintf("  %6s\n" => $paths_seen{$path});
    }
    croak $error_msg if @dupe_paths;

    $error_msg = <<ERROR_MSG_WRONG_COUNT;
Header row has $field_count records.  The following records had different counts:
ERROR_MSG_WRONG_COUNT
    for my $rec (@bad_count_records) {
        $error_msg .= "  $rec->[0]: $rec->[1]\n";
    }
    croak $error_msg if @bad_count_records;

    # Confirm each node appears in taxonomy:
    my $path_args = { map { $_ => $args->{$_} } keys %{$args} };
    $path_args->{sep} = $data->{path_col_sep};
    my $path_csv = Text::CSV_XS->new ( $path_args )
        or croak "Cannot use CSV: ".Text::CSV_XS->error_diag ();
    my %missing_parents = ();
    for my $path (sort keys %paths_seen) {
        my $status  = $path_csv->parse($path);
        my @columns = $path_csv->fields();
        if (@columns > 2) {
            my $parent =
                join($path_args->{sep} => @columns[0 .. ($#columns - 1)]);
            unless (exists $paths_seen{$parent}) {
                $missing_parents{$path} = $parent;
            }
        }
    }
    $error_msg = <<ERROR_MSG_ORPHAN;
Each node in the taxonomy must have a parent.
The following nodes lack the expected parent:
ERROR_MSG_ORPHAN
    for my $path (sort keys %missing_parents) {
        $error_msg .= "  $path:  $missing_parents{$path}\n";
    }
    croak $error_msg if scalar(keys %missing_parents);
    # BBB end of validations
    $data->{data_records} = $data_records;

    return $data;
}

=head2 C<fields()>

=over 4

=item * Purpose

Identify the names of the columns in the taxonomy.

=item * Arguments

    my $fields = $self->fields();

No arguments; the information is already inside the object.

=item * Return Value

Reference to an array holding a list of the columns as they appear in the
header row of the incoming taxonomy file.

=item * Comment

Read-only.

=back

=head2 C<path_col_idx()>

=over 4

=item * Purpose

Identify the index position (count starts at 0) of the column in the incoming
taxonomy file which serves as the path column.

=item * Arguments

    my $path_col_idx = $self->path_col_idx;

No arguments; the information is already inside the object.

=item * Return Value

Integer in the range from 0 to 1 less than the number of columns in the header
row.

=item * Comment

Read-only.

=back

=cut

sub path_col_idx {
    my $self = shift;
    return $self->{path_col_idx};
}

=head2 C<path_col()>

=over 4

=item * Purpose

Identify the name of the column in the incoming taxonomy which serves as the
path column.

=item * Arguments

    my $path_col = $self->path_col;

No arguments; the information is already inside the object.

=item * Return Value

String.

=item * Comment

Read-only.

=back

=cut

sub path_col {
    my $self = shift;
    return $self->{path_col};
}

=head2 C<path_col_sep()>

=over 4

=item * Purpose

Identify the string used to separate path components once the taxonomy has
been created.  This is just a "getter" and is logically distinct from the
option to C<new()> which is, in effect, a "setter."

=item * Arguments

    my $path_col_sep = $self->path_col_sep;

No arguments; the information is already inside the object.

=item * Return Value

String.

=item * Comment

Read-only.

=back

=cut

sub path_col_sep {
    my $self = shift;
    return $self->{path_col_sep};
}

=head2 C<data_records()>

=over 4

=item * Purpose

Once the taxonomy has been validated, get a list of its data rows as a Perl
data structure.

=item * Arguments

    $data_records = $self->data_records;

None.

=item * Return Value

Reference to array of array references.  The array will hold the data records
found in the incoming taxonomy file in their order in that file.

=item * Comment

Does not contain any information about the fields in the taxonomy, so you
should probably either (a) use in conjunction with C<fields()> method above;
or (b) use C<fields_and_data_records()>.

=back

=head2 C<fields_and_data_records()>

=over 4

=item * Purpose

Once the taxonomy has been validated, get a list of its header and data rows as a Perl
data structure.

=item * Arguments

    $data_records = $self->fields_and_data_records;

None.

=item * Return Value

Reference to array of array references.  The first element in the array will
hold the header row (same as output of C<fields()>).  The remaining elements
will hold the data records found in the incoming taxonomy file in their order
in that file.

=back

=cut

=head2 C<data_records_path_components()>

=over 4

=item * Purpose

Once the taxonomy has been validated, get a list of its data rows as a Perl
data structure.  In each element of this list, the path is now represented as
an array reference rather than a string.

=item * Arguments

    $data_records_path_components = $self->data_records_path_components;

None.

=item * Return Value

Reference to array of array references.  The array will hold the data records
found in the incoming taxonomy file in their order in that file.

=item * Comment

Does not contain any information about the fields in the taxonomy, so you may
wish to use this method either (a) use in conjunction with C<fields()> method
above; or (b) use C<fields_and_data_records_path_components()>.

=back

=cut

sub data_records_path_components {
    my $self = shift;
    my @all_rows = ();
    for my $row (@{$self->{data_records}}) {
        my $path_col = $row->[$self->{path_col_idx}];
        my @path_components = split(/\Q$self->{path_col_sep}\E/, $path_col);
        my @rewritten = ();
        for (my $i = 0; $i <= $#{$row}; $i++) {
            if ($i != $self->{path_col_idx}) {
                push @rewritten, $row->[$i];
            }
            else {
                push @rewritten, \@path_components;
            }
        }
        push @all_rows, \@rewritten;
    }
    return \@all_rows;
}

=head2 C<fields_and_data_records_path_components()>

=over 4

=item * Purpose

Once the taxonomy has been validated, get a list of its data rows as a Perl
data structure.  The first element in this list is an array reference holding
the header row.  In each data element of this list, the path is now represented as
an array reference rather than a string.

=item * Arguments

    $fields_and_data_records_path_components = $self->fields_and_data_records_path_components;

None.

=item * Return Value

Reference to array of array references.  The array will hold the data records
found in the incoming taxonomy file in their order in that file.

=back

=cut

sub fields_and_data_records_path_components {
    my $self = shift;
    my @all_rows = $self->fields;
    for my $row (@{$self->{data_records}}) {
        my $path_col = $row->[$self->{path_col_idx}];
        my @path_components = split(/\Q$self->{path_col_sep}\E/, $path_col);
        my @rewritten = ();
        for (my $i = 0; $i <= $#{$row}; $i++) {
            if ($i != $self->{path_col_idx}) {
                push @rewritten, $row->[$i];
            }
            else {
                push @rewritten, \@path_components;
            }
        }
        push @all_rows, \@rewritten;
    }
    return \@all_rows;
}

=head2 C<get_field_position()>

=over 4

=item * Purpose

Identify the index position of a given field within the header row.

=item * Arguments

    $index = $self->get_field_position('income');

Takes a single string holding the name of one of the fields (column names).

=item * Return Value

Integer representing the index position (counting from C<0>) of the field
provided as argument.  Throws exception if the argument is not actually a
field.

=back

=cut

=head2 C<descendant_counts()>

=over 4

=item * Purpose

Display the number of descendant (multi-generational) nodes each node in the
taxonomy has.

=item * Arguments

    $descendant_counts = $self->descendant_counts();

    $descendant_counts = $self->descendant_counts( { generations => 1 } );

None required; one optional hash reference.  Currently, the only element
honored in that hashref is C<generations>, whose value must be a non-negative
integer.  If, instead of getting the count of all descendants of a node, you
only want the count of its first generation, i.e., its immediate children, you
provide a value of C<1>.  Want the count of only the first and second
generations?  Provide a value of C<2> -- and so on.

=item * Return Value

Reference to hash in which each element is keyed on the value of the path
column in the incoming taxonomy file.

=back

=cut

sub descendant_counts {
    my ($self, $args) = @_;
    if (defined $args) {
        croak "Argument to 'descendant_counts()' must be hashref"
            unless (ref($args) and reftype($args) eq 'HASH');
        croak "Value for 'generations' element passed to descendant_counts() must be integer > 0"
            unless ($args->{generations} and $args->{generations} =~ m/^[0-9]+$/);
    }
    my %descendant_counts = ();
    my $hashified = $self->hashify();
    for my $p (keys %{$hashified}) {
        $descendant_counts{$p} = 0;
        for my $q (
            grep { $self->{row_analysis}->{$_} > $self->{row_analysis}->{$p} }
            keys %{$hashified}
        ) {
            if ($q =~ m/^\Q$p$self->{path_col_sep}\E/) {
                if (! $args->{generations}) {
                    $descendant_counts{$p}++;
                }
                else {
                    my @c = $p =~ m/\Q$self->{path_col_sep}\E/g;
                    my @d = $q =~ m/\Q$self->{path_col_sep}\E/g;
                    $descendant_counts{$p}++
                        if (scalar(@d) - scalar(@c) <= $args->{generations});
                }
            }
        }
    }
    $self->{descendant_counts} = \%descendant_counts;
    return $self->{descendant_counts};
}

=head2 C<get_descendant_count()>

=over 4

=item * Purpose

Get the total number of descendant nodes for one specific node in a validated
taxonomy.

=item * Arguments

    $descendant_count = $self->get_descendant_count('|Path|To|Node');

    $descendant_counts = $self->get_descendant_count('|Path|To|Node', { generations => 1 } );

One required:  string containing node's path as spelled in the taxonomy.

One optional hash reference.  Currently, the only element honored in that
hashref is C<generations>, whose value must be a non-negative integer.  If,
instead of getting the count of all descendants of a node, you only want the
count of its first generation, i.e., its immediate children, you provide a
value of C<1>.  Want the count of only first and second generations?  Provide
a value of C<2> -- and so on.

=item * Return Value

Unsigned integer >= 0.  Any node whose child count is C<0> is by definition a
leaf node.

=item * Comment

Will throw an exception if the node does not exist or is misspelled.

If C<get_descendant_count()> is called with no second (hashref) argument
following an invocation of C<descendant_counts()>, it will return a value from
an internal cache created during that earlier method call.  Otherwise, it will
re-create the cache from scratch.  (This, of course, assumes that you have not
manipulated the object's internal data subsequent to its creation.)

=back

=cut

sub get_descendant_count {
    my ($self, $node, $args) = @_;
    if (defined $args) {
        croak "Second argument to 'get_descendant_count()' must be hashref"
            unless (ref($args) and reftype($args) eq 'HASH');
        croak "Value for 'generations' element passed to second argument to get_descendant_count() must be integer > 0"
            unless ($args->{generations} and $args->{generations} =~ m/^[0-9]+$/);
    }
    if (exists $self->{descendant_counts}) {
        my $descendant_counts = $self->{descendant_counts};
        croak "Node '$node' not found" unless exists $descendant_counts->{$node};
        return $descendant_counts->{$node};
    }
    else {
        my %descendant_counts = ();
        my $hashified = $self->hashify();
        croak "Node '$node' not found" unless exists $hashified->{$node};
        for my $p ($node) {
            $descendant_counts{$p} = 0;
            for my $q (
                grep { $self->{row_analysis}->{$_} > $self->{row_analysis}->{$p} }
                keys %{$hashified}
            ) {
                if ($q =~ m/^\Q$p$self->{path_col_sep}\E/) {
                    if (! $args->{generations}) {
                        $descendant_counts{$p}++;
                    }
                    else {
                        my @c = $p =~ m/\Q$self->{path_col_sep}\E/g;
                        my @d = $q =~ m/\Q$self->{path_col_sep}\E/g;
                        $descendant_counts{$p}++
                            if (scalar(@d) - scalar(@c) <= $args->{generations});
                    }
                }
            }
        }
        return $descendant_counts{$node};
    }
}

=head2 C<hashify()>

=over 4

=item * Purpose

Turn a validated taxonomy into a Perl hash keyed on the column designated as
the path column.

=item * Arguments

    $hashref = $self->hashify();

Takes an optional hashref holding a list of any of the following elements:

=over 4

=item * C<remove_leading_path_col_sep>

Boolean, defaulting to C<0>.  By default, C<hashify()> will spell the
key of the hash exactly as the value of the path column is spelled in the
taxonomy -- which in turn is the way it was spelled in the incoming file.
That is, a path in the taxonomy spelled C<|Alpha|Beta|Gamma> will be spelled
as a key in exactly the same way.

However, since in many cases (including the example above) the root node of
the taxonomy will be empty, the user may wish to remove the first instance of
C<path_col_sep>.  The user would do so by setting
C<remove_leading_path_col_sep> to a true value.

    $hashref = $self->hashify( {
        remove_leading_path_col_sep => 1,
    } );

In that case they key would now be spelled:  C<Alpha|Beta|Gamma>.

Note further that if the C<root_str> switch is set to a true value, any
setting to C<remove_leading_path_col_sep> will be ignored.

=item * C<key_delim>

A string which will be used in composing the key of the hashref returned by
this method.  The user may select this key if she does not want to use the
value found in the incoming CSV file (which by default will be the pipe
character (C<|>) and which may be overridden with the C<path_col_sep> argument
to C<new()>.

    $hashref = $self->hashify( {
        key_delim   => q{ - },
    } );

In the above variant, a path that in the incoming taxonomy file was
represented by C<|Alpha|Beta|Gamma> will in C<$hashref> be represented by
C< - Alpha - Beta - Gamma>.

=item * C<root_str>

A string which will be used in composing the key of the hashref returned by
this method.  The user will set this switch if she wishes to have the root
note explicitly represented.  Using this switch will automatically cause
C<remove_leading_path_col_sep> to be ignored.

Suppose the user wished to have C<All Suppliers> be the text for the root
node.  Suppose further that the user wanted to use the string C< - > as the
delimiter within the key.

    $hashref = $self->hashify( {
        root_str    => q{All Suppliers},
        key_delim   => q{ - },
    } );

Then incoming path C<|Alpha|Beta|Gamma> would be keyed as:

    All Suppliers - Alpha - Beta - Gamma

=back

=item * Return Value

Hash reference.  The number of elements in this hash should be equal to the
number of non-header records in the taxonomy.

=back

=cut

sub hashify {
    my ($self, $args) = @_;
    if (defined $args) {
        croak "Argument to 'hashify()' must be hashref"
            unless (ref($args) and reftype($args) eq 'HASH');
    }
    my %hashified = ();
    my $fields = $self->{fields};
    my %idx2col = map { $_ => $fields->[$_] } (0 .. $#{$fields});
    for my $rec (@{$self->{data_records}}) {
        my $rowkey;
        if ($args->{root_str}) {
            $rowkey = $args->{root_str} . $rec->[$self->{path_col_idx}];
        }
        else {
            if ($args->{remove_leading_path_col_sep}) {
                ($rowkey = $rec->[$self->{path_col_idx}]) =~ s/^\Q$self->{path_col_sep}\E(.*)/$1/;
            }
            else {
                $rowkey = $rec->[$self->{path_col_idx}];
            }
        }
        if ($args->{key_delim}) {
            $rowkey =~ s/\Q$self->{path_col_sep}\E/$args->{key_delim}/g;
        }
        my $rowdata = { map { $idx2col{$_} => $rec->[$_] } (0 .. $#{$fields}) };
        $hashified{$rowkey} = $rowdata;
    }
    return \%hashified;
}

=head2 C<adjacentify()>

=over 4

=item * Purpose

Transform a taxonomy-by-materialized-path into a taxonomy-by-adjacent-list.

=item * Arguments

    $adjacentified = $self->adjacentify();

    $adjacentified = $self->adjacentify( { serial => 500 } );
    $adjacentified = $self->adjacentify( { floor  => 500 } );  # same as serial

Optional single hash reference.

For that hashref, C<adjacentify()> supports the key C<serial>, which defaults
to C<0>.  C<serial> must be a non-negative integer and sets the "floor" above
which new unique IDs will be assigned to the C<id> column.  Hence, if
C<serial> is set to C<500>, the value assigned to the C<id> column of the
first record to be processed will be C<501>.

Starting with version .19, C<floor> will serve as an alternative way of
providing the same information to C<adjacentify()>.  If, however, by mistake
you provide B<both> C<serial> and C<floor> elements in the hash, C<serial>
will take precedence.

=item * Return Value

Reference to an array of hash references.  Each element represents one node in
the taxonomy.  Each element will have key-value pairs for C<id>, C<parent_id>
and C<name> which will hold the adjacentification of the materialized path in the
original taxonomy-by-materialized-path.  Each element will, as well, have KVPs for the
non-materialized-path fields in the records in the original taxonomy-by-materialized-path.

=item * Comment

See documentation for C<write_adjacentified_to_csv()> for example.

Note that the order in which C<adjacentify()> will assign C<id> and
C<parent_id> values to records in the taxonomy-by-adjacent-list will almost
certainly B<not> match the order in which elements appear in a CSV file or in
the data structure returned by a method such as C<data_records()>.

=back

=cut

sub adjacentify {
    my ($self, $args) = @_;
    my $serial = 0;
    if (defined $args) {
        croak "Argument to 'adjacentify()' must be hashref"
            unless (ref($args) and reftype($args) eq 'HASH');
        for my $w ('serial', 'floor') {
            if (exists $args->{$w}) {
                croak "Element '$w' in argument to 'adjacentify()' must be integer"
                    unless ($args->{$w} =~ m/^\d+$/);
            }
        }
        $serial = $args->{serial} || $args->{floor} || 0;
    }


    my $fields = $self->fields();
    my $drpc = $self->data_records_path_components();

    my $path_col_idx = $self->path_col_idx();
    my %non_path_col2idx = map { $fields->[$_] => $_  }
        grep { $_ != $path_col_idx }
        (0..$#{$fields});

    my @components_by_row =
        map { my $f = $_->[$path_col_idx]; my $c = $#{$f}; [ @{$f}[1..$c] ] } @{$drpc};
    my $max_components = max( map { scalar(@{$_}) } @components_by_row);
    my @adjacentified = ();
    my %paths_to_id;
    for my $depth (1..$max_components) {
        for (my $r = 0; $r <= $#components_by_row; $r++) {
            if (scalar(@{$components_by_row[$r]}) == $depth) {
                my %rowdata = map { $_ => $drpc->[$r]->[$non_path_col2idx{$_}] }
                    keys %non_path_col2idx;
                my @path_components = @{$drpc->[$r]->[$path_col_idx]};
                my $name = $path_components[-1];
                my $parent_of_name = join('|' =>
                    @path_components[1 .. ($#path_components -1)]);

                my $candidate_for_path = (length($parent_of_name))
                    ? join('|' => $parent_of_name, $name)
                    : $name;

                my %rowhash = (
                    id => ++$serial,
                    parent_id => $paths_to_id{$parent_of_name}{id},
                    name => $name,
                    %rowdata,
                );
                $paths_to_id{$candidate_for_path}{id} = $rowhash{id};
                $paths_to_id{$candidate_for_path}{parent_path} = $parent_of_name
                    if (length($parent_of_name));
                push @adjacentified, \%rowhash;
            }
        }
    }
    return \@adjacentified;
}

=head2 C<write_adjacentified_to_csv()>

=over 4

=item * Purpose

Create a CSV-formatted file holding the data returned by C<adjacentify()>.

=item * Arguments

    $csv_file = $self->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,                   # output of adjacentify()
       csvfile => './t/data/taxonomy_out3.csv',
    } );

Single hash reference.  That hash is keyed on:

=over 4

=item * C<adjacentified>

B<Required:>  Its value must be the arrayref of hash references returned by
the C<adjacentify()> method.

=item * C<csvfile>

Optional.  Path to location where a CSV-formatted text file holding the
taxonomy-by-adjacent-list will be written.  Defaults to a file called
F<taxonomy_out.csv> in the current working directory.

=item * Text::CSV_XS options

You can also pass through any key-value pairs normally accepted by
F<Text::CSV_XS>.

=back

=item * Return Value

Returns path to CSV-formatted text file just created.

=item * Example

Suppose we have a CSV-formatted file holding the following taxonomy-by-materialized-path:

    "path","is_actionable"
    "|Alpha","0"
    "|Beta","0"
    "|Alpha|Epsilon","0"
    "|Alpha|Epsilon|Kappa","1"
    "|Alpha|Zeta","0"
    "|Alpha|Zeta|Lambda","1"
    "|Alpha|Zeta|Mu","0"
    "|Beta|Eta","1"
    "|Beta|Theta","1"

After running this file through C<new()>, C<adjacentify()> and
C<write_adjacentified_to_csv()> we will have a new CSV-formatted file holding
this taxonomy-by-adjacent-list:

    id,parent_id,name,is_actionable
    1,,Alpha,0
    2,,Beta,0
    3,1,Epsilon,0
    4,1,Zeta,0
    5,2,Eta,1
    6,2,Theta,1
    7,3,Kappa,1
    8,4,Lambda,1
    9,4,Mu,0

Note that the C<path> column has been replaced by the C<id>, C<parent_id> and
C<name> columns.

=back

=cut

sub write_adjacentified_to_csv {
    my ($self, $args) = @_;
    if (defined $args) {
        croak "Argument to 'adjacentify()' must be hashref"
            unless (ref($args) and reftype($args) eq 'HASH');
        croak "Argument to 'adjacentify()' must have 'adjacentified' element"
            unless exists $args->{adjacentified};
        croak "Argument 'adjacentified' must be array reference"
            unless (ref($args->{adjacentified}) and
                reftype($args->{adjacentified}) eq 'ARRAY');
    }
    else {
        croak "write_adjacentified_to_csv() must be supplied with hashref"
    }
    my $adjacentified = $args->{adjacentified};
    delete $args->{adjacentified};

    my $columns_in = $self->fields;
    my @non_path_columns_in =
        map { $columns_in->[$_]  }
        grep { $_ != $self->{path_col_idx} }
        (0..$#{$columns_in});
    my @columns_out = (qw| id parent_id name |);
    push @columns_out, @non_path_columns_in;

    my $cwd = cwd();
    my $csvfile = defined($args->{csvfile})
        ? $args->{csvfile}
        : "$cwd/taxonomy_out.csv";
    delete $args->{csvfile};

    # By this point, we should have processed all args other than those
    # intended for Text::CSV_XS and assigned their contents to variables as
    # needed.

    my $csv_args = { binary => 1 };
    while (my ($k,$v) = each %{$args}) {
        $csv_args->{$k} = $v;
    }
    my $csv = Text::CSV_XS->new($csv_args);
    open my $OUT, ">:encoding(utf8)", $csvfile
        or croak "Unable to open $csvfile for writing";
    $csv->eol(defined($csv_args->{eol}) ? $csv_args->{eol} : "\n");
    $csv->print($OUT, [@columns_out]);
    for my $rec (@{$adjacentified}) {
        $csv->print(
            $OUT,
            [ map { $rec->{$columns_out[$_]} } (0..$#columns_out) ]
        );
    }
    close $OUT or croak "Unable to close $csvfile after writing";

    return $csvfile;
}

1;

# vim: formatoptions=crqot
