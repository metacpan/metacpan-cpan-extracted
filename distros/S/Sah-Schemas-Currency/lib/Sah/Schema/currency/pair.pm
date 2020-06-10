package Sah::Schema::currency::pair;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-04'; # DATE
our $DIST = 'Sah-Schemas-Currency'; # DIST
our $VERSION = '0.006'; # VERSION

our $schema = [str => {
    summary => 'Fiat currency pair, e.g. USD/IDR',
    description => <<'_',

Currency pair is string in the form of *currency1*/*currency2*, where
*currency1* is called the base currency while *currency2* is the quote (or
price) currency. Both must be known currency codes (e.g. USD, or IDR).

Currency code is checked against <pm:Locale::Codes::Currency_Codes>.

Will be normalized to uppercase.

_
    match => qr(\A\S+/\S+\z),
    #'x.completion' => 'currency_pair',
    'x.perl.coerce_rules' => ['From_str::to_currency_pair'],
    examples => [
        {value=>'', valid=>0},
        {value=>'idr', valid=>0},
        {value=>'usd/idr', valid=>1, res=>'USD/IDR'},
        {value=>'usd idr', valid=>0},
        {value=>'usd/foo', valid=>0},
    ],
}, {}];

1;
# ABSTRACT: Fiat currency pair, e.g. USD/IDR

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::currency::pair - Fiat currency pair, e.g. USD/IDR

=head1 VERSION

This document describes version 0.006 of Sah::Schema::currency::pair (from Perl distribution Sah-Schemas-Currency), released on 2020-03-04.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("currency::pair*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used in L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['currency::pair*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 undef  # INVALID

 undef  # INVALID

 undef  # valid, becomes "USD/IDR"

 undef  # INVALID

 undef  # INVALID

=head1 DESCRIPTION

Currency pair is string in the form of I<currency1>/I<currency2>, where
I<currency1> is called the base currency while I<currency2> is the quote (or
price) currency. Both must be known currency codes (e.g. USD, or IDR).

Currency code is checked against L<Locale::Codes::Currency_Codes>.

Will be normalized to uppercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Currency>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Currency>

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
