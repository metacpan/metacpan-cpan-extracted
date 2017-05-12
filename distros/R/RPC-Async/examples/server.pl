#!/usr/bin/env perl -c
use strict;
use warnings;

use RPC::Async::Server;
use IO::EventMux;

my $mux = IO::EventMux->new;
my $rpc = RPC::Async::Server->new($mux);
init_clients($rpc);

while ($rpc->has_clients()) {
    my $event = $rpc->io($mux->mux) or next;
}

sub rpc_add_numbers {
    my ($caller, %args) = @_;
    my $sum = $args{n1} + $args{n2};
    $rpc->return($caller, sum => $sum);
}

1;
