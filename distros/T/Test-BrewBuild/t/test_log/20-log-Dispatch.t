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

my $t = Test::BrewBuild::Tester->new(debug => 7);

$t->start;

my $stdout = capture_stdout {
    my $d = Test::BrewBuild::Dispatch->new(debug => 7);
    $d->dispatch(
        cmd => 'brewbuild',
        repo => 'https://stevieb9@github.com/stevieb9/test-fail',
        testers => [ qw(127.0.0.1:7800) ],
    );
};
$t->stop;

my @ret = split /\n/, $stdout;

ok (@ret > 8, "return has debug logging lines");
like ($ret[7], qr/\d{4}-\d{2}-\d{2}/, "log lines contain a date");

done_testing();
