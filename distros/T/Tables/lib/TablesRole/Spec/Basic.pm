package TablesRole::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-01'; # DATE
our $DIST = 'Tables'; # DIST
our $VERSION = '0.1.1'; # VERSION

use Role::Tiny;

requires 'new';

requires 'as_csv';
requires 'get_column_count';
requires 'get_column_names';
requires 'get_row_arrayref';
requires 'get_row_count';
requires 'get_row_hashref';
requires 'reset_iterator';

1;
# ABSTRACT: Required methods for all Tables::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

TablesRole::Spec::Basic - Required methods for all Tables::* modules

=head1 VERSION

This document describes version 0.1.1 of TablesRole::Spec::Basic (from Perl distribution Tables), released on 2020-06-01.

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $table = Tables::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 as_csv

Usage:

 my $csv = $table->as_csv;

Must return the whole table data as CSV (string). May reset the row iterator
(see L</get_row_arrayref> and L</reset_iterator>).

=head2 get_column_count

Usage:

 my $n = $table->get_column_count;

Must return the number of columns of the table.

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
that you call L</reset_iterator> first, then get all the rows you want at one
go.

See also L</reset_iterator>.

=head2 get_row_count

Usage:

 my $count = $table->get_row_count;

Must return the number of data rows in the table. May reset the row iterator
(see L</get_row_arrayref> and L</reset_iterator>).

=head2 get_row_hashref

Usage:

 my $hashref = $table->get_row_hashref;

Just like L</get_row_arrayref>, but must return the row as hashref instead of
arrayref.

See also L</reset_iterator>.

=head2 reset_iterator

Usage:

 $table->reset_iterator;

Can be used to reset the iterator so the next call to L</get_row_arrayref> or
L</get_row_hashref>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tables>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tables>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tables>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
