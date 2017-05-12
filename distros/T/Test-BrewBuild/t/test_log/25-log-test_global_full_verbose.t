#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_merged);
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Git;
use Test::BrewBuild::Tester;

use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}

my $ret;

my $stdout = capture_merged {
    my $t = Test::BrewBuild::Tester->new(debug => 7);
    my $d = Test::BrewBuild::Dispatch->new(debug => 7);

    $t->start;

    $ret = $d->dispatch(
        cmd     => 'brewbuild -r -d 7',
        repo    => 'https://stevieb9@github.com/stevieb9/mock-sub',
        testers => [ qw(127.0.0.1:7800) ],
    );

    $t->stop;
};

$ret .= $stdout;

like ($ret, qr/Dispatch\.new/, "dispatch new() represented");
like ($ret, qr/Dispatch\.dispatch/, "dispatch dispatch() represented");
like ($ret, qr/BrewBuild\]/, "BB rep");
like ($ret, qr/BrewBuild\.BrewCommands\.new/, "BBCMD rep");
like ($ret, qr/BrewBuild\.BrewCommands\.brew/, "BBCMD brew rep");
like ($ret, qr/Tester\.new/, "Tester new() rep");
like ($ret, qr/Tester\.listen/, "Tester listen() rep");
like ($ret, qr/Dispatch\.dispatch/, "Dispatch rep");

done_testing();

