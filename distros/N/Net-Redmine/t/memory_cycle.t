#!/usr/bin/env perl -w
use strict;
use Test::More;
use Net::Redmine;
require 't/net_redmine_test.pl';

use Test::Memory::Cycle;

my $r = new_net_redmine();

plan tests => 4;

my $t1 = $r->create(
    ticket => {
        subject => __FILE__ . " $$ @{[time]}",
        description => __FILE__ . "$$ @{[time]}"
    }
);

memory_cycle_ok($r);
memory_cycle_ok($t1);

my $t2 = $r->lookup(
    ticket => {
        id => $t1->id
    }
);

memory_cycle_ok($r);
memory_cycle_ok($t2);

$t1->destroy;
