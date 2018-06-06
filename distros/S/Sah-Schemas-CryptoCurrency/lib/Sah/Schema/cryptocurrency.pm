package Sah::Schema::cryptocurrency;

our $DATE = '2018-06-06'; # DATE
our $VERSION = '0.009'; # VERSION

our $schema = [str => {
    summary => 'Cryptocurrency code, name, or safename',
    description => <<'_',

Cryptocurrency code or name or safename that is listed in
<pm:CryptoCurrency::Catalog>, e.g. BTC, "Bitcoin Cash", ethereum-classic.

Code/name/safename must be listed.

Will be normalized to code in uppercase.

_
    'x.completion' => 'cryptocurrency',
    'x.perl.coerce_rules' => ['str_to_cryptocurrency_code'],
}, {}];

1;
# ABSTRACT: Cryptocurrency code, name, or safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptocurrency - Cryptocurrency code, name, or safename

=head1 VERSION

This document describes version 0.009 of Sah::Schema::cryptocurrency (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2018-06-06.

=head1 DESCRIPTION

Cryptocurrency code or name or safename that is listed in
L<CryptoCurrency::Catalog>, e.g. BTC, "Bitcoin Cash", ethereum-classic.

Code/name/safename must be listed.

Will be normalized to code in uppercase.

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
