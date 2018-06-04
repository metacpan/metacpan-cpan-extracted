#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use My::Test::SignalHandlers;
use Sys::Signals::Block qw(SIGHUP SIGUSR1);
use Test::More tests => 6;

cmp_ok $HUP, '==', 0;
cmp_ok $USR1, '==', 0;

Sys::Signals::Block->block;

kill HUP => $$;
kill USR1 => $$;

# sleep 1s so that we wait to make sure the signals are blocked.
sleep 1;

ok !$HUP, 'SIGHUP was blocked';
ok !$USR1, 'SIGUSR1 was blocked';

Sys::Signals::Block->unblock;
# signals should be delivered here.

ok $HUP, 'SIGHUP was delivered';
ok $USR1, 'SIGUSR1 was delivered';
