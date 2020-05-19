package Sah::Schema::color::ansi256;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-Color'; # DIST
our $VERSION = '0.006'; # VERSION

our $schema = [int => {
    summary => 'ANSI-256 color, an integer number from 0-255',
    min => 0,
    max => 255,
    examples => [
        {data=>  0, valid=>1},
        {data=>255, valid=>1},
        {data=>256, valid=>0},
        {data=>'black'  , valid=>0}, # not supported yet
        {data=>'foo'    , valid=>0},
    ],
}, {}];

1;
# ABSTRACT: ANSI-256 color, an integer number from 0-255

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::color::ansi256 - ANSI-256 color, an integer number from 0-255

=head1 VERSION

This document describes version 0.006 of Sah::Schema::color::ansi256 (from Perl distribution Sah-Schemas-Color), released on 2020-03-02.

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

This software is copyright (c) 2020, 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
