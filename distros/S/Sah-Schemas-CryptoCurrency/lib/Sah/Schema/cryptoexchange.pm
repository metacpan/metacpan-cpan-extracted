package Sah::Schema::cryptoexchange;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-CryptoCurrency'; # DIST
our $VERSION = '0.015'; # VERSION

our $schema = [str => {
    summary => 'Cryptoexchange code, name, or safename',
    description => <<'_',

Cryptoexchange code or name or safename that is listed in
<pm:CryptoExchange::Catalog>, e.g. GDAX, "BX Thailand", bx-thailand.

Code/name/safename must be listed.

Will be normalized to safename in lowercase.

_
    'x.completion' => 'cryptoexchange',
    'x.perl.coerce_rules' => ['From_str::to_cryptoexchange_safename'],
    examples => [
        {value=>'', valid=>0},
        {value=>'foo', valid=>0},
        {value=>'BX Thailand', valid=>1, validated_value=>'bx-thailand'},
        {value=>'BX-thailand', valid=>1, validated_value=>'bx-thailand'},
        {value=>'bx', valid=>1, validated_value=>'bx-thailand'},
    ],
}, {}];

1;
# ABSTRACT: Cryptoexchange code, name, or safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptoexchange - Cryptoexchange code, name, or safename

=head1 VERSION

This document describes version 0.015 of Sah::Schema::cryptoexchange (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("cryptoexchange*");
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
             schema => ['cryptoexchange*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 ""  # INVALID

 "foo"  # INVALID

 "BX Thailand"  # valid, becomes "bx-thailand"

 "BX-thailand"  # valid, becomes "bx-thailand"

 "bx"  # valid, becomes "bx-thailand"

=head1 DESCRIPTION

Cryptoexchange code or name or safename that is listed in
L<CryptoExchange::Catalog>, e.g. GDAX, "BX Thailand", bx-thailand.

Code/name/safename must be listed.

Will be normalized to safename in lowercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CryptoCurrency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CryptoCurrency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CryptoCurrency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
