package Sah::Schema::cryptoexchange;

our $DATE = '2018-06-10'; # DATE
our $VERSION = '0.011'; # VERSION

our $schema = [str => {
    summary => 'Cryptoexchange code, name, or safename',
    description => <<'_',

Cryptoexchange code or name or safename that is listed in
<pm:CryptoExchange::Catalog>, e.g. GDAX, "BX Thailand", bx-thailand.

Code/name/safename must be listed.

Will be normalized to safename in lowercase.

_
    'x.completion' => 'cryptoexchange',
    'x.perl.coerce_rules' => ['str_to_cryptoexchange_safename'],
}, {}];

1;
# ABSTRACT: Cryptoexchange code, name, or safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptoexchange - Cryptoexchange code, name, or safename

=head1 VERSION

This document describes version 0.011 of Sah::Schema::cryptoexchange (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2018-06-10.

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

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
