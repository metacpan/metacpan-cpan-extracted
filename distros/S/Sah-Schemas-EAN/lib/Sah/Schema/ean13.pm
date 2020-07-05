package Sah::Schema::ean13;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-EAN'; # DIST
our $VERSION = '0.007'; # VERSION

our $schema = [str => {
    summary => 'EAN-13 number',
    description => <<'_',

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

_
    match => '\A[0-9]{13}\z',
    'x.perl.coerce_rules' => ['From_str::to_ean13'],

    examples => [
        {value=>'5-901234-123457', valid=>1, validated_value=>'5901234123457'},
        {value=>'123-4567890-123', valid=>0, summary=>'Invalid checkdigit'},
        {value=>'1234567890', valid=>0, summary=>'Less than 13 digits'},
        {value=>'12345678901234', valid=>0, summary=>'More than 13 digits'},
    ],
}, {}];

1;
# ABSTRACT: EAN-13 number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::ean13 - EAN-13 number

=head1 VERSION

This document describes version 0.007 of Sah::Schema::ean13 (from Perl distribution Sah-Schemas-EAN), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("ean13*");
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
             schema => ['ean13*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "5-901234-123457"  # valid, becomes 5901234123457

 "123-4567890-123"  # INVALID (Invalid checkdigit)

 1234567890  # INVALID (Less than 13 digits)

 12345678901234  # INVALID (More than 13 digits)

=head1 DESCRIPTION

Nondigits [^0-9] will be removed during coercion.

Checksum digit must be valid.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-EAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-EAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-EAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
