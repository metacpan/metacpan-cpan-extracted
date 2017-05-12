package Number::Phone::CountryCode;

use strict;
use base qw(Class::Accessor);

__PACKAGE__->mk_ro_accessors(qw(country
                                country_code
                                idd_prefix
                                ndd_prefix));

our $VERSION = '0.02';

# Codes hash
# ISO code maps to 3 element array containing:
# Country prefix
# IDD prefix
# NDD prefix

my %Codes = (
    AD => ['376',   '00',  undef],     # Andorra
    AE => ['971',   '00',    '0'],     # United Arab Emirates
    AF => [ '93',   '00',    '0'],     # Afghanistan
    AG => [  '1',  '011',    '1'],     # Antigua and Barbuda
    AG => [  '1',  '011',    '1'],     # Antigua and Barbuda
    AI => [  '1',  '011',    '1'],     # Anguilla
    AL => ['355',   '00',    '0'],     # Albania
    AM => ['374',   '00',    '8'],     # Armenia
    AN => ['599',   '00',    '0'],     # Netherlands Antilles
    AO => ['244',   '00',    '0'],     # Angola
    AQ => ['672',  undef,  undef],     # Antarctica
    AR => [ '54',   '00',    '0'],     # Argentina
    AS => [  '1',  '011',    '1'],     # American Samoa
    AT => [ '43',   '00',    '0'],     # Austria
    AU => [ '61',   '00',  undef],     # Australia
    AW => ['297',   '00',  undef],     # Aruba
    AZ => ['994',   '00',    '8'],     # Azerbaijan
    BA => ['387',   '00',    '0'],     # Bosnia and Herzegovina
    BB => [  '1',  '011',    '1'],     # Barbados
    BD => ['880',   '00',    '0'],     # Bangladesh
    BE => [ '32',   '00',    '0'],     # Belgium
    BF => ['226',   '00',  undef],     # Burkina Faso
    BG => ['359',   '00',    '0'],     # Bulgaria
    BH => ['973',   '00',  undef],     # Bahrain
    BI => ['257',   '00',  undef],     # Burundi
    BJ => ['229',   '00',  undef],     # Benin
    BM => [  '1',  '011',    '1'],     # Bermuda
    BN => ['673',   '00',    '0'],     # Brunei Darussalam
    BO => ['591',   '00',    '0'],     # Bolivia
    BR => [ '55',   '00',    '0'],     # Brazil
    BS => [  '1',  '011',    '1'],     # Bahamas
    BT => ['975',   '00',  undef],     # Bhutan
    BW => ['267',   '00',  undef],     # Botswana
    BY => ['375',  '810',    '8'],     # Belarus (IDD really 8**10)
    BZ => ['501',   '00',    '0'],     # Belize
    CA => [  '1',  '011',    '1'],     # Canada
    CD => ['243',   '00',  undef],     # Congo (Dem. Rep. of / Zaire)
    CF => ['236',   '00',  undef],     # Central African Republic
    CH => [ '41',   '00',    '0'],     # Switzerland
    CI => ['225',   '00',    '0'],     # Cote D'Ivoire
    CL => [ '56',   '00',    '0'],     # Chile
    CM => ['237',   '00',  undef],     # Cameroon
    CN => [ '86',   '00',    '0'],     # China
    CO => [ '57',  '009',   '09'],     # Colombia
    CR => ['506',   '00',  undef],     # Costa Rica
    CV => ['238',    '0',  undef],     # Cape Verde Islands
    CX => [ '61', '0011',    '0'],     # Christmas Island
    CY => ['357',   '00',  undef],     # Cyprus
    CZ => ['420',   '00',  undef],     # Czech Republic
    DE => [ '49',   '00',    '0'],     # Germany
    DJ => ['253',   '00',  undef],     # Djibouti
    DK => [ '45',   '00',  undef],     # Denmark
    DO => [  '1',  '011',      1],     # Dominican Republic
    DZ => ['213',   '00',    '7'],     # Algeria
    EC => ['593',   '00',    '0'],     # Ecuador
    EE => ['372',   '00',  undef],     # Estonia
    EG => [ '20',   '00',    '0'],     # Egypt
    EH => ['212',   '00',    '0'],     # Western Sahara
    ER => ['291',   '00',    '0'],     # Eritrea
    ET => ['251',   '00',    '0'],     # Ethiopia
    FI => ['358',   '00',    '0'],     # Finland
    FJ => ['679',   '00',  undef],     # Fiji
    FK => ['500',   '00',  undef],     # Falkland Islands (Malvinas)
    FM => ['691',  '011',    '1'],     # Micronesia, Federated States of
    FO => ['298',   '00',  undef],     # Faroe Islands
    FR => [ '33',   '00',  undef],     # France
    GA => ['241',   '00',  undef],     # Gabonese Republic
    GB => [ '44',   '00',    '0'],     # United Kingdom
    GD => [  '1',  '011',    '4'],     # Grenada
    GF => ['594',   '00',  undef],     # French Guiana
    GH => ['233',   '00',  undef],     # Ghana
    GI => ['350',   '00',  undef],     # Gibraltar
    GL => ['299',   '00',  undef],     # Greenland
    GM => ['220',   '00',  undef],     # Gambia
    GP => ['590',   '00',  undef],     # Guadeloupe
    GQ => ['240',   '00',  undef],     # Equatorial Guinea
    GR => [ '30',   '00',  undef],     # Greece
    GS => ['995',  '810',    '8'],     # South Georgia and the South Sandwich Islands (IDD really 8**10)
    GT => ['502',   '00',  undef],     # Guatemala
    GW => ['245',   '00',  undef],     # Guinea-Bissau
    HK => ['852',  '001',  undef],     # Hong Kong
    HN => ['504',   '00',    '0'],     # Honduras
    HR => ['385',   '00',    '0'],     # Croatia
    HT => ['509',   '00',    '0'],     # Haiti
    HU => [ '36',   '00',   '06'],     # Hungary
    ID => [ '62',  '001',    '0'],     # Indonesia
    IE => ['353',   '00',    '0'],     # Ireland
    IL => ['972',   '00',    '0'],     # Israel
    IN => [ '91',   '00',    '0'],     # India
    IQ => ['964',   '00',    '0'],     # Iraq
    IR => [ '98',   '00',    '0'],     # Iran, Islamic Republic of
    IT => [ '39',   '00',  undef],     # Italy
    JM => [  '1',  '011',    '1'],     # Jamaica
    JO => ['962',   '00',    '0'],     # Jordan
    JP => [ '81',  '001',    '0'],     # Japan
    KE => ['254',  '000',    '0'],     # Kenya
    KG => ['996',   '00',    '0'],     # Kyrgyzstan
    KH => ['855',  '001',    '0'],     # Cambodia
    KI => ['686',   '00',    '0'],     # Kiribati
    KM => ['269',   '00',  undef],     # Comoros
    KN => [  '1',  '011',    '1'],     # Saint Kitts and Nevis
    KP => ['850',   '00',    '0'],     # Korea, Democratic People's Republic of
    KR => [ '82',  '001',    '0'],     # Korea (South)
    KW => ['965',   '00',    '0'],     # Kuwait
    KY => [  '1',  '011',    '1'],     # Cayman Islands
    KZ => [  '7',  '810',    '8'],     # Kazakhstan (IDD really 8**10)
    LB => ['961',   '00',    '0'],     # Lebanon
    LC => [  '1',  '011',    '1'],     # Saint Lucia
    LI => ['423',   '00',  undef],     # Liechtenstein
    LK => [ '94',   '00',    '0'],     # Sri Lanka
    LR => ['231',   '00',   '22'],     # Liberia
    LS => ['266',   '00',    '0'],     # Lesotho
    LT => ['370',   '00',    '8'],     # Lithuania
    LU => ['352',   '00',  undef],     # Luxembourg
    LV => ['371',   '00',    '8'],     # Latvia
    LY => ['218',   '00',    '0'],     # Libyan Arab Jamahiriya
    MA => ['212',   '00',  undef],     # Morocco
    MC => ['377',   '00',    '0'],     # Monaco
    MD => ['373',   '00',    '0'],     # Moldova, Republic of
    MG => ['261',   '00',    '0'],     # Madagascar
    MH => ['692',  '011',    '1'],     # Marshall Islands
    MK => ['389',   '00',    '0'],     # Macedonia, the Former Yugoslav Republic of
    MN => ['976',  '001',    '0'],     # Mongolia
    MO => ['853',   '00',    '0'],     # Macao
    MP => [  '1',  '011',    '1'],     # Northern Mariana Islands
    MQ => ['596',   '00',    '0'],     # Martinique
    MR => ['222',   '00',    '0'],     # Mauritania
    MS => [  '1',  '011',    '1'],     # Montserrat
    MU => ['230',   '00',    '0'],     # Mauritius
    MV => ['960',   '00',    '0'],     # Maldives
    MW => ['265',   '00',  undef],     # Malawi
    MX => [ '52',   '00',   '01'],     # Mexico
    MY => [ '60',   '00',    '0'],     # Malaysia
    MZ => ['258',   '00',    '0'],     # Mozambique
    NA => ['264',   '00',    '0'],     # Namibia
    NC => ['687',   '00',    '0'],     # New Caledonia
    NE => ['227',   '00',    '0'],     # Niger
    NF => ['672',   '00',  undef],     # Norfolk Island
    NG => ['234',  '009',    '0'],     # Nigeria
    NI => ['505',   '00',    '0'],     # Nicaragua
    NL => [ '31',   '00',    '0'],     # Netherlands
    NO => [ '47',   '00',  undef],     # Norway
    NR => ['674',   '00',    '0'],     # Nauru
    NU => ['683',   '00',    '0'],     # Niue
    NZ => [ '64',   '00',    '0'],     # New Zealand
    PA => ['507',   '00',    '0'],     # Panama
    PE => [ '51',   '00',    '0'],     # Peru
    PF => ['689',   '00',  undef],     # French Polynesia
    PG => ['675',   '05',  undef],     # Papua New Guinea
    PH => [ '63',   '00',    '0'],     # Philippines
    PK => [ '92',   '00',    '0'],     # Pakistan
    PL => [ '48',   '00',    '0'],     # Poland
    PM => ['508',   '00',    '0'],     # Saint Pierre and Miquelon
    PR => [  '1',  '011',    '1'],     # Puerto Rico
    PS => ['970',   '00',    '0'],     # Palestinian Territory, Occupied
    PT => ['351',   '00',  undef],     # Portugal
    PW => ['680',  '011',  undef],     # Palau
    PY => ['595',  '002',    '0'],     # Paraguay
    QA => ['974',   '00',    '0'],     # Qatar
    RE => ['262',   '00',    '0'],     # Reunion
    RO => [ '40',   '00',    '0'],     # Romania
    RS => ['381',   '99',    '0'],     # Serbia
    RW => ['250',   '00',    '0'],     # Rwanda
    SA => ['966',   '00',    '0'],     # Saudi Arabia
    SB => ['677',   '00',  undef],     # Solomon Islands
    SC => ['248',   '00',    '0'],     # Seychelles
    SD => ['249',   '00',    '0'],     # Sudan
    SE => [ '46',   '00',    '0'],     # Sweden
    SG => [ '65',  '001',  undef],     # Singapore
    SH => ['290',   '00',  undef],     # Saint Helena
    SI => ['386',   '00',    '0'],     # Slovenia
    SK => ['421',   '00',    '0'],     # Slovakia
    SL => ['232',   '00',    '0'],     # Sierra Leone
    SM => ['378',   '00',    '0'],     # San Marino
    SN => ['221',   '00',    '0'],     # Senegal
    SO => ['252',   '00',  undef],     # Somalia
    SR => ['597',   '00',  undef],     # Suriname
    ST => ['239',   '00',    '0'],     # Sao Tome and Principe
    SV => ['503',   '00',  undef],     # El Salvador
    SZ => ['268',   '00',  undef],     # Swaziland
    TC => [  '1',  '011',    '1'],     # Turks and Caicos Islands
    TD => ['235',   '15',  undef],     # Chad
    TG => ['228',   '00',  undef],     # Togo
    TH => [ '66',  '001',    '0'],     # Thailand
    TJ => ['992',  '810',    '8'],     # Tajikistan (IDD really 8**10)
    TK => ['690',   '00',  undef],     # Tokelau
    TL => ['670',   '00',  undef],     # Timor-Leste
    TM => ['993',  '810',    '8'],     # Turkmenistan (IDD really 8**10)
    TN => ['216',   '00',    '0'],     # Tunisia
    TR => [ '90',   '00',    '0'],     # Turkey
    TT => [  '1',  '011',    '1'],     # Trinidad and Tobago
    TV => ['688',   '00',  undef],     # Tuvalu
    TW => ['886',  '002',  undef],     # Taiwan, Province of China
    TZ => ['255',  '000',    '0'],     # Tanzania, United Republic of
    UA => ['380',  '810',    '8'],     # Ukraine (IDD really 8**10)
    UG => ['256',  '000',    '0'],     # Uganda
    US => [  '1',  '011',    '1'],     # United States
    UY => ['598',   '00',    '0'],     # Uruguay
    UZ => ['998',  '810',    '8'],     # Uzbekistan (IDD really 8**10)
    VA => ['379',   '00',  undef],     # Holy See (Vatican City State)
    VC => [  '1',  '011',    '1'],     # Saint Vincent and the Grenadines
    VE => [ '58',   '00',    '0'],     # Venezuela
    VG => [  '1',  '011',    '1'],     # Virgin Islands, British
    VI => [  '1',  '011',    '1'],     # Virgin Islands, U.S.
    VN => [ '84',   '00',    '0'],     # Viet Nam
    VU => ['678',   '00',  undef],     # Vanuatu
    WF => ['681',   '19',  undef],     # Wallis and Futuna Islands
    WS => ['685',    '0',    '0'],     # Samoa (Western)
    YE => ['967',   '00',    '0'],     # Yemen
    YT => ['269',   '00',  undef],     # Mayotte
    ZA => [ '27',   '09',    '0'],     # South Africa
    ZW => ['263',  '110',    '0'],     # Zimbabwe
);

=head1 NAME

Number::Phone::CountryCode - Country phone dialing prefixes

=head1 SYNOPSIS

 use Number::Phone::CountryCode;

 # retrieve object of United Kingdom codes.
 my $pc = Number::Phone::CountryCode->new('GB');

 print $pc->country;       # ISO 3166 code, e.g: GB
 print $pc->country_code;  # country prefix
 print $pc->idd_prefix;    # IDD prefix
 print $pc->ndd_prefix;    # NDD prefix

 # get list of supported ISO 3166 codes
 my @countries = Number::Phone::CountryCode->countries;

See below for description of the country/IDD/NDD prefixes.

=head1 DESCRIPTION

This module provides an interface to lookup country specific dialing prefixes.
These prefixes are useful when working with phone numbers from different
countries.  The follwing codes are available for each country:

=head2 Country Code

This is the national prefix to be used with dialing B<to> a country B<from>
another country.

=head2 National Direct Dialing Prefix (NDD)

This is the prefix used to make a call B<within a country> from one city to
another.  This prefix may not be necessary when calling another city in the
same vicinity.  This is followed by the city or area code for the place you are
calling.  For example, in the US, the NDD prefix is "1", so you must dial 1
before the area code to place a long distance call within the country.

=head2 International Direct Dialing Prefix (IDD)

This is the prefix needed to make a call B<from a country> to another country.
This is followed by the country code for the country you are calling.  For
example, when calling another country from the US, you must dial 011.

=cut

=head1 CONSTRUCTOR

=over 4

=item new($country)

Constructs a new Number::Phone::CountryCode object.  C<$country> is the two
digit ISO 3166 country code for the country you wish to look up.  Returns
C<undef> if the country code did not match one of the supported countries.

=back

=cut

sub new {
    my ($class, $country) = @_;

    $country = uc $country;

    my $data = $Codes{$country};

    # return nothing if no data for this country code.
    return unless defined $data;

    return $class->SUPER::new({
        country      => $country,
        country_code => $data->[0],
        idd_prefix   => $data->[1],
        ndd_prefix   => $data->[2]
    });
}

=head1 METHODS

The following methods are available

=over 4

=item country

the ISO 3166 country code for this country

=item country_code

The national prefix for this country

=item ndd_prefix

The NDD prefix for this country. Note that this might be undef if no prefix is
necessary.

=item idd_prefix

The IDD prefix for this country.  Note that this might be undef if no prefix is
necessary.

=back

=cut

=head1 CLASS METHODS

The following class methods are available (may be called without constructing
an object).

=over 4

=item countries

Returns a list of all ISO 3166 country codes supported by this module.

=cut

sub countries {
    return sort keys %Codes;
}

=item is_supported($country)

Returns true if the given country is supported, false otherwise.  C<$country>
is a 2 character ISO 3166 country code.

=cut

sub is_supported {
    my ($class, $code) = @_;

    $code = uc $code;

    return defined $Codes{$code} ? 1 : 0;
}

=back

=cut

1;

__END__

=head1 SOURCE

You can contribute to or fork this project via github:

http://github.com/mschout/number-phone-countrycode/tree/master

 git clone git://github.com/mschout/number-phone-countrycode.git

=head1 BUGS / FEEDBACK

Please report any bugs or feature requests to
bug-number-phone-countrycode@rt.cpan.org, or through the web interface at
http://rt.cpan.org

I welcome feedback, and additions/corrections to the country code data
contained within this module.

=head1 AUTHOR

Michael Schout, E<lt>mschout@gkg.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Michael Schout

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.0 or, at your option,
any later version of Perl 5 you may have available.

=cut
