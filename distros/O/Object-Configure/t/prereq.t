#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Prereq';

# Packages declared inside the test files themselves are not prerequisites
my %local;
for my $file (glob('t/*.t')) {
	open(my $fh, '<', $file) or die "$file: $!";
	while(my $line = <$fh>) {
		$local{$1} = 1 if $line =~ /^\s*package\s+([A-Za-z_][\w:]*)/;
	}
	close $fh;
}

my @skip = (
	sort(keys %local),
	'Object::Configure',	# the distribution itself
	'Test::Memory::Cycle',	# optional; recommended in META, t/function.t skips without it
	qw(base lib strict warnings),	# core pragmas
);

Test::Prereq->import();
prereq_ok(undef, \@skip);
