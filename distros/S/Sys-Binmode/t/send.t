#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Socket;

use Sys::Binmode;

socket my $ls, AF_INET, SOCK_DGRAM, 0;
setsockopt $ls, SOL_SOCKET, SO_REUSEADDR, 1;
bind $ls, Socket::pack_sockaddr_in( 0, "\0\0\0\0" ) or die "bind: $^E";

my $fulladdr = getsockname $ls;

my ($port, $addr) = Socket::unpack_sockaddr_in($fulladdr);
$addr = Socket::inet_ntoa($addr);
diag sprintf("bound to $addr:$port (%v.02x)", $fulladdr);

socket my $ss, AF_INET, SOCK_DGRAM, 0;

my $destaddr = Socket::pack_sockaddr_in($port, "\x7f\0\0\1");

utf8::upgrade $fulladdr;
my $ok = send $ss, $fulladdr, 0, $destaddr;
my $errs = "$!, $^E";

SKIP: {
    ok( $ok, 'send() succeeded' ) or do {
        diag $errs;
        skip "cannot proceed", 1;
    };

    my $from = recv( $ls, my $buf, 512, 0 );

    alarm 10;
    is($buf, $fulladdr, 'send() sent to the right place');
};

done_testing();

1;
