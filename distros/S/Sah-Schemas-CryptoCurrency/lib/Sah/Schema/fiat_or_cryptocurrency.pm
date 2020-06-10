package Sah::Schema::fiat_or_cryptocurrency;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-CryptoCurrency'; # DIST
our $VERSION = '0.015'; # VERSION

our $schema = [str => {
    summary => 'Fiat currency code or cryptocurrency code, name, or safename',
    description => <<'_',

Either: a) a known fiat currency code (e.g. USD, GBP), or b) a known
cryptocurrency code or name or safename (e.g. BTC, "Bitcoin Cash",
ethereum-classic). Fiat currency code is checked against known codes in
<pm:Locale::Codes::Currency_Codes>. Cryptocurrency code/name/safename is checked
against catalog in <pm:CryptoCurrency::Catalog>. Cryptocurrency name/safename
Will be normalized to code in uppercase.

_
    'x.completion' => 'fiat_or_cryptocurrency',
    'x.perl.coerce_rules' => ['From_str::to_fiat_or_cryptocurrency_code'],
    examples => [
    ],
}, {}];

1;
# ABSTRACT: Fiat currency code or cryptocurrency code, name, or safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::fiat_or_cryptocurrency - Fiat currency code or cryptocurrency code, name, or safename

=head1 VERSION

This document describes version 0.015 of Sah::Schema::fiat_or_cryptocurrency (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("fiat_or_cryptocurrency*");
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
             schema => ['fiat_or_cryptocurrency*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

=head1 DESCRIPTION

Either: a) a known fiat currency code (e.g. USD, GBP), or b) a known
cryptocurrency code or name or safename (e.g. BTC, "Bitcoin Cash",
ethereum-classic). Fiat currency code is checked against known codes in
L<Locale::Codes::Currency_Codes>. Cryptocurrency code/name/safename is checked
against catalog in L<CryptoCurrency::Catalog>. Cryptocurrency name/safename
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

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
