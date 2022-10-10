#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

eval 'require AnyEvent' or do {
    plan skip_all => $@;
};

require Net::HTTP2::Client::AnyEvent;

my $h2 = Net::HTTP2::Client::AnyEvent->new();

my $cv = AnyEvent->condvar();

$h2->request("GET", "https://google.com")->then(
    sub { diag explain shift },
)->finally($cv);

$cv->recv();

ok 1;

done_testing;

1;
