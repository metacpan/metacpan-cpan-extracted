package Perl::Examples::POD::Escape;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'Perl-Examples'; # DIST
our $VERSION = '0.096'; # VERSION

1;
# ABSTRACT: Show the various examples of escaping

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::POD::Escape - Show the various examples of escaping

=head1 VERSION

This document describes version 0.096 of Perl::Examples::POD::Escape (from Perl distribution Perl-Examples), released on 2023-02-24.

=head1 DESCRIPTION

To make the whole paragraph as verbatim, thus avoiding any interior sequences
from being interpreted, you indent the paragraph with at least one whitespace,
example:

 This is a verbatim paragraph. Interior sequences like I<italic> and B<bold>
 will not be interpreted but shown as is.

They are akin to C<< <PRE> >> in HTML.

To escape a character, use the EE<lt>E<gt> interior sequence, which is similar
to C<&foo;> entities in HTML. For example: C<< EE<lt>gtE<gt> >> (will be
rendered as E<gt>), C<< EE<lt>ltE<gt> >> (will be rendered as E<lt>). See
L<perlpod> for the full list.

To make an inline text as verbatim, you use the C<< CE<lt>E<gt> >> interior
sequence, for example: C<< CE<lt>literalE<gt> >> (will be rendered as
C<literal>), C<< CE<lt>&gt;E<gt> >> (will be rendered as C<&gt;>). This is
similar to C<< <CODE> >> in HTML.

Interior sequence can be written with a single angle bracket pair (C<<
CE<lt>fooE<gt> >>, C<< CE<lt>fooE<gt> >>) or double angle bracket + whitespace
(C<< CE<lt>E<lt> foo E<gt>E<gt> >>, C<< BE<lt>E<lt> foo E<gt>E<gt> >>). The
latter is useful if you have literal E<lt> and E<gt> inside the sequence, e.g.
C<< CE<lt>E<lt> E<lt>TAGE<gt> E<gt>E<gt> >> (will be rendered as C<< <TAG> >>).

The interior sequence can contain one another, so another way to write verbatim:

 <foo>

aside from:

 C<< <foo> >>

is:

 C<E<lt>fooE<gt>>

Another example:

 I<E<lt>italicE<gt>>

(will be rendered as I<E<lt>italicE<gt>>).

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
