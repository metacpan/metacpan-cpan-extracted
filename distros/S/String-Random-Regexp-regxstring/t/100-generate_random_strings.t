#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.04';

use Test::More;

use String::Random::Regexp::regxstring qw/generate_random_strings/;

my $VERBOSITY = 1;
my $DEBUG = 1;

my $N = 100; # ! wow !

# note, do not test utf8 regex here, there is another test for this

my @testdata = (
	{
	'name' => 'Bulgaria-BG-_standard',
	'regexp-string' => '^(BG)(\d{9,10})',
	},
	{
	'name' => 'Netherlands-NL-_standard',
	'regexp-string' => '^(NL)(\d{9})B\d{2}',
	},
	{
	'name' => 'EU-type-EU-_standard',
	'regexp-string' => '^(EU)(\d{9})',
	},
	{
	'name' => 'Spain-ES-National juridical entities',
	'regexp-string' => '^(ES)([A-Z]\d{8})',
	},
	{
	'name' => 'Spain-ES-Other juridical entities',
	'regexp-string' => '^(ES)([A-HN-SW]\d{7}[A-J])',
	},
	{
	'name' => 'Spain-ES-Personal entities type 1',
	'regexp-string' => '^(ES)([0-9YZ]\d{7}[A-Z])',
	},
	{
	'name' => 'Spain-ES-Personal entities type 2',
	'regexp-string' => '^(ES)([KLMX]\d{7}[A-Z])',
	},
	{
	'name' => 'Greece-EL-_standard',
	'regexp-string' => '^(EL)(\d{9})',
	},
	{
	'name' => 'Slovenia-SI-_standard',
	'regexp-string' => '^(SI)([1-9]\d{7})',
	},
	{
	'name' => 'Czech Republic-CZ-_standard',
	'regexp-string' => '^(CZ)(\d{8,10})(\d{3})?',
	},
	{
	'name' => 'Austria-AT-_standard',
	'regexp-string' => '^(AT)U(\d{8})',
	},
	{
	'name' => 'Slovakia Republic-SK-_standard',
	'regexp-string' => '^(SK)([1-9]\d[2346-9]\d{7})',
	},
	{
	'name' => 'Cyprus-CY-_standard',
	'regexp-string' => '^(CY)([0-59]\d{7}[A-Z])',
	},
	{
	'name' => 'Ireland-IE-1',
	'regexp-string' => '^(IE)(\d{7}[A-W])',
	},
	{
	'name' => 'Ireland-IE-2',
	'regexp-string' => '^(IE)([7-9][A-Z\*\+)]\d{5}[A-W])',
	},
	{
	'name' => 'Ireland-IE-3',
	'regexp-string' => '^(IE)(\d{7}[A-W][AH])',
	},
	{
	'name' => 'Croatia-HR-_standard',
	'regexp-string' => '^(HR)(\d{11})',
	},
	{
	'name' => 'Germany-DE-_standard',
	'regexp-string' => '^(DE)([1-9]\d{8})',
	},
	{
	'name' => 'Finland-FI-_standard',
	'regexp-string' => '^(FI)(\d{8})',
	},
	{
	'name' => 'Norway-NO-_standard',
	'regexp-string' => '^(NO)(\d{9})',
	},
	{
	'name' => 'Belgium-BE-_standard',
	'regexp-string' => '^(BE)(0?\d{9})',
	},
	{
	'name' => 'Serbia-RS-_standard',
	'regexp-string' => '^(RS)(\d{9})',
	},
	{
	'name' => 'Sweden-SE-_standard',
	'regexp-string' => '^(SE)(\d{10}01)',
	},
	{
	'name' => 'Latvia-LV-_standard',
	'regexp-string' => '^(LV)(\d{11})',
	},
	{
	'name' => 'Poland-PL-_standard',
	'regexp-string' => '^(PL)(\d{10})',
	},
	{
	'name' => 'Denmark-DK-_standard',
	'regexp-string' => '^(DK)(\d{8})',
	},
	{
	'name' => 'Italy-IT-_standard',
	'regexp-string' => '^(IT)(\d{11})',
	},
	{
	'name' => 'Malta-MT-_standard',
	'regexp-string' => '^(MT)([1-9]\d{7})',
	},
	{
	'name' => 'UK-GB-Branches',
	'regexp-string' => '^(GB)(\d{12})',
	},
	{
	'name' => 'UK-GB-Government',
	'regexp-string' => '^(GB)(GD\d{3})',
	},
	{
	'name' => 'UK-GB-Health authority',
	'regexp-string' => '^(GB)(HA\d{3})',
	},
	{
	'name' => 'UK-GB-Standard',
	'regexp-string' => '^(GB)(\d{9})',
	},
	{
	'name' => 'Lithunia-LT-_standard',
	'regexp-string' => '^(LT)(\d{9}|\d{12})',
	},
	{
	'name' => 'Luxembourg-LU-_standard',
	'regexp-string' => '^(LU)(\d{8})',
	},
	{
	'name' => 'France-FR-1',
	'regexp-string' => '^(FR)(\d{11})',
	},
	{
	'name' => 'France-FR-2',
	'regexp-string' => '^(FR)([A-HJ-NP-Z]\d{10})',
	},
	{
	'name' => 'France-FR-3',
	'regexp-string' => '^(FR)(\d[A-HJ-NP-Z]\d{9})',
	},
	{
	'name' => 'France-FR-4',
	'regexp-string' => '^(FR)([A-HJ-NP-Z]{2}\d{9})',
	},
	{
	'name' => 'Romania-RO-_standard',
	'regexp-string' => '^(RO)([1-9]\d{1,9})',
	},
	{
	'name' => 'Estonia-EE-_standard',
	'regexp-string' => '^(EE)(10\d{7})',
	},
	{
	'name' => 'Russia-RU-_standard',
	'regexp-string' => '^(RU)(\d{10}|\d{12})',
	},
	{
	'name' => 'Switzerland-CHE-_standard',
	'regexp-string' => '^(CHE)(\d{9})(MWST|TVA|IVA)?',
	},
	{
	'name' => 'Hungary-HU-_standard',
	'regexp-string' => '^(HU)(\d{8})',
	},
	{
	'name' => 'Portugal-PT-_standard',
	'regexp-string' => '^(PT)(\d{9})',
	},
);


# add regexp-object to the above test data
$_->{'regexp-object'} = qr/$_->{'regexp-string'}/ for @testdata;

for my $atest (@testdata){
  for my $I (1..2){
	my $results = generate_random_strings(
		$I==1 ? $atest->{'regexp-string'} : $atest->{'regexp-object'},
		$N,
		$DEBUG
	);
	ok(defined $results, 'generate_random_strings()'." : called and got defined result.") or BAIL_OUT();
	is(ref($results), 'ARRAY', 'generate_random_strings()'." : called and got defined result which is ARRAYref.") or BAIL_OUT("failed, result is of type '".ref($results)."'.");
	is(scalar(@$results), $N, 'generate_random_strings()'." : called and returned array contains $N items as expected.") or BAIL_OUT("failed, it contains ".scalar(@$results)." items.");
	my $undefs = 0;
	for (@$results){ $undefs++ unless defined $_ }
	is($undefs, 0, 'generate_random_strings()'." : called and returned array does not contain any undefined strings.") or BAIL_OUT("failed, return contains $undefs undefined strings.");

	my $empties = 0;
	for (@$results){ $empties++ if $_=~/^\s*$/ }
	is($empties, 0, 'generate_random_strings()'." : called and returned array does not contain any empty strings.") or BAIL_OUT("failed, return contains $empties empty strings.");

	# now let's check the regex, the first part must be present intact
	my $nomatches = 0;
	my ($firstpart) = $atest->{'regexp-string'}=~/^\^\((.+?)\)/;
	if( defined $firstpart ){
		for (@$results){ $nomatches++ unless $_=~/^${firstpart}/ }
		is($nomatches, 0, 'generate_random_strings()'." : called and returned array does not contain any strings without the prefix.") or BAIL_OUT("failed, return contains strings without the first prefix.");
	}
  }
}

done_testing;

1;
