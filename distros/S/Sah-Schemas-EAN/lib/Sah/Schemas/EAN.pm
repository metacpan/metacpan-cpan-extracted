package Sah::Schemas::EAN;

our $DATE = '2018-08-23'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Various Sah schemas related to EAN (International/European Article Number)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::EAN - Various Sah schemas related to EAN (International/European Article Number)

=head1 VERSION

This document describes version 0.002 of Sah::Schemas::EAN (from Perl distribution Sah-Schemas-EAN), released on 2018-08-23.

=head1 SAH SCHEMAS

=over

=item * L<ean13|Sah::Schema::ean13>

EAN-13 number.

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.


=item * L<ean8|Sah::Schema::ean8>

EAN-8 number.

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-EAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-EAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-EAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

L<https://en.wikipedia.org/wiki/International_Article_Number>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
