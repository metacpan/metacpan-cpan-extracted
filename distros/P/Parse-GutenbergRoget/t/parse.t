#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $thesaurus = "./t/roget15a.txt";

unless (-f $thesaurus) {
	plan skip_all => "roget15a.txt required in ./t to test parsing";
	exit;
}

plan 'no_plan';

use Parse::GutenbergRoget;

my %roget = parse_roget($thesaurus);

ok(%roget, "parsed the thesaurus");

cmp_ok(keys %roget, '==', 1044, "proper number of sections");

cmp_ok(
	$roget{'252a'}{name},
	'eq',
	'Sponge',
	"section 252a is properly named"
);

cmp_ok(
	$roget{'467'}{subsections}[2]{groups}[1]{entries}[0]{text},
	'eq',
	'attestation',
	'correct text for 467.3.2.1'
);
