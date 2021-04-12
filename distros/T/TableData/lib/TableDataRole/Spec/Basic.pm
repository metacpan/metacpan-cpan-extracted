package TableDataRole::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'TableData'; # DIST
our $VERSION = '0.1.5'; # VERSION

use Role::Tiny;

# constructor
requires 'new';

# iterator interface
requires 'get_row_arrayref';
requires 'get_row_hashref';
#provides 'get_row_count';
requires 'get_row_iterator_index';
requires 'reset_row_iterator';

# convenience
#provides 'get_all_rows_arrayref';
#provides 'get_all_rows_hashref';
#provides 'each_row_arrayref';
#provides 'each_row_hashref';

# column information
requires 'get_column_count';
requires 'get_column_names';

###

sub get_row_count {
    my $table = shift;

    $table->reset_row_iterator;
    while (defined(my $row = $table->get_row_arrayref)) { }
    $table->get_row_iterator_index;
}

sub get_all_rows_arrayref {
    my $table = shift;

    my $rows = [];
    $table->reset_row_iterator;
    while (defined(my $row = $table->get_row_arrayref)) {
        push @$rows, $row;
    }
    $rows;
}

sub get_all_rows_hashref {
    my $table = shift;

    my $rows = [];
    $table->reset_row_iterator;
    while (defined(my $row = $table->get_row_hashref)) {
        push @$rows, $row;
    }
    $rows;
}

sub each_row_arrayref {
    my ($table, $coderef) = @_;

    $table->reset_row_iterator;
    my $index = 0;
    while (defined(my $row = $table->get_row_arrayref)) {
        my $res = $coderef->($row, $table, $index);
        return 0 unless $res;
        $index++;
    }
    return 1;
}

sub each_row_hashref {
    my ($table, $coderef) = @_;

    $table->reset_row_iterator;
    my $index = 0;
    while (defined(my $row = $table->get_row_hashref)) {
        my $res = $coderef->($row, $table, $index);
        return 0 unless $res;
        $index++;
    }
    return 1;
}

1;
# ABSTRACT: Basic interface for all TableData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

TableDataRole::Spec::Basic - Basic interface for all TableData::* modules

=head1 VERSION

This document describes version 0.1.5 of TableDataRole::Spec::Basic (from Perl distribution TableData), released on 2021-04-11.

=head1 DESCRIPTION

The basic interface is an iterator. You can call L</reset_row_iterator> to jump
to the first row, then call either L</get_row_arrayref> or L</get_row_hashref>
repeatedly to get rows one at a time until all the rows are retrieved. If you
need to go back to the first row, you can call L</reset_row_iterator> again.

Some methods are provided to get information about the columns:
L</get_column_count>, L</get_column_names>.

Some other information methods: L</get_row_count>, L</get_row_iterator_index>.

Other convenient methods: L</get_all_rows_arrayref>, L</get_all_rows_hashref>,
L</each_row_arrayref>, L</each_row_hashref>.

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $table = TableData::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 get_column_count

Usage:

 my $n = $table->get_column_count;

Must return the number of columns of the table.

All tables must have finite number of columns.

=head2 get_column_names

Usage:

 my @colnames = $table->get_column_names;
 my $colnames = $table->get_column_names;

Must return a list (or arrayref) containing the names of columns, ordered. For
ease of use, when in list context the method must return a list, and in scalar
context must return an arrayref.

=head2 get_row_arrayref

Usage:

 my $arrayref = $table->get_row_arrayref;

Must return the next row of the table as arrayref: if called the first time,
must return the first row; then the second, and so on. Must return undef if
there are no more rows in the table.

Can be interspersed with L</get_row_hashref>. A call to either
C<get_row_arrayref> or C<get_row_hashref> move the internal row iterator.

Beware of methods that may reset the row iterator. For safety it is recommended
that you call L</reset_row_iterator> first, then get all the rows you want at
one go.

See also L</reset_row_iterator>.

=head2 get_row_hashref

Usage:

 my $hashref = $table->get_row_hashref;

Just like L</get_row_arrayref>, but must return the row as hashref instead of
arrayref.

See also L</reset_row_iterator>.

=head2 get_row_iterator_index

Usage:

 my $index = $table->get_row_iterator_index;

Must return the row iterator index (integer), where 0 points to the first data
row, 1 to the second, and so on.

Since the first call to L</get_row_arrayref> or L</get_row_hashref> before any
call to L</reset_row_iterator> must return the first data row, this means at the
beginning the row iterator index must be 0.

=head2 reset_row_iterator

Usage:

 $table->reset_row_iterator;

Can be used to reset the iterator so the next call to L</get_row_arrayref> or
L</get_row_hashref> will return the first data row.

=head1 PROVIDED METHODS

=head2 get_row_count

Usage:

 my $count = $table->get_row_count;

Return the number of data rows in the table. May reset the row iterator (see
L</get_row_arrayref> and L</reset_iterator>).

A table with infinite data rows can return -1.

The default implementation will call L</reset_row_iterator>, call
L</get_row_arrayref> repeatedly until undef is returned, then return
L</get_row_iterator_index>. If your source data is already in an array or some
other form where the length is easily known, you can replace the implementation
with a more efficient one.

=head2 get_all_rows_arrayref

Usage:

 my $rows = $table->get_all_rows_arrayref;

Return all rows as an array of arrayrefs. May reset the row iterator. Basically
shortcut for:

 my $rows = [];
 $table->reset_row_iterator;
 while (my $row = $table->get_row_arrayref) {
     push @$rows, $row;
 }

You can provide a more efficient implementation if your source data allows it.

A table with infinite data rows can throw an exception if this method is called.

=head2 get_all_rows_hashref

Usage:

 my $rows = $table->get_all_rows_hashref;

Return all rows as an I<array> of hashrefs. May reset the row iterator.
Basically shortcut for:

 my $rows = [];
 $table->reset_row_iterator;
 while (my $row = $table->get_row_hashref) {
     push @$rows, $row;
 }

You can provide a more efficient implementation if your source data allows it.

A table with infinite data rows can throw an exception if this method is called.

=head2 each_row_arrayref

Usage:

 $table->each_row_arrayref($coderef);

Call C<$coderef> for each row. If C<$coderef> returns false, will immediately
return false and skip the rest of the rows. Otherwise, will return true.
Basically:

 $table->reset_row_iterator;
 my $index = 0;
 while (my $row = $table->get_row_arrayref) {
     my $res = $coderef->($row, $table, $index);
     return 0 unless $res;
     $index++;
 }
 return 1;

See also L</each_row_hashref>.

=head2 each_row_hashref

Usage:

 $table->each_row_hashref($coderef);

Call C<$coderef> for each row. If C<$coderef> returns false, will immediately
return false and skip the rest of the rows. Otherwise, will return true.
Basically:

 $table->reset_row_iterator;
 my $index = 0;
 while (my $row = $table->get_row_hashref) {
     my $res = $coderef->($row, $table, $index);
     return 0 unless $res;
     $index++;
 }
 return 1;

See also L</each_row_arrayref>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<TableDataRole::Spec::Seekable>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
