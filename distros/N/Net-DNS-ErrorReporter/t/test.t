#!/usr/bin/env perl
use Test::More;
use common::sense;

my $package = q{Net::DNS::ErrorReporter};

require_ok($package);

my $reporter = $package->new;
isa_ok($reporter, $package);

done_testing;
