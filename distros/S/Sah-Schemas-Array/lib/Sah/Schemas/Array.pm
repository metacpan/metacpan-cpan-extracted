package Sah::Schemas::Array;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-03'; # DATE
our $DIST = 'Sah-Schemas-Array'; # DIST
our $VERSION = '0.003'; # VERSION

1;
# ABSTRACT: Sah schemas related to array type

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Array - Sah schemas related to array type

=head1 VERSION

This document describes version 0.003 of Sah::Schemas::Array (from Perl distribution Sah-Schemas-Array), released on 2023-02-03.

=head1 DESCRIPTION

The L<Sah>'s C<array> type supports some basic constraint clauses: C<min_len>,
C<max_len>, C<len>, C<len_between> (for checking number of elements), C<uniq>
(for checking that elements are unique), C<has> (for checking that a specified
value is found in array).

Until L<Data::Sah> allows easier creation of custom clauses, this distribution
contains schemas that allow you to perform additional checks.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<array::int::contiguous|Sah::Schema::array::int::contiguous>

An array of a single contiguous range of integers.




=item * L<array::int::monotonically_decreasing|Sah::Schema::array::int::monotonically_decreasing>

An array of integers with monotonically decreasing elements.

This is like the C<array::num::monotonically_decreasing> schema except elements
must be integers.


=item * L<array::int::monotonically_increasing|Sah::Schema::array::int::monotonically_increasing>

An array of integers with monotonically increasing elements.

This is like the C<array::num::monotonically_increasing> schema except elements
must be integers.


=item * L<array::int::reverse_sorted|Sah::Schema::array::int::reverse_sorted>

An array of reversely sorted integers.

This is like the C<array::num::reverse_sorted> schema except elements must be
integers.


=item * L<array::int::sorted|Sah::Schema::array::int::sorted>

An array of sorted integers.

This is like the C<array::num::sorted> schema except elements must be integers.


=item * L<array::num::monotonically_decreasing|Sah::Schema::array::num::monotonically_decreasing>

An array of numbers with monotonically decreasing elements.

Use this schema if you want to accept an array of numbers where the elements are
monotonically decreasing, i.e. C<< elem(i) E<lt> elem(i-1) for all i E<gt> 0 >>. It's similar
to the C<array::num::reverse_sorted> schema except that duplicate numbers are not
allowed (e.g. C<[4, 2, 2, 1]> is okay for C<array::num::reverse_sorted> but will fail
C<array::num::monotonically_decreasing>).


=item * L<array::num::monotonically_increasing|Sah::Schema::array::num::monotonically_increasing>

An array of numbers with monotonically increasing elements.

Use this schema if you want to accept an array of numbers where the elements are
monotonically increasing, i.e. C<< elem(i) E<gt> elem(i-1) for all i E<gt> 0 >>. It's similar
to the C<array::num::sorted> schema except that duplicate numbers are not allowed
(e.g. C<[1, 2, 2, 4]> is okay for C<array::num::sorted> but will fail
C<array::num::monotonically_increasing>).


=item * L<array::num::reverse_sorted|Sah::Schema::array::num::reverse_sorted>

An array of reversely sorted numbers.

Use this schema if you want to accept an array of reversely sorted numbers, i.e.
C<< elem(i) E<lt>= elem(i-1) for all i E<gt> 0 >>.

See also: C<array::num::monotonically_decreasing> and
C<array::num::sorted> schemas.


=item * L<array::num::sorted|Sah::Schema::array::num::sorted>

An array of sorted numbers.

Use this schema if you want to accept an array of sorted numbers, i.e. C<< elem(i)
 E<gt>= elem(i-1) for all i E<gt> 0 >>.

See also: C<array::num::monotonically_increasing> and
C<array::num::reverse_sorted> schemas.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Array>.

=head1 SEE ALSO

L<Sah::PSchemas::Array>

L<Sah::Schemas::Hash>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
