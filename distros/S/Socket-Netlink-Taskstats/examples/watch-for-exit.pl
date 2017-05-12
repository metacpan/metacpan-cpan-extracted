#!/usr/bin/perl

use strict;
use warnings;

use Data::Dump qw( pp );

use IO::Socket::Netlink::Taskstats;

my $taskstats = IO::Socket::Netlink::Taskstats->new;

my $mask = '';
# Register 1 CPU
vec( $mask, $_, 1 ) = 1 for 0 .. 0;
$taskstats->register_cpumask( $mask );

while( $taskstats->recv_nlmsg( my $message, 32768 ) ) {
   my $attrs = $message->nlattrs;

   my $pid   = $attrs->{aggr_pid}{pid};
   my $stats = $attrs->{aggr_pid}{stats};

   my $command  = $stats->{ac_comm};
   my $exitcode = $stats->{ac_exitcode};

   print "Process $pid ($command) exited $exitcode\n";
}
