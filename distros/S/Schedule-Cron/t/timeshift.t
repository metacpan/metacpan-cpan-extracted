#!/usr/bin/perl

use Test::More tests => 1;
use Schedule::Cron;
use strict;

my $count = 0;
my $second = (localtime)[0];
my $cron = new Schedule::Cron(sub {},{nofork => 1,timeshift => 10});

$cron->add_entry("* * * * * " . ($second + 12) % 60,{subroutine => sub { die } });
my $now = time;
eval {
    $cron->run();
};
my $delta = time - $now;
ok($delta <= 3,"Call was shifted by " . $delta . " seconds (<= 3)");
