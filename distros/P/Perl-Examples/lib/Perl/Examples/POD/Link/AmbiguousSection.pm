package Perl::Examples::POD::Link::AmbiguousSection;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'Perl-Examples'; # DIST
our $VERSION = '0.096'; # VERSION

1;
# ABSTRACT: Link to section where the section name is not unique

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::POD::Link::AmbiguousSection - Link to section where the section name is not unique

=head1 VERSION

This document describes version 0.096 of Perl::Examples::POD::Link::AmbiguousSection (from Perl distribution Perl-Examples), released on 2023-02-24.

=head1 DESCRIPTION

This document features POD links with section where the section name is not
unique.

L<This link|/"Subchapter 1"> links to section named "Subchapter 1" (a level-2
heading). Note that the L</CHAPTER 1> level-1 heading as well as L</CHAPTER 2>
level-1 heading both have this subheading. There is currently no way we can link
to a specific level-1 heading's subheading.

These don't work (yet).

=over

=item * L</"CHAPTER 1"/"Subchapter 1">

=item * L</"CHAPTER 1/Subchapter 1">

=item * L</CHAPTER 1/Subchapter 1>

=back

L<This link|/"Item 1"> links to section named "Item 1" (an item). Note that both
chapters also have this item.

L<This link|/"Another item"> links to section named "Another item" (an item).
Note that Subchapter 2 in Chapter 2 has a list with two items named "Another
item".

=head1 CHAPTER 1

=head2 Subchapter 1

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

=over

=item * Item 1

=item * Item 2

=back

=head2 Subchapter 2

Some text.

=head1 CHAPTER 2

=head2 Subchapter 1

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

Some text.

=head2 Subchapter 2

Some text.

=over

=item * Item 1

=item * Item 2

=item * Another item

=item * Another item

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples>.

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

This software is copyright (c) 2023, 2020, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
