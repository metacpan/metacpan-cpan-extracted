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
use Test::More;
use Test::Collectd::Plugins;
use Module::Find;

my @module = findsubmod "Collectd::Plugins::NOK";
plan tests => @module * 2;
for (@module) {
	my $module = $_;
	(my $plugin = $module) =~ s/^Collectd::Plugins:://;
	load_ok($module);
	ok (! read_values ($module,$plugin), "plugin $plugin can't read");
}

1;

