package Sah::Schemas::CryptoCurrency;

our $DATE = '2018-06-06'; # DATE
our $VERSION = '0.009'; # VERSION

1;
# ABSTRACT: Various Sah cryptocurrency schemas

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::CryptoCurrency - Various Sah cryptocurrency schemas

=head1 VERSION

This document describes version 0.009 of Sah::Schemas::CryptoCurrency (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2018-06-06.

=head1 SAH SCHEMAS

=over

=item * L<cryptocurrency|Sah::Schema::cryptocurrency>

Cryptocurrency code, name, or safename.

Cryptocurrency code or name or safename that is listed in
L<CryptoCurrency::Catalog>, e.g. BTC, "Bitcoin Cash", ethereum-classic.

Code/name/safename must be listed.

Will be normalized to code in uppercase.


=item * L<cryptoexchange|Sah::Schema::cryptoexchange>

Cryptoexchange code, name, or safename.

Cryptoexchange code or name or safename that is listed in
L<CryptoExchange::Catalog>, e.g. GDAX, "BX Thailand", bx-thailand.

Code/name/safename must be listed.

Will be normalized to safename in lowercase.


=item * L<fiat_currency|Sah::Schema::fiat_currency>

Alias for currency::code.

=item * L<fiat_or_cryptocurrency|Sah::Schema::fiat_or_cryptocurrency>

Fiat currency code or cryptocurrency code, name, or safename.

Either: a) a known fiat currency code (e.g. USD, GBP), or b) a known
cryptocurrency code or name or safename (e.g. BTC, "Bitcoin Cash",
ethereum-classic). Fiat currency code is checked against known codes in
L<Locale::Codes::Currency_Codes>. Cryptocurrency code/name/safename is checked
against catalog in L<CryptoCurrency::Catalog>. Cryptocurrency name/safename
Will be normalized to code in uppercase.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-CryptoCurrency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-CryptoCurrency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-CryptoCurrency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah> - specification

L<Data::Sah>

L<Sah::Schemas::Currency>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
