#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.04';

use utf8; # allow for utf8 in code (we have regex strings in utf8)

use Test::More;
use Test2::Plugin::UTF8;

use String::Random::Regexp::regxstring qw/generate_random_strings/;

my $VERBOSITY = 1;
my $DEBUG = 1;

my $N = 100; # ! wow !

my @testdata = (
	{
	'name' => 'Bulgaria-BG-_standard',
	'regexp-string' => '^(ΒΟΥΛΓΑΡΙΑ)(\d{9,10})',
	},
	{
	'name' => 'Netherlands-NL-_standard',
	'regexp-string' => '^(ΟΛΛΑΝΔΙΑ)(\d{9})B\d{2}',
	},
	{
	'name' => 'EU-type-EU-_standard',
	'regexp-string' => '^(ΤΣΙΡΚΟ)(\d{9})',
	},
	{
	'name' => 'Spain-ES-National juridical entities',
	'regexp-string' => '^(ΙΣΠΑΝΙΑ)([A-Z]\d{8})',
	},
	{
	'name' => 'Spain-ES-Other juridical entities',
	'regexp-string' => '^(ΙΣΠΑΝΙΑ)([A-HN-SW]\d{7}[A-J])',
	},
	{
	'name' => 'Spain-ES-Personal entities type 1',
	'regexp-string' => '^(ΙΣΠΑΝΙΑ)([0-9YZ]\d{7}[A-Z])',
	},
	{
	'name' => 'Spain-ES-Personal entities type 2',
	'regexp-string' => '^(ΙΣΠΑΝΙΑ)([KLMX]\d{7}[A-Z])',
	},
	{
	'name' => 'Greece-EL-_standard',
	'regexp-string' => '^(ΕΛΛΑΔΑ)(\d{9})',
	},
	{
	'name' => 'Slovenia-SI-_standard',
	'regexp-string' => '^(ΣΛΟΒΕΝΙΑ)([1-9]\d{7})',
	},
	{
	'name' => 'Czech Republic-CZ-_standard',
	'regexp-string' => '^(ΤΣΕΧΙΑ)(\d{8,10})(\d{3})?',
	},
	{
	'name' => 'Austria-AT-_standard',
	'regexp-string' => '^(ΑΥΣΤΡΙΑ)U(\d{8})',
	},
	{
	'name' => 'Slovakia Republic-SK-_standard',
	'regexp-string' => '^(ΣΛΟΒΑΚΙΑ)([1-9]\d[2346-9]\d{7})',
	},
	{
	'name' => 'Cyprus-CY-_standard',
	'regexp-string' => '^(ΚΥΠΡΟΣ)([0-59]\d{7}[A-Z])',
	},
	{
	'name' => 'Ireland-IE-1',
	'regexp-string' => '^(ΙΡΛΑΝΔΙΑ)(\d{7}[A-W])',
	},
	{
	'name' => 'Ireland-IE-2',
	'regexp-string' => '^(ΙΡΛΑΝΔΙΑ)([7-9][A-Z\*\+)]\d{5}[A-W])',
	},
	{
	'name' => 'Ireland-IE-3',
	'regexp-string' => '^(ΙΡΛΑΝΔΙΑ)(\d{7}[A-W][AH])',
	},
	{
	'name' => 'Croatia-HR-_standard',
	'regexp-string' => '^(ΚΡΟΑΤΙΑ)(\d{11})',
	},
	{
	'name' => 'Germany-DE-_standard',
	'regexp-string' => '^(ΓΕΡΜΑΝΙΑ)([1-9]\d{8})',
	},
	{
	'name' => 'Finland-FI-_standard',
	'regexp-string' => '^(ΦΙΛΛΑΝΔΙΑ)(\d{8})',
	},
	{
	'name' => 'Norway-NO-_standard',
	'regexp-string' => '^(ΝΟΡΒΗΓΙΑ)(\d{9})',
	},
	{
	'name' => 'Belgium-BE-_standard',
	'regexp-string' => '^(ΒΕΛΓΙΟ)(0?\d{9})',
	},
	{
	'name' => 'Serbia-RS-_standard',
	'regexp-string' => '^(ΣΕΡΒΙΑ)(\d{9})',
	},
	{
	'name' => 'Sweden-SE-_standard',
	'regexp-string' => '^(ΣΟΥΗΔΙΑ)(\d{10}01)',
	},
	{
	'name' => 'Latvia-LV-_standard',
	'regexp-string' => '^(ΛΑΤΒΙΑ)(\d{11})',
	},
	{
	'name' => 'Poland-PL-_standard',
	'regexp-string' => '^(ΠΟΛΩΝΙΑ)(\d{10})',
	},
	{
	'name' => 'Denmark-DK-_standard',
	'regexp-string' => '^(ΔΑΝΙΑ)(\d{8})',
	},
	{
	'name' => 'Italy-IT-_standard',
	'regexp-string' => '^(ΙΤΑΛΙΑ)(\d{11})',
	},
	{
	'name' => 'Malta-MT-_standard',
	'regexp-string' => '^(ΜΑΛΤΑ)([1-9]\d{7})',
	},
	{
	'name' => 'UK-GB-Branches',
	'regexp-string' => '^(ΗΒ)(\d{12})',
	},
	{
	'name' => 'UK-GB-Government',
	'regexp-string' => '^(ΗΒ)(GD\d{3})',
	},
	{
	'name' => 'UK-GB-Health authority',
	'regexp-string' => '^(ΗΒ)(HA\d{3})',
	},
	{
	'name' => 'UK-GB-Standard',
	'regexp-string' => '^(ΗΒ)(\d{9})',
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
		is($nomatches, 0, 'generate_random_strings()'." : called and returned array does not contain any strings without the prefix in unicode.") or BAIL_OUT("failed, return contains strings without the first prefix which is unicode.");
	} else { die "x=$_ and ".$atest->{'regexp-string'}; }
  }
}

done_testing;

1;
