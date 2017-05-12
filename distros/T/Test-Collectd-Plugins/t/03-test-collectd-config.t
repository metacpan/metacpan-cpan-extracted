#!/usr/bin/perl

use strict;
use warnings;
use lib "t/lib";
use Test::Collectd::Config;
use Data::Dumper;
use Test::More;
use File::Find;
use FindBin;

diag "Testing Test::Collectd::Config";

my @found;
sub wanted {
	my $file = $File::Find::name;
	return unless -f $_;
	return unless $file =~ s/\.conf$//;
	if ( -f "$file.dat" ) {
		push @found, $file;
	} else {
		warn "Found $file.conf without $file.dat";
	}
}
find(\&wanted, "$FindBin::Bin/dat/Collectd/Config");

plan tests => @found * 1 + 1;

ok (@found);

for (@found) {
	my $expected = do "$_.dat";
	my $computed = parse("$_.conf");
	is_deeply($computed, $expected, "data matches $_");
}

1;

