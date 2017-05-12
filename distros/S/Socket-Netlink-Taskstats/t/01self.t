#!/usr/bin/perl -w

use strict;

use Test::More tests => 4;

use IO::Socket::Netlink::Taskstats;

my $sock = IO::Socket::Netlink::Taskstats->new;

ok( defined $sock, 'Obtained a Taskstats socket' );

# Get my own stats
my $stats = $sock->get_process_info_by_pid( $$ );

ok( defined $stats && ref $stats eq "HASH", 'get_process_info_by_pid returned a HASH ref' );

# Can't assert in a test what the stats will be like, but we can check a few
# of the other info fields
is( $stats->{ac_uid}, $<,   '$stats->{ac_uid}' );
is( $stats->{ac_gid}, $(+0, '$stats->{ac_gid}' );
