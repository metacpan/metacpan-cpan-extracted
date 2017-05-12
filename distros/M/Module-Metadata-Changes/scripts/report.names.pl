#!/usr/bin/env perl

use feature 'say';
use strict;
use warnings;

use File::chdir; # For magic $CWD.

use Module::Metadata::Changes;

# ------------------------------------------------

my($work) = "$ENV{HOME}/perl.modules";
my($m)    = Module::Metadata::Changes -> new;

opendir(INX, $work) || die "Can't opendir($work)";
my(@name) = sort grep{! /^\.\.?$/} readdir INX;
closedir INX;

my($config);
my($version);

for my $name (@name)
{
	$CWD     = "$work/$name";
	$version = $m -> read -> get_latest_version;
	$config  = $m -> config; # Must call read() before config().

	say $config -> val('Module', 'Name'), " V $version ", $config -> val("V $version", 'Date');
}

