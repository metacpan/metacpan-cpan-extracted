#!perl

# 01_network.t - Test if remote network is reachable.

use strict;
use Test::More tests => 5;
use IO::Socket;

alarm(30);
$SIG{ALRM} = sub { die "Network is broken" };
my $sock;
ok(($sock = IO::Socket::INET->new(82.46.99.88.":1")),"tcpmux connect");
ok(scalar(<$sock>),"tcpmux read");
ok(($sock = IO::Socket::INET->new(82.46.99.88.":80")),"http connect");
ok($sock->print("GET /\n"),"http write");
ok(<$sock>!~/^HTTP/,"http HTTP/0.9 protocol network support");
alarm(0);
