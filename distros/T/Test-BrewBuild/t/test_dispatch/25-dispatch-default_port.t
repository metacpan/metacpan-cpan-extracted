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

my $t = Test::BrewBuild::Tester->new;
my $d = Test::BrewBuild::Dispatch->new;

$t->start;

my $ret = $d->dispatch(
    cmd => 'brewbuild',
    repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
    testers => [qw(127.0.0.1)],
);

$t->stop;

like ($ret, qr/127.0.0.1/, "dispatch sets the default port if not supplied");

done_testing();
