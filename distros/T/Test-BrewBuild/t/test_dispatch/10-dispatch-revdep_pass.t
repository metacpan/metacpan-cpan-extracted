#!/usr/bin/perl
use strict;
use warnings;

use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Git;
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
    cmd => 'brewbuild -r -R',
    repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
    testers => [qw(127.0.0.1:7800)],
);

$t->stop;

my @ret = split /\n/, $ret;
@ret = grep {$_ !~ /^\s*$/} @ret;

print "$_\n" for @ret;

if ($^O =~ /MSWin/){
    is (@ret > 10, 1, "return count is correct");

    like ($ret[0], qr/127\.0\.0\.1 - /, "remote tester info");
    like ($ret[1], qr/removing/, "removing installs");
    like ($ret[2], qr/reverse dependencies:/, "line has has revdep info");

    like ($ret[3], qr/.*?::.*?::.*?/, "Module name");
    like ($ret[4], qr/.*?:: PASS/, "PASS ok");

    like ($ret[5], qr/.*?::.*?::.*?/, "Module name");
    like ($ret[6], qr/.*?:: PASS/, "PASS ok");

    like ($ret[7], qr/.*?::.*?::.*?/, "Module name");
    like ($ret[8], qr/.*?:: PASS/, "PASS ok");
}
else {
    is (@ret > 10, 1, "return count is correct");

    like ($ret[1], qr/removing/, "removing installs");
    like ($ret[2], qr/reverse dependencies:/, "line has has revdep info");

    like ($ret[3], qr/.*?::.*?::.*?/, "Module name");
    like ($ret[4], qr/.*?:: \w+/, "run ok");

    like ($ret[5], qr/.*?::.*?::.*?/, "Module name");
    like ($ret[6], qr/.*?:: \w+/, "run ok");

    like ($ret[7], qr/.*?::.*?(?:::.*?)?/, "Module name");
    like ($ret[8], qr/.*?:: \w+/, "run ok");
}

done_testing();
