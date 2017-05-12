#!/usr/bin/perl

use Test::More 'no_plan';
use strict;
use warnings;

use_ok('Parse::IRCLog');

my $result = Parse::IRCLog->parse("t/samples/sample01.log");

isa_ok($result, 'Parse::IRCLog::Result');

ok(my @events = $result->events, "got list of events");

is(@events, 3, "three events parsed");

is_deeply(
  $events[0],
  { type        => 'msg',
    timestamp   => undef,
    nick_prefix => '@',
    nick        => 'rjbs',
    text        => 'I love this channel!'
  },
  "simple msg"
);
