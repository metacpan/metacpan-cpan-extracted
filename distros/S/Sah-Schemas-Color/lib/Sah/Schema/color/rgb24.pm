package Sah::Schema::color::rgb24;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-Color'; # DIST
our $VERSION = '0.006'; # VERSION

our $schema = [str => {
    summary => 'RGB 24-digit color, a hexdigit e.g. ffcc00', # XXX also allow other forms
    match => qr/\A[0-9A-Fa-f]{6}\z/,
    'x.completion' => ['colorname'],
    'x.perl.coerce_rules' => ['From_str::rgb24_from_colorname_X_or_code'],
    examples => [
        {data=>'000000' , valid=>1, res=>'000000'},
        {data=>'black'  , valid=>1, res=>'000000'},
        {data=>'FFffcc' , valid=>1, res=>'ffffcc'},
        {data=>'#FFffcc', valid=>1, res=>'ffffcc'},
        {data=>'foo'    , valid=>0},
    ],
}, {}];

1;
# ABSTRACT: RGB 24-digit color, a hexdigit e.g. ffcc00

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::color::rgb24 - RGB 24-digit color, a hexdigit e.g. ffcc00

=head1 VERSION

This document describes version 0.006 of Sah::Schema::color::rgb24 (from Perl distribution Sah-Schemas-Color), released on 2020-03-02.

=head1 DESCRIPTION

Accepts color codes (with optional pound sign prefix, which will be removed), e.g.:

 ffff00
 #80FF00

Color names (from L<Graphics::ColorNames::X>) are also accepted and will be
coerced to its RGB code, e.g.:

 black

(will be coerced to C<000000>)

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
