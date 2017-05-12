#!/usr/bin/perl

use strict;
use Test::Simple tests => 2;

BEGIN {
    $ENV{LOG_CHANNEL_CONFIG} = "t/logging.xml";
}

use Spread::Queue::FIFO;
use Time::HiRes qw( sleep );

my $q = new Spread::Queue::FIFO ("test");

$q->enqueue("foo");
sleep 0.1;

my ($data, $duration) = $q->dequeue;

ok($data eq "foo");
ok(abs($duration - 0.1) < 0.05);
