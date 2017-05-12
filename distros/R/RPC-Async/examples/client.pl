#!/usr/bin/env perl
use strict;
use warnings;

use RPC::Async::Client;
use IO::EventMux;

my $mux = IO::EventMux->new;
my $rpc = RPC::Async::Client->new($mux, "perl://server.pl");
# or # my $rpc = RPC::Async::Client->new($mux, "tcp://127.0.0.1:1234");

$rpc->add_numbers(n1 => 2, n2 => 3,
    sub {
        my %reply = @_;
        print "2 + 3 = $reply{sum}\n";
    });

while ($rpc->has_requests || $rpc->has_coderefs) {
    my $event = $rpc->io($mux->mux) or next;
}

$rpc->disconnect;

