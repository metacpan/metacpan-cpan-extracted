#!/usr/bin/perl
use strict;
use warnings;

use File::Copy qw(move);

use Test::BrewBuild;
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $workdir = Test::BrewBuild->workdir;

if (-f "$workdir/brewbuild.conf"){
    move "$workdir/brewbuild.conf", "$workdir/brewbuild.conf.temp" or die $!;
    is -f "$workdir/brewbuild.conf", undef, "conf file moved ok";
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

if (-f "$workdir/brewbuild.conf.temp"){
    move "$workdir/brewbuild.conf.temp", "$workdir/brewbuild.conf" or die $!;
    is -f "$workdir/brewbuild.conf", 1, "conf replaced moved ok";
}
done_testing();
