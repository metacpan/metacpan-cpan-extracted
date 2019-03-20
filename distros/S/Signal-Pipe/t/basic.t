#! perl

use strict;
use warnings;

use Test::More 0.89;

use POSIX qw/raise SIGUSR1 EAGAIN/;
use Signal::Pipe 'selfpipe';

alarm 5;

my $pipe = selfpipe(SIGUSR1);
is(sysread($pipe, my $buf, 1), undef, 'Read no byte before signal');
is($!+0, EAGAIN, 'Error is EAGAIN');
raise(SIGUSR1);
is(sysread($pipe, $buf, 1), 1, 'Read one byte after signal');
is(length($buf), 1, 'Buffer really is one ');

done_testing;
