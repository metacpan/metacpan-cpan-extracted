package Perl::Examples::POD::Link;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'Perl-Examples'; # DIST
our $VERSION = '0.096'; # VERSION

1;
# ABSTRACT: Show the various examples of links

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::POD::Link - Show the various examples of links

=head1 VERSION

This document describes version 0.096 of Perl::Examples::POD::Link (from Perl distribution Perl-Examples), released on 2023-02-24.

=head1 SYNOPSIS

 target link                   text     syntax                                                       note
 -----------                   ----     ------                                                       ----
 Perl module's POD             no       L<Foo::Bar>
 Perl module's POD             yes      L<that module|Foo::Bar>
 Perl module's POD + section   no       L<Foo::Bar/"SEE ALSO">
 Perl module's POD + section   yes      L<that module's See Also section|Foo::Bar/"SEE ALSO">
 section in the same POD       no       L</"SEE ALSO">
 section in the same POD       yes      L<See Also section|/"SEE ALSO">
 Perl script                   no       L<httpthis>
 Perl script                   yes      L<that script|httpthis>
 manpage                       no       L<ls(1)>                                                     MetaCPAN renders this
 URL                           no       L<http://www.example.com/page>
 URL                           yes      L<that page|http://www.example.com/pages>

=head1 DESCRIPTION

=head2 Links to POD

=head3 Link to module

 L<Perl::Examples>

Rendered result: L<Perl::Examples>

=head3 Link to module + section

 L<Perl::Examples/"SEE ALSO">

Rendered result: L<Perl::Examples/"SEE ALSO">

=head3 Link this page + section

 L</"URL links">

Rendered result: L</"URL links">

=head3 Link to module with text

 L<The Perl-Examples main module|Perl::Examples>

Rendered result: L<The Perl-Examples main module|Perl::Examples>

=head3 Link to module with text + section

 L<The description of Perl-Examples main module|Perl::Examples/"DESCRIPTION">

Rendered result: L<The description of Perl-Examples main module|Perl::Examples/"DESCRIPTION">

=head3 Link this page with text + section

 L<A collection of URL links|/"URL links">

Rendered result: L<A collection of URL links|/"URL links">

=head3 Link to script

 L<perl-example-die>

Rendered result: L<perl-example-die>

=head2 Links to manpage

=head2 URL links

=head3 URL without text

 L<http://www.example.com/page.html>

Rendered result: L<http://www.example.com/page.html>

=head3 URL with text

 L<An example page|http://www.example.com/page.html>

Rendered result: L<An example page|http://www.example.com/page.html>

=head3 http scheme with port

 L<http://www.example.com:8001/>

Rendered result: L<http://www.example.com:8001/>

=head3 https scheme

 L<https://www.example.com/>

Rendered result: L<https://www.example.com/>

=head3 ftp scheme

 L<ftp://ftp.example.com/>

Rendered result: L<ftp://ftp.example.com/>

=head3 mailto scheme

 L<mailto:example@example.com>

Rendered result: L<mailto:example@example.com>

=head3 Some custom scheme

 L<foo://bar>

Rendered result: L<foo://bar>

=head2 POD link in head2

L<Perl::Examples>

Rendered result: L<Perl::Examples>

=head2 URL link in head2

L<http://www.example.com/head2.html>

Rendered result: L<http://www.example.com/head2.html>

=head2 Links in bullet points

=over

=item * L<Perl::Examples>

=item * L<http://www.example.com/bullet.html>

=back

=head2 Not links

 L<link in verbatim is not link|Perl::Example>

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
