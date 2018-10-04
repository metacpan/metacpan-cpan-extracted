package Sah::Schema::color::ansi256;

our $DATE = '2018-09-26'; # DATE
our $VERSION = '0.002'; # VERSION

our $schema = [int => {
    summary => 'ANSI-256 color, an integer number from 0-255',
    min => 0,
    max => 255,
}, {}];

1;
# ABSTRACT: ANSI-256 color, an integer number from 0-255

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::color::ansi256 - ANSI-256 color, an integer number from 0-255

=head1 VERSION

This document describes version 0.002 of Sah::Schema::color::ansi256 (from Perl distribution Sah-Schemas-Color), released on 2018-09-26.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
