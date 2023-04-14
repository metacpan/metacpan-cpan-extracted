package Sah::Schemas::EAN;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-27'; # DATE
our $DIST = 'Sah-Schemas-EAN'; # DIST
our $VERSION = '0.009'; # VERSION

1;
# ABSTRACT: Various Sah schemas related to EAN (International/European Article Number)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::EAN - Various Sah schemas related to EAN (International/European Article Number)

=head1 VERSION

This document describes version 0.009 of Sah::Schemas::EAN (from Perl distribution Sah-Schemas-EAN), released on 2023-01-27.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<ean13|Sah::Schema::ean13>

EAN-13 number (e.g. 5-901234-123457).

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

Length must be 13 digits.


=item * L<ean13_unvalidated|Sah::Schema::ean13_unvalidated>

EAN-13 number (e.g. 5-901234-123457), check digit not validated.

Nondigits [^0-9] will be removed during coercion.

Length must be 13 digits.

This schema can be useful if you want to check EAN-13's check digit yourself.


=item * L<ean13_without_check_digit|Sah::Schema::ean13_without_check_digit>

The first 12 digits of an EAN-13 number (eg. 5-901234-12345).

Nondigits [^0-9] will be removed during coercion.

Length must be 7 digits.

This schema can be useful if you want co calculate the check digit and want to
accept the first 12 digits as input.


=item * L<ean8|Sah::Schema::ean8>

EAN-8 number (e.g. 9638-5074).

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

Length must be 8 digits.


=item * L<ean8_unvalidated|Sah::Schema::ean8_unvalidated>

EAN-8 number (e.g. 9638-5074), check digit not validated.

Nondigits [^0-9] will be removed during coercion.

Length must be 8 digits.

This schema can be useful if you want to check EAN-8's check digit yourself.


=item * L<ean8_without_check_digit|Sah::Schema::ean8_without_check_digit>

The first 7 digits of an EAN-8 number (eg. 9638-507).

Nondigits [^0-9] will be removed during coercion.

Length must be 7 digits.

This schema can be useful if you want co calculate the check digit and want to
accept the first 7 digits as input.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-EAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-EAN>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<https://en.wikipedia.org/wiki/International_Article_Number>

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

This software is copyright (c) 2023, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-EAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
