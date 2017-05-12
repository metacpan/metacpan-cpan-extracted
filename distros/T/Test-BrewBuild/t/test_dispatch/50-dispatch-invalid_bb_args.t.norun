#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $testers = [qw(127.0.0.1)];

my $d = Test::BrewBuild::Dispatch->new;
my $t = Test::BrewBuild::Tester->new;

done_testing();
