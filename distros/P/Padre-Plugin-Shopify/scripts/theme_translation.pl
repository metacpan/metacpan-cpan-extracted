#!/usr/bin/perl

use strict;
use warnings;

my %replacements = ();
my $regex = undef;
while (my $line = <>) {
	if ($line =~ m/^\s*#\s*%\s*(\w+)\s+(\w+)\s*$/) {
		$replacements{$1} = $2;
	}
	else {
		while(my ($key, $value) = each(%replacements)) {
			$line =~ s/\b$key\b/$value/;
		}
	}
	print $line;
}
