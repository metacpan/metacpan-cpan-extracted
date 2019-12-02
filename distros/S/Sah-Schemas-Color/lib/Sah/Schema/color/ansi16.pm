package Sah::Schema::color::ansi16;

our $DATE = '2019-11-29'; # DATE
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc',
    match => qr/\A(?:0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|
                    (?:(bold|bright) \s )?(black|red|green|yellow|blue|magenta|cyan|white))\z/ix,
}, {}];

1;
# ABSTRACT: ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::color::ansi16 - ANSI-16 color, either a number from 0-15 or color names like "black", "bold red", etc

=head1 VERSION

This document describes version 0.005 of Sah::Schema::color::ansi16 (from Perl distribution Sah-Schemas-Color), released on 2019-11-29.

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

This software is copyright (c) 2019, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
