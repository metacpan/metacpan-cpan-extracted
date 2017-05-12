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

if (@$testers != 2){
    plan skip_all => "NEED INPUT: need to add a second remote tester";
    exit;
}

my $d = Test::BrewBuild::Dispatch->new;
my $t = Test::BrewBuild::Tester->new;

$t->start;

my $return = $d->dispatch(
    cmd => 'brewbuild -r -i 5.20.3',
    testers => $testers,
    repo => 'https://stevieb9@github.com/stevieb9/p5-logging-simple',
);

$t->stop;

my @ret = split /\n/, $return;
@ret = grep /\S/, @ret;

print "*$_*\n" for @ret;

is (@ret, 10, "proper ret count");

like ($ret[0], qr/^\d+\.\d+/, "host ok");
like ($ret[1], qr/removing/, "remove ok");
like ($ret[2], qr/installing/, "installing ok");
like ($ret[3], qr/\d\.\d+\.\d+ :: PASS/, "pass 1 ok");
like ($ret[4], qr/\d\.\d+\.\d+ :: PASS/, "pass 2 ok");

like ($ret[5], qr/^\d+\.\d+/, "host ok");
like ($ret[6], qr/removing/, "remove ok");
like ($ret[7], qr/installing/, "installing ok");
like ($ret[8], qr/\d\.\d+\.\d+ :: PASS/, "pass 1 ok");
like ($ret[9], qr/\d\.\d+\.\d+ :: PASS/, "pass 2 ok");

done_testing();

