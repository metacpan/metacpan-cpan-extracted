package Sah::Schema::cryptoexchange::currency_pair;

our $DATE = '2018-06-10'; # DATE
our $VERSION = '0.011'; # VERSION

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
    'x.perl.coerce_rules' => ['str_to_cryptoexchange_currency_pair'],
}, {}];

1;
# ABSTRACT: Currency pair, e.g. LTC/USD

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptoexchange::currency_pair - Currency pair, e.g. LTC/USD

=head1 VERSION

This document describes version 0.011 of Sah::Schema::cryptoexchange::currency_pair (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2018-06-10.

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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
