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

my $t = Test::BrewBuild::Tester->new(debug => '7');
my $d = Test::BrewBuild::Dispatch->new;

$t->start;

my $ret = $d->dispatch(
    cmd => 'brewbuild',
    repo => 'https://stevieb9@github.com/stevieb9/test-fail',
    testers => [ qw(127.0.0.1:7800) ],
);
$t->stop;

my @ret = split /\n/, $ret;

ok (@ret > 17, "return has debug logging lines");
like ($ret[8], qr/\d{4}-\d{2}-\d{2}/, "log lines contain a date");

done_testing();
