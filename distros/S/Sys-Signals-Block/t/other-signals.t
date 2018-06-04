#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use My::Test::SignalHandlers;
use POSIX ();
use Sys::Signals::Block;
use Test::More tests => 7;

my $sigs = new_ok 'Sys::Signals::Block', [qw(HUP USR1)];

my $sigset = $sigs->sigset;
ok $sigset->ismember(POSIX::SIGHUP());
ok $sigset->ismember(POSIX::SIGUSR1());
ok !$sigset->ismember(POSIX::SIGUSR2());

my $USR2 = 0;
$SIG{USR2} = sub { $USR2++ };

$sigs->block;

kill HUP => $$;
kill USR2 => $$;

cmp_ok $HUP, '==', 0, 'SIGHUP was blocked';
cmp_ok $USR2, '==', 1, 'SIGUSR2 was delivered';

$sigs->unblock;

cmp_ok $HUP, '==', 1, 'SIGHUP was delivered';
