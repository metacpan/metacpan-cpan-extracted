package Sah::Schemas::ColorScheme;

our $DATE = '2021-01-20'; # DATE
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Alias for Sah::Schemas::GraphicsColorNames

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::ColorScheme - Alias for Sah::Schemas::GraphicsColorNames

=head1 VERSION

This document describes version 0.002 of Sah::Schemas::ColorScheme (from Perl distribution Sah-Schemas-GraphicsColorNames), released on 2021-01-20.

=head1 DESCRIPTION

I use "color schemes" to refer to modules in the L<Graphics::ColorNames>::*
namespace, while "color themes" to refer to modules in the L<ColorTheme>::* (or
C<WHATEVER::ColorTheme::*>) namespace. The color theme modules allow defining
color items that have background color (in addition to foreground color), as
well as dynamic color (coderef).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-GraphicsColorNames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-GraphicsColorNames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-Schemas-GraphicsColorNames/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

L<Graphics::ColorNames>

L<Sah::Schemas::ColorTheme> and L<ColorTheme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
