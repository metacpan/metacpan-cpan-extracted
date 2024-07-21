package Sah::Schema::currency::code;

use strict;

use Locale::Codes::Currency_Codes ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-06-26'; # DATE
our $DIST = 'Sah-SchemaBundle-Currency'; # DIST
our $VERSION = '0.009'; # VERSION

my $codes = [sort keys %{ $Locale::Codes::Data{'currency'}{'code2id'}{alpha} }];
die "Can't extract any currency codes from Locale::Codes::Currency_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Currency code',
    description => <<'_',

Accept only current (not retired) codes. Code will be converted to uppercase.

_
    match => '\A[A-Z]{3}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['From_str::to_upper'],
    examples => [
        {value=>'', valid=>0},
        {value=>'idr', valid=>1, validated_value=>'IDR'},
        {value=>'foo', valid=>0},
    ],
}];

1;
# ABSTRACT: Currency code

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::currency::code - Currency code

=head1 VERSION

This document describes version 0.009 of Sah::Schema::currency::code (from Perl distribution Sah-SchemaBundle-Currency), released on 2024-06-26.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     "in" => [
       "AED",
       "AFN",
       "ALL",
       "AMD",
       "ANG",
       "AOA",
       "ARS",
       "AUD",
       "AWG",
       "AZN",
       "BAM",
       "BBD",
       "BDT",
       "BGN",
       "BHD",
       "BIF",
       "BMD",
       "BND",
       "BOB",
       "BOV",
       "BRL",
       "BSD",
       "BTN",
       "BWP",
       "BYN",
       "BZD",
       "CAD",
       "CDF",
       "CHE",
       "CHF",
       "CHW",
       "CLF",
       "CLP",
       "CNY",
       "COP",
       "COU",
       "CRC",
       "CUC",
       "CUP",
       "CVE",
       "CZK",
       "DJF",
       "DKK",
       "DOP",
       "DZD",
       "EGP",
       "ERN",
       "ETB",
       "EUR",
       "FJD",
       "FKP",
       "GBP",
       "GEL",
       "GHS",
       "GIP",
       "GMD",
       "GNF",
       "GTQ",
       "GYD",
       "HKD",
       "HNL",
       "HTG",
       "HUF",
       "IDR",
       "ILS",
       "INR",
       "IQD",
       "IRR",
       "ISK",
       "JMD",
       "JOD",
       "JPY",
       "KES",
       "KGS",
       "KHR",
       "KMF",
       "KPW",
       "KRW",
       "KWD",
       "KYD",
       "KZT",
       "LAK",
       "LBP",
       "LKR",
       "LRD",
       "LSL",
       "LYD",
       "MAD",
       "MDL",
       "MGA",
       "MKD",
       "MMK",
       "MNT",
       "MOP",
       "MRU",
       "MUR",
       "MVR",
       "MWK",
       "MXN",
       "MXV",
       "MYR",
       "MZN",
       "NAD",
       "NGN",
       "NIO",
       "NOK",
       "NPR",
       "NZD",
       "OMR",
       "PAB",
       "PEN",
       "PGK",
       "PHP",
       "PKR",
       "PLN",
       "PYG",
       "QAR",
       "RON",
       "RSD",
       "RUB",
       "RWF",
       "SAR",
       "SBD",
       "SCR",
       "SDG",
       "SEK",
       "SGD",
       "SHP",
       "SLE",
       "SLL",
       "SOS",
       "SRD",
       "SSP",
       "STN",
       "SVC",
       "SYP",
       "SZL",
       "THB",
       "TJS",
       "TMT",
       "TND",
       "TOP",
       "TRY",
       "TTD",
       "TWD",
       "TZS",
       "UAH",
       "UGX",
       "USD",
       "USN",
       "UYI",
       "UYU",
       "UYW",
       "UZS",
       "VED",
       "VES",
       "VND",
       "VUV",
       "WST",
       "XAF",
       "XAG",
       "XAU",
       "XBA" .. "XBD",
       "XCD",
       "XDR",
       "XOF",
       "XPD",
       "XPF",
       "XPT",
       "XSU",
       "XUA",
       "YER",
       "ZAR",
       "ZMW",
       "ZWL",
     ],
     "match" => "\\A[A-Z]{3}\\z",
     "x.perl.coerce_rules" => ["From_str::to_upper"],
   },
 ]

Base type: L<str|Data::Sah::Type::str>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "idr"  # valid, becomes "IDR"

 "foo"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("currency::code*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("currency::code", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "idr";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "";
 my $errmsg = $validator->($data); # => "Must be one of [\"AED\",\"AFN\",\"ALL\",\"AMD\",\"ANG\",\"AOA\",\"ARS\",\"AUD\",\"AWG\",\"AZN\",\"BAM\",\"BBD\",\"BDT\",\"BGN\",\"BHD\",\"BIF\",\"BMD\",\"BND\",\"BOB\",\"BOV\",\"BRL\",\"BSD\",\"BTN\",\"BWP\",\"BYN\",\"BZD\",\"CAD\",\"CDF\",\"CHE\",\"CHF\",\"CHW\",\"CLF\",\"CLP\",\"CNY\",\"COP\",\"COU\",\"CRC\",\"CUC\",\"CUP\",\"CVE\",\"CZK\",\"DJF\",\"DKK\",\"DOP\",\"DZD\",\"EGP\",\"ERN\",\"ETB\",\"EUR\",\"FJD\",\"FKP\",\"GBP\",\"GEL\",\"GHS\",\"GIP\",\"GMD\",\"GNF\",\"GTQ\",\"GYD\",\"HKD\",\"HNL\",\"HTG\",\"HUF\",\"IDR\",\"ILS\",\"INR\",\"IQD\",\"IRR\",\"ISK\",\"JMD\",\"JOD\",\"JPY\",\"KES\",\"KGS\",\"KHR\",\"KMF\",\"KPW\",\"KRW\",\"KWD\",\"KYD\",\"KZT\",\"LAK\",\"LBP\",\"LKR\",\"LRD\",\"LSL\",\"LYD\",\"MAD\",\"MDL\",\"MGA\",\"MKD\",\"MMK\",\"MNT\",\"MOP\",\"MRU\",\"MUR\",\"MVR\",\"MWK\",\"MXN\",\"MXV\",\"MYR\",\"MZN\",\"NAD\",\"NGN\",\"NIO\",\"NOK\",\"NPR\",\"NZD\",\"OMR\",\"PAB\",\"PEN\",\"PGK\",\"PHP\",\"PKR\",\"PLN\",\"PYG\",\"QAR\",\"RON\",\"RSD\",\"RUB\",\"RWF\",\"SAR\",\"SBD\",\"SCR\",\"SDG\",\"SEK\",\"SGD\",\"SHP\",\"SLE\",\"SLL\",\"SOS\",\"SRD\",\"SSP\",\"STN\",\"SVC\",\"SYP\",\"SZL\",\"THB\",\"TJS\",\"TMT\",\"TND\",\"TOP\",\"TRY\",\"TTD\",\"TWD\",\"TZS\",\"UAH\",\"UGX\",\"USD\",\"USN\",\"UYI\",\"UYU\",\"UYW\",\"UZS\",\"VED\",\"VES\",\"VND\",\"VUV\",\"WST\",\"XAF\",\"XAG\",\"XAU\",\"XBA\",\"XBB\",\"XBC\",\"XBD\",\"XCD\",\"XDR\",\"XOF\",\"XPD\",\"XPF\",\"XPT\",\"XSU\",\"XUA\",\"YER\",\"ZAR\",\"ZMW\",\"ZWL\"]"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("currency::code", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "idr";
 my $res = $validator->($data); # => ["","IDR"]
 
 # a sample invalid data
 $data = "";
 my $res = $validator->($data); # => ["Must be one of [\"AED\",\"AFN\",\"ALL\",\"AMD\",\"ANG\",\"AOA\",\"ARS\",\"AUD\",\"AWG\",\"AZN\",\"BAM\",\"BBD\",\"BDT\",\"BGN\",\"BHD\",\"BIF\",\"BMD\",\"BND\",\"BOB\",\"BOV\",\"BRL\",\"BSD\",\"BTN\",\"BWP\",\"BYN\",\"BZD\",\"CAD\",\"CDF\",\"CHE\",\"CHF\",\"CHW\",\"CLF\",\"CLP\",\"CNY\",\"COP\",\"COU\",\"CRC\",\"CUC\",\"CUP\",\"CVE\",\"CZK\",\"DJF\",\"DKK\",\"DOP\",\"DZD\",\"EGP\",\"ERN\",\"ETB\",\"EUR\",\"FJD\",\"FKP\",\"GBP\",\"GEL\",\"GHS\",\"GIP\",\"GMD\",\"GNF\",\"GTQ\",\"GYD\",\"HKD\",\"HNL\",\"HTG\",\"HUF\",\"IDR\",\"ILS\",\"INR\",\"IQD\",\"IRR\",\"ISK\",\"JMD\",\"JOD\",\"JPY\",\"KES\",\"KGS\",\"KHR\",\"KMF\",\"KPW\",\"KRW\",\"KWD\",\"KYD\",\"KZT\",\"LAK\",\"LBP\",\"LKR\",\"LRD\",\"LSL\",\"LYD\",\"MAD\",\"MDL\",\"MGA\",\"MKD\",\"MMK\",\"MNT\",\"MOP\",\"MRU\",\"MUR\",\"MVR\",\"MWK\",\"MXN\",\"MXV\",\"MYR\",\"MZN\",\"NAD\",\"NGN\",\"NIO\",\"NOK\",\"NPR\",\"NZD\",\"OMR\",\"PAB\",\"PEN\",\"PGK\",\"PHP\",\"PKR\",\"PLN\",\"PYG\",\"QAR\",\"RON\",\"RSD\",\"RUB\",\"RWF\",\"SAR\",\"SBD\",\"SCR\",\"SDG\",\"SEK\",\"SGD\",\"SHP\",\"SLE\",\"SLL\",\"SOS\",\"SRD\",\"SSP\",\"STN\",\"SVC\",\"SYP\",\"SZL\",\"THB\",\"TJS\",\"TMT\",\"TND\",\"TOP\",\"TRY\",\"TTD\",\"TWD\",\"TZS\",\"UAH\",\"UGX\",\"USD\",\"USN\",\"UYI\",\"UYU\",\"UYW\",\"UZS\",\"VED\",\"VES\",\"VND\",\"VUV\",\"WST\",\"XAF\",\"XAG\",\"XAU\",\"XBA\",\"XBB\",\"XBC\",\"XBD\",\"XCD\",\"XDR\",\"XOF\",\"XPD\",\"XPF\",\"XPT\",\"XSU\",\"XUA\",\"YER\",\"ZAR\",\"ZMW\",\"ZWL\"]",""]

Data::Sah can also create validator that returns a hash of detailed error
message. Data::Sah can even create validator that targets other language, like
JavaScript, from the same schema. Other things Data::Sah can do: show source
code for validator, generate a validator code with debug comments and/or log
statements, generate human text from schema. See its documentation for more
details.

=head2 Using with Params::Sah

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("currency::code*");
     $validator->(\@args);
     ...
 }

=head2 Using with Perinci::CmdLine::Lite

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>) to create a CLI:

 # in lib/MyApp.pm
 package
   MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['currency::code*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }
 1;

 # in myapp.pl
 package
   main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'/MyApp/myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

=head2 Using on the CLI with validate-with-sah

To validate some data on the CLI, you can use L<validate-with-sah> utility.
Specify the schema as the first argument (encoded in Perl syntax) and the data
to validate as the second argument (encoded in Perl syntax):

 % validate-with-sah '"currency::code*"' '"data..."'

C<validate-with-sah> has several options for, e.g. validating multiple data,
showing the generated validator code (Perl/JavaScript/etc), or loading
schema/data from file. See its manpage for more details.


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema (requires
L<Type::Tiny> as well as L<Type::FromSah>):

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('currency::code*', name=>'CurrencyCode')
     );
 }

 use My::Types qw(CurrencyCode);
 CurrencyCode->assert_valid($data);

=head1 DESCRIPTION

Accept only current (not retired) codes. Code will be converted to uppercase.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Currency>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Currency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
