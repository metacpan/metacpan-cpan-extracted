#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 2;
ok( $mturk, "Created client");

my $balance = $mturk->getAvailableBalance();
ok($balance =~ /^\d+\.\d+$/, "GetAccountBalance");
