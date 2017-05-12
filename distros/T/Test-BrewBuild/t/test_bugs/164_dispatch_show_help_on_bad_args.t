#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $d = Test::BrewBuild::Dispatch->new;
my $t = Test::BrewBuild::Tester->new;

$t->start;

eval {
    my $ret = $d->dispatch(
    );
};

like 
    $@, 
    qr/bbdispatch -h/, 
    "bbdispatch is clear on what to do if no testers found";

$t->stop;

done_testing();
