#!/usr/bin/perl

BEGIN {
	# this ensures the shipped but not yet installed typesdb module param is being used
	use Test::File::ShareDir
		-share => {
			-module => { 'Test::Collectd::Plugins' => 'share/Test-Collectd-Plugins' },
	};
}

use strict;
use warnings;
use lib "t/lib";
use Test::Collectd::Plugins;
use Data::Dumper;
use Test::More;
use Module::Find;
use FindBin;

my @found = findsubmod "Collectd::Plugins::OK";
plan tests => @found * 3;

for (@found) {
	diag "Plugin $_";
	my $module = $_;
	(my $modulepath = $module) =~ s/::/\//g;
	(my $plugin = $module) =~ s/^Collectd::Plugins:://;

	load_ok ($module,"Module $module");
	read_ok ($module, $plugin, "Plugin $plugin");
	my @val = read_values ($module, $plugin);
	my $expected = do "$FindBin::Bin/dat/$modulepath.dat";
	is_deeply(\@val, $expected, "data matches");
}

1;

