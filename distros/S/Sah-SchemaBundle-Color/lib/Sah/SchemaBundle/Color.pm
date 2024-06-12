package Sah::SchemaBundle::Color;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-08'; # DATE
our $DIST = 'Sah-SchemaBundle-Color'; # DIST
our $VERSION = '0.015'; # VERSION

1;
# ABSTRACT: Sah schemas related to color codes/names

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::Color - Sah schemas related to color codes/names

=head1 VERSION

This document describes version 0.015 of Sah::SchemaBundle::Color (from Perl distribution Sah-SchemaBundle-Color), released on 2024-06-08.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<color::ansi16|Sah::Schema::color::ansi16>

ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc.

=item * L<color::ansi256|Sah::Schema::color::ansi256>

ANSI-256 color, an integer number from 0-255.

=item * L<color::cmyk|Sah::Schema::color::cmyk>

CMYK color in the format of C,M,Y,K where each component is an integer between 0-100, e.g. 0,0,0,50 (gray).

=item * L<color::rgb24|Sah::Schema::color::rgb24>

RGB 24-digit color, a hexdigit e.g. ffcc00.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Color>.

=head1 SEE ALSO

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
