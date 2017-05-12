#!/usr/bin/perl

use strict;
use Test::More;
use lib::abs "..","../lib";

my $dist = lib::abs::path('..');
chdir $dist or plan skip_all => "Can't chdir to $dist: $!";
$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
eval { require Test::Fixme;Test::Fixme->import() };
plan( skip_all => 'Test::Fixme not installed; skipping' ) if $@;

#local $TODO = 'Developer release';

run_tests(
	where    => $dist.'/lib',
	match    => qr/\b(?:TODO|FIXME)\b/, # what to check for
	skip_all => $ENV{SKIP},
);
