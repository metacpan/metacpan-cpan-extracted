#!/usr/bin/env perl
#

use strict;
use warnings;
use lib 't/lib';
use My::Test::SignalHandlers;
use Sys::Signals::Block;
use Test::More tests => 11;

my $obj = new_ok 'Sys::Signals::Block', [qw(SIGHUP SIGUSR1)];

ok !$HUP;
ok !$USR1;

# check that signal delivery is working.
kill HUP => $$;
kill USR1 => $$;

cmp_ok $HUP, '==', 1;
cmp_ok $USR1, '==', 1;

# block signals
$obj->block;

kill HUP => $$;
kill USR1 => $$;

sleep 1;

# check that signals were not delivered yet
cmp_ok $HUP, '==', 1;
cmp_ok $USR1, '==', 1;

ok $obj->is_blocked;

$obj->unblock;

ok !$obj->is_blocked;

# check that signals were delivered
cmp_ok $HUP, '==', 2;
cmp_ok $USR1, '==', 2;
