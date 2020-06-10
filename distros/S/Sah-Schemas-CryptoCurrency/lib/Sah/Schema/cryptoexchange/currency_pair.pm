package Sah::Schema::cryptoexchange::currency_pair;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-CryptoCurrency'; # DIST
our $VERSION = '0.015'; # VERSION

our $schema = [str => {
    summary => 'Currency pair, e.g. LTC/USD',
    description => <<'_',

Currency pair is string in the form of *currency1*/*currency2*, where
*currency1* is called the base currency and must be a known cryptocurrency code
(e.g. LTC) while *currency2* is the quote (or price) currency and must be a
known fiat currency or a known cryptocurrency code (e.g. USD, or BTC).

Cryptocurrency code is checked against catalog in <pm:CryptoCurrency::Catalog>,
while fiat currency code is checked against <pm:Locale::Codes::Currency_Codes>.

Will be normalized to uppercase.

_
    match => qr(\A\S+/\S+\z),
    #'x.completion' => 'cryptoexchange_currency_pair',
    'x.perl.coerce_rules' => ['From_str::to_cryptoexchange_currency_pair'],
}, {}];

1;
# ABSTRACT: Currency pair, e.g. LTC/USD

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptoexchange::currency_pair - Currency pair, e.g. LTC/USD

=head1 VERSION

This document describes version 0.015 of Sah::Schema::cryptoexchange::currency_pair (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("cryptoexchange::currency_pair*");
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
             schema => ['cryptoexchange::currency_pair*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

=head1 DESCRIPTION

Currency pair is string in the form of I<currency1>/I<currency2>, where
I<currency1> is called the base currency and must be a known cryptocurrency code
(e.g. LTC) while I<currency2> is the quote (or price) currency and must be a
known fiat currency or a known cryptocurrency code (e.g. USD, or BTC).

Cryptocurrency code is checked against catalog in L<CryptoCurrency::Catalog>,
while fiat currency code is checked against L<Locale::Codes::Currency_Codes>.

Will be normalized to uppercase.

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
