package Sah::Schema::cryptocurrency::code;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-CryptoCurrency'; # DIST
our $VERSION = '0.015'; # VERSION

our $schema = [str => {
    summary => 'Cryptocurrency code',
    description => <<'_',

Cryptocurrency code that is listed in <pm:CryptoCurrency::Catalog>, e.g. BTC,
ltc, ETH.

Code will be converted to uppercase.

_
    'x.completion' => 'cryptocurrency_code',
    'x.perl.coerce_rules' => ['From_str::to_cryptocurrency_code'],
    examples => [
        {value=>'', valid=>0},
        {value=>'btc', valid=>1, validated_value=>'BTC'},
        {value=>'bitcoin', valid=>1, validated_value=>'BTC'},
        {value=>'bitCOIN caSh', valid=>1, validated_value=>'BCH'},
        {value=>'notbtc', valid=>0},
    ],
}, {}];

1;
# ABSTRACT: Cryptocurrency code

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::cryptocurrency::code - Cryptocurrency code

=head1 VERSION

This document describes version 0.015 of Sah::Schema::cryptocurrency::code (from Perl distribution Sah-Schemas-CryptoCurrency), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("cryptocurrency::code*");
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
             schema => ['cryptocurrency::code*'],
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

 "btc"  # valid, becomes "BTC"

 "bitcoin"  # valid, becomes "BTC"

 "bitCOIN caSh"  # valid, becomes "BCH"

 "notbtc"  # INVALID

=head1 DESCRIPTION

Cryptocurrency code that is listed in L<CryptoCurrency::Catalog>, e.g. BTC,
ltc, ETH.

Code will be converted to uppercase.

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
