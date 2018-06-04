#!/usr/bin/env perl

use strict;
use warnings;
use POSIX ();
use Test::Exception;
use Test::More tests => 10;

use_ok 'Sys::Signals::Block' or exit 1;

my $instance = Sys::Signals::Block->instance;

lives_ok {
    $instance->import(qw(INT TERM));
} 'named signals';

my $sigset = $instance->sigset;

ok $sigset->ismember(POSIX::SIGINT());
ok $sigset->ismember(POSIX::SIGTERM());

lives_ok {
    $instance->import(qw(SIGINT SIGTERM));
} 'SIG named signals';

$sigset = $instance->sigset;
ok $sigset->ismember(POSIX::SIGINT());
ok $sigset->ismember(POSIX::SIGTERM());

lives_ok {
    $instance->import(POSIX::SIGINT(), POSIX::SIGTERM());
} 'numeric signals';

$sigset = $instance->sigset;
ok $sigset->ismember(POSIX::SIGINT());
ok $sigset->ismember(POSIX::SIGTERM());
