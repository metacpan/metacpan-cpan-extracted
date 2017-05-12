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
use Test::Collectd::Config qw( parse );
use Data::Dumper;
use Test::More;
use Module::Find;
use FindBin;

my @found = findsubmod "Collectd::Plugins::OKConfig";
plan tests => @found * 2;

for (@found) {
	diag "Plugin $_";
	my $module = $_;
	(my $modulepath = $module) =~ s/::/\//g;
	(my $plugin = $module) =~ s/^Collectd::Plugins:://;
	my $configfile = "$FindBin::Bin/dat/$modulepath.conf";
	die "Missing configfile: $configfile" unless -f $configfile;
	# parse config to extract injected "values" part of vl_list
	my $config = parse ($configfile);
	my $expected = $config -> {children} -> [0] -> {values};
	# spawn the plugin's read function and extract the "values" part of vl_list
	read_config_ok ($module, $plugin, $configfile);
	my ($val) = read_values ($module, $plugin, $configfile);
	my $got = $val->[0]->{values};
	is_deeply($got, $expected, "data matches");
}

1;

