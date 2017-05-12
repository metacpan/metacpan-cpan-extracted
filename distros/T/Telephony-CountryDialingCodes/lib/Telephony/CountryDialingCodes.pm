package Telephony::CountryDialingCodes;
# $Id: CountryDialingCodes.pm,v 1.4 2009/11/02 19:46:32 cmanley Exp $
# See POD documentation below.
use strict;
use Carp;
our $VERSION = sprintf('%d.%02d', q|$Revision: 1.4 $| =~ m/ (\d+) \. (\d+) /xg);


# Private global 'constants'.
our %DIALING_ISO3166 = (
	1	=> [qw(AG AI AS BB BM BS CA DM DO GD GU JM LC KN KY MP MS PR TC TT US VC VG VI)],
	20	=> 'EG',
	212	=> [qw(MA EH)],
	213	=> 'DZ',
	216	=> 'TN',
	218	=> 'LY',
	220	=> 'GM',
	221	=> 'SN',
	222	=> 'MR',
	223	=> 'ML',
	224	=> 'GN',
	225	=> 'CI',
	226	=> 'BF',
	227	=> 'NE',
	228	=> 'TG',
	229	=> 'BJ',
	230	=> 'MU',
	231	=> 'LR',
	232	=> 'SL',
	233	=> 'GH',
	234	=> 'NG',
	235	=> 'TD',
	236	=> 'CF',
	237	=> 'CM',
	238	=> 'CV',
	239	=> 'ST',
	240	=> 'GQ',
	241	=> 'GA',
	242	=> 'CG',
	243	=> 'CD',
	244	=> 'AO',
	245	=> 'GW',
	246	=> 'IO',
	247	=> 'AC',
	248	=> 'SC',
	249	=> 'SD',
	250	=> 'RW',
	251	=> 'ET',
	252	=> 'SO',
	253	=> 'DJ',
	254	=> 'KE',
	255	=> 'TZ',
	256	=> 'UG',
	257	=> 'BI',
	258	=> 'MZ',
	260	=> 'ZM',
	261	=> 'MG',
	262	=> 'RE',
	263	=> 'ZW',
	264	=> 'NA',
	265	=> 'MW',
	266	=> 'LS',
	267	=> 'BW',
	268	=> 'SZ',
	269	=> [qw(KM YT)],
	27	=> 'ZA',
	290	=> 'SH',
	291	=> 'ER',
	297	=> 'AW',
	298	=> 'FO',
	299	=> 'GL',
	30	=> 'GR',
	31	=> 'NL',
	32	=> 'BE',
	33	=> 'FR',
	34	=> 'ES',
	350	=> 'GI',
	351	=> 'PT',
	352	=> 'LU',
	353	=> 'IE',
	354	=> 'IS',
	355	=> 'AL',
	356	=> 'MT',
	357	=> 'CY',
	358	=> 'FI',
	359	=> 'BG',
	36	=> 'HU',
	370	=> 'LT',
	371	=> 'LV',
	372	=> 'EE',
	373	=> 'MD',
	374	=> 'AM',
	375	=> 'BY',
	376	=> 'AD',
	377	=> 'MC',
	378	=> 'SM',
	379	=> 'VA',
	380	=> 'UA',
	381	=> 'RS',
	382	=> 'ME',
	385	=> 'HR',
	386	=> 'SI',
	387	=> 'BA',
	388	=> 'EU',
	389	=> 'MK',
	39	=> 'IT',
	40	=> 'RO',
	41	=> 'CH',
	420	=> 'CZ',
	421	=> 'SK',
	423	=> 'LI',
	43	=> 'AT',
	44	=> 'GB',
	45	=> 'DK',
	46	=> 'SE',
	47	=> 'NO',
	48	=> 'PL',
	49	=> 'DE',
	500	=> 'FK',
	501	=> 'BZ',
	502	=> 'GT',
	503	=> 'SV',
	504	=> 'HN',
	505	=> 'NI',
	506	=> 'CR',
	507	=> 'PA',
	508	=> 'PM',
	509	=> 'HT',
	51	=> 'PE',
	52	=> 'MX',
	53	=> 'CU',
	54	=> 'AR',
	55	=> 'BR',
	56	=> 'CL',
	57	=> 'CO',
	58	=> 'VE',
	590	=> 'GP',
	591	=> 'BO',
	592	=> 'GY',
	593	=> 'EC',
	594	=> 'GF',
	595	=> 'PY',
	596	=> 'MQ',
	597	=> 'SR',
	598	=> 'UY',
	599	=> 'AN',
	60	=> 'MY',
	61	=> [qw(AU CC CX)],
	62	=> 'ID',
	63	=> 'PH',
	64	=> 'NZ',
	65	=> 'SG',
	66	=> 'TH',
	670	=> 'TL',
	672	=> [qw(AQ NF)],
	673	=> 'BN',
	674	=> 'NR',
	675	=> 'PG',
	676	=> 'TO',
	677	=> 'SB',
	678	=> 'VU',
	679	=> 'FJ',
	680	=> 'PW',
	681	=> 'WF',
	682	=> 'CK',
	683	=> 'NU',
	685	=> 'WS',
	686	=> 'KI',
	687	=> 'NC',
	688	=> 'TV',
	689	=> 'PF',
	690	=> 'TK',
	691	=> 'FM',
	692	=> 'MH',
	7	=> [qw(RU KZ)],
	800	=> 'XT',
	808	=> 'XS',
	81	=> 'JP',
	82	=> 'KR',
	84	=> 'VN',
	850	=> 'KP',
	852	=> 'HK',
	853	=> 'MO',
	855	=> 'KH',
	856	=> 'LA',
	86	=> 'CN',
	870	=> 'XN',
	871	=> 'XE',
	872	=> 'XF',
	873	=> 'XI',
	874	=> 'XW',
	878	=> 'XP',
	880	=> 'BD',
	881	=> 'XG',
	882	=> 'XV',
	886	=> 'TW',
	90	=> 'TR',
	91	=> 'IN',
	92	=> 'PK',
	93	=> 'AF',
	94	=> 'LK',
	95	=> 'MM',
	960	=> 'MV',
	961	=> 'LB',
	962	=> 'JO',
	963	=> 'SY',
	964	=> 'IQ',
	965	=> 'KW',
	966	=> 'SA',
	967	=> 'YE',
	968	=> 'OM',
	970	=> 'PS',
	971	=> 'AE',
	972	=> 'IL',
	973	=> 'BH',
	974	=> 'QA',
	975	=> 'BT',
	976	=> 'MN',
	977	=> 'NP',
	979	=> 'XR',
	98	=> 'IR',
	991	=> 'XC',
	992	=> 'TJ',
	993	=> 'TM',
	994	=> 'AZ',
	995	=> 'GE',
	996	=> 'KG',
	998	=> 'UZ',
);
our %ISO3166_DIALING = map { my $dc = $_; my $x = $DIALING_ISO3166{$_}; map { $_ => $dc } (ref($x) ? @{$x} : $x); } keys(%DIALING_ISO3166);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self,$class);
	return $self;
}



sub country_codes {
	my $proto = shift;
	my $dc = shift;
	my $cc = $DIALING_ISO3166{$dc};
	if (defined($cc)) {
		return ref($cc) ? @{$cc} : ($cc);
	}
	return ();
}



sub dialing_code {
	my $proto = shift;
	my $cc = uc(shift);
	return $ISO3166_DIALING{$cc};
}



sub extract_dialing_code {
	my $proto = shift;
	my $phn = shift;
	# Chop off leading + or 0's if any.
	$phn =~ s/^[+0]+//;
	foreach my $dialcode (keys %DIALING_ISO3166) {
		if (substr($phn,0,length($dialcode)) eq $dialcode) {
			return $dialcode;
		}
	}
	return undef;
}


1;

__END__

=head1 NAME

Telephony::CountryDialingCodes - convert international dialing codes to country codes and vice versa.

=head1 SYNOPSIS

 # Usage method 1 (using object methods):
 use Telephony::CountryDialingCodes;
 my $o = new Telephony::CountryDialingCodes();
 my $country_code = 'NL';
 print "The dialing access code for country $country_code is " . $o->dialing_code($country_code) . "\n";
 my $dialing_code = 1;
 my @country_codes = $o->country_codes($dialing_code);
 print "The country code(s) for dialing access code $dialing_code is/are: " . join(',',@country_codes) . "\n";


 # Usage method 2 (using class methods):
 use Telephony::CountryDialingCodes;
 my $country_code = 'NL';
 print "The dialing access code for country $country_code is " . Telephony::CountryDialingCodes->dialing_code($country_code) . "\n";
 my $dialing_code = 1;
 my @country_codes = Telephony::CountryDialingCodes->country_codes($dialing_code);
 print "The country code(s) for dialing access code $dialing_code is/are: " . join(',',@country_codes) . "\n";

 # Extracting an int'l dialing code from an int'l phone number:
 use Telephony::CountryDialingCodes;
 my $o = new Telephony::CountryDialingCodes();
 my $dialing_code = $o->extract_dialing_code('+521234567890');
 # $dialing_code will contain 52.

=head1 DESCRIPTION

This class exports a method for determining a country's international dialing
code, and another method for doing the reverse: i.e. determining the
country code(s) that belong(s) to a given international dialing code.

=head1 PUBLIC METHODS

All the methods below can be called in either object or class context.

=head2 new()

The constructor.

=head2 country_codes($)

Returns an array of ISO-3166 alpha2 country codes associated with the given international dialing code.

=head2 dialing_code($)

Returns the international dialing code for the given ISO-3166 alpha2 country code,
or undef if no match is found.

=head2 extract_dialing_code($)

Extracts the international dialing code from the given international telephone number
which can be passed in one of the following formats:

 - with leading +, e.g. '+521234567890'
 - w/o leading +, e.g. '521234567890'
 - with leading zero's, e.g. '00521234567890' (not recommended).

=head1 REFERENCES

=over 4

=item [1]

TheFreeDictionary.com List of country calling codes
I<http://encyclopedia.thefreedictionary.com/list%20of%20country%20calling%20codes>.
2004-11-16

=item [2]

Country / Internet Code / Dialing Code
I<http://www.loglink.com/countrystats.asp?mode=cs17>.
2004-11-18

=item [3]

List of country calling codes
I<http://en.wikipedia.org/wiki/List_of_country_calling_codes>.
2007-02-23

=back

=head1 SEE ALSO

L<Geography::Countries|Geography::Countries> for ISO-3166 alpha2 country codes and names.

L<Locale::Country|Locale::Country> for ISO-3166 alpha2 country codes and names.

L<Number::Phone::Country|Number::Phone::Country> for looking up country codes from telephone numbers.

=head1 COPYRIGHT

Copyright (C) 2004-2009 Craig Manley. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. There is NO warranty; not even for
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

Craig Manley

=cut
