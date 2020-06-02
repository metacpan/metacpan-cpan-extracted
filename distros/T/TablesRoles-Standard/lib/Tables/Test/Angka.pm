package Tables::Test::Angka;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-01'; # DATE
our $DIST = 'TablesRoles-Standard'; # DIST
our $VERSION = '0.003'; # VERSION

use Role::Tiny::With;
with 'TablesRole::Source::CSVDATA';

1;
# ABSTRACT: Number from 1-5 with English and Indonesian text

=pod

=encoding UTF-8

=head1 NAME

Tables::Test::Angka - Number from 1-5 with English and Indonesian text

=head1 VERSION

This document describes version 0.003 of Tables::Test::Angka (from Perl distribution TablesRoles-Standard), released on 2020-06-01.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TablesRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TablesRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TablesRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
number,en_name,id_name
1,one,satu
2,two,dua
3,three,tiga
4,four,empat
5,five,lima
