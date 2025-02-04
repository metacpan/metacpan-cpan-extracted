#! perl

use strict;
use warnings FATAL => 'all';

use Test::More 0.88;
use Signal::Unsafe;
use POSIX qw/raise SIGUSR1/;

my $received;
$Signal::Unsafe{USR1} = sub { $received = [ @_ ] };
raise('USR1');
is(@$received, 3, 'Got 3 arguments');
is($received->[0], SIGUSR1);
isa_ok($received->[1], 'Signal::Info');
is($received->[1]->signo, SIGUSR1);
is($received->[1]->pid, $$);
is($received->[1]->uid, $<);

$Signal::Unsafe::Flags = 0;
$Signal::Unsafe{USR1} = sub { $received = [ @_ ] };
raise('USR1');
is(@$received, 1, 'Got 1 arguments');
is($received->[0], SIGUSR1);

done_testing();
