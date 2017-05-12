#!/usr/bin/perl
use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Test::BrewBuild::Dispatch;
use Test::BrewBuild::Tester;
use Test::More;

if (! $ENV{BBDEV_TESTING}){
    plan skip_all => "developer tests only";
    exit;
}
my $t = Test::BrewBuild::Tester->new;
$t->start;

my $d = Test::BrewBuild::Dispatch->new;

my $stdout = capture_stdout {
    $d->dispatch(
        cmd => 'asdf',
        repo => 'https://stevieb9@github.com/stevieb9/mock-sub',
        testers => [ qw(127.0.0.1:7800) ],
    );
};

$t->stop;

like ($stdout, qr/error: only 'brewbuild'/, "bad command dies");

done_testing();
