#!perl

use strict;
use warnings;

use Test::More 'no_plan';

my $reaped;
use sigtrap handler => sub {
  $reaped = wait;
} => 'CHLD';

my $class = 'Proc::Daemontools::Service::Test';
use_ok($class);

my $serv = $class->new;

my $file = "test.out";

if (-e $file) {
  unlink $file or die "Can't unlink $file: $!";
}

my $pid = fork;

if (not $pid) {
  $serv->run;
}

sleep 1;
# hup
is(kill(1, $pid), 1, 'hupped 1 pid');
sleep 1;
is($serv->_read, 'hangup', 'child wrote hangup');

# term
is(kill(15, $pid), 1, 'termed 1 pid');
sleep 1;
is($serv->_read, 'exit', 'child wrote exit');

is($reaped, $pid, 'reaped child pid');
