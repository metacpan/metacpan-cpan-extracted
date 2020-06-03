package Sah::Schema::color::rgb24;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Color'; # DIST
our $VERSION = '0.012'; # VERSION

our $schema = [str => {
    summary => 'RGB 24-digit color, a hexdigit e.g. ffcc00', # XXX also allow other forms
    match => qr/\A[0-9A-Fa-f]{6}\z/,
    'x.completion' => ['colorname'],
    'x.perl.coerce_rules' => ['From_str::rgb24_from_colorname_X_or_code'],
    examples => [
        {value=>'000000' , valid=>1, validated_value=>'000000'},
        {value=>'black'  , valid=>1, validated_value=>'000000'},
        {value=>'FFffcc' , valid=>1, validated_value=>'ffffcc'},
        {value=>'#FFffcc', valid=>1, validated_value=>'ffffcc'},
        {value=>'foo'    , valid=>0},
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

This document describes version 0.012 of Sah::Schema::color::rgb24 (from Perl distribution Sah-Schemas-Color), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("color::rgb24*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used with L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['color::rgb24*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "000000"  # valid, becomes "000000"

 "black"  # valid, becomes "000000"

 "FFffcc"  # valid, becomes "ffffcc"

 "#FFffcc"  # valid, becomes "ffffcc"

 "foo"  # INVALID

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
