package Role::TinyCommons::Collection::CompareItems;

use strict;
use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-07'; # DATE
our $DIST = 'RoleBundle-TinyCommons-Collection'; # DIST
our $VERSION = '0.009'; # VERSION

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

This document describes version 0.009 of Role::TinyCommons::Collection::CompareItems (from Perl distribution RoleBundle-TinyCommons-Collection), released on 2021-10-07.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 REQUIRED METHODS

=head2 cmp_items

Usage:

 my $res = $obj->cmp_item($item1, $item2); # => -1|0|1

Compare two items. Must return either -1, 0, or 1. This is the standard Perl's
C<cmp> and C<< <=> >> semantic.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/RoleBundle-TinyCommons-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-RoleBundle-TinyCommons-Collection>.

=head1 SEE ALSO

Perl's C<cmp> and C<< <=> >> operator.

L<Data::Cmp>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=RoleBundle-TinyCommons-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
