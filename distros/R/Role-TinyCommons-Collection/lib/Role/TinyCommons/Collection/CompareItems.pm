package Role::TinyCommons::Collection::CompareItems;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-20'; # DATE
our $DIST = 'Role-TinyCommons-Collection'; # DIST
our $VERSION = '0.008'; # VERSION

use Role::Tiny;

### required methods

requires 'cmp_items';

1;
# ABSTRACT: The cmp_items() interface

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::TinyCommons::Collection::CompareItems - The cmp_items() interface

=head1 VERSION

This document describes version 0.008 of Role::TinyCommons::Collection::CompareItems (from Perl distribution Role-TinyCommons-Collection), released on 2021-05-20.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 REQUIRED METHODS

=head2 cmp_items

Usage:

 my $res = $obj->cmp_item($item1, $item2); # => -1|0|1

Compare two items. Must return either -1, 0, or 1. This is the standard Perl's
C<cmp> and C<< <=> >> semantic.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Role-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Role-TinyCommons-Collection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Role-TinyCommons-Collection/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Perl's C<cmp> and C<< <=> >> operator.

L<Data::Cmp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
