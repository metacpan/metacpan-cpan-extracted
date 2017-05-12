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

my $ret = $d->dispatch(
    cmd => 'brewbuild -N',
    repo => 'https://stevieb9@github.com/stevieb9/test-fail',
    testers => [ qw(127.0.0.1:7800) ],
);

$t->stop;

my @ret = split /\n/, $ret;

is (@ret, 2, "bug #81: dispatch return ok and doesn't hang with -N|--notest");
is ($ret[0], '', "blank line");
like ($ret[1], qr/127\.0\.0\.1 - /, "remote tester info");

done_testing();
