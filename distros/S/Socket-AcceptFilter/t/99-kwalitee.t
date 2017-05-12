#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs "../lib";

$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';

my $dist = lib::abs::path('..');
chdir $dist or plan skip_all => "Can't chdir to $dist: $!";
eval { require Test::Kwalitee; Test::Kwalitee->import( basedir => $dist ) }; #, tests => ['-use_strict']
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

END {
	-e 'Debian_CPANTS.txt' and do { unlink 'Debian_CPANTS.txt' or $! and warn $! };
}
