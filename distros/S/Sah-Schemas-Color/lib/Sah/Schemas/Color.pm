package Sah::Schemas::Color;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-19'; # DATE
our $DIST = 'Sah-Schemas-Color'; # DIST
our $VERSION = '0.014'; # VERSION

1;
# ABSTRACT: Sah schemas related to color codes/names

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::Color - Sah schemas related to color codes/names

=head1 VERSION

This document describes version 0.014 of Sah::Schemas::Color (from Perl distribution Sah-Schemas-Color), released on 2021-07-19.

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-dell-xps13)

perlancar (on netbook-dell-xps13) <perlancar@gmail.com>

=head1 SAH SCHEMAS

=over

=item * L<color::ansi16|Sah::Schema::color::ansi16>

ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc.

=item * L<color::ansi256|Sah::Schema::color::ansi256>

ANSI-256 color, an integer number from 0-255.

=item * L<color::rgb24|Sah::Schema::color::rgb24>

RGB 24-digit color, a hexdigit e.g. ffcc00.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
