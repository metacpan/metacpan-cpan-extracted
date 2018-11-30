#!/usr/local/bin/perl

use 5.006;
use strict;
use warnings;

my @entries;
my %entry;

while (<>) {
	/^##/ and next;

	m(^//) and do {
		push @entries, {%entry};
		%entry = ();
		next;
	};

	chomp;
	my ( $key, $val ) = split ' ', $_, 2;

	$key or next;
	$entry{$key} = $val;

}

@entries = sort { $a->{GENOME_SIZE} <=> $b->{GENOME_SIZE} } @entries;

for my $entry (@entries) {
	my @vals = map { $entry->{$_} } qw(COMMON_NAME GENOME_SIZE);
	printf "%-40s %12.f\n", @vals;
}

