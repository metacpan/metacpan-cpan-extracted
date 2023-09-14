#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'redefine';

use Test::More;
use Test::Fatal;

use IO::Async::Test;
use IO::Async::Loop;

BEGIN {
    use_ok "Net::Async::HTTP";
    use_ok "Net::Async::Blockchain::Client::RPC";
    use_ok "Net::Async::Blockchain::Client::RPC::ETH";
    use_ok "Net::Async::Blockchain::Client::RPC::BTC";
}

my @peersocks;
local *IO::Async::Handle::connect = sub {
    my $self = shift;

    my ($selfsock, $peersock) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
    $self->set_handle($selfsock);
    push @peersocks, $peersock;

    return Future->new->done($self);
};

my $loop = IO::Async::Loop->new();
testing_loop($loop);

subtest 'timeout' => sub {
    $loop->add(
        my $rpc = Net::Async::Blockchain::Client::RPC::ETH->new(
            endpoint => "http://abcd.com",
            timeout  => 0.1,
        ));

    like(exception { $rpc->accounts->get() }, qr(Timed out), 'Timeout');
};

subtest 'no endpoint' => sub {
    $loop->add(my $rpc = Net::Async::Blockchain::Client::RPC::ETH->new());

    like(exception { $rpc->accounts->get() }, qr(Require either 'uri' or 'request'), 'No endpoint');
};

subtest 'max connections per host' => sub {
    my $max = 5;

    $loop->add(
        my $rpc = Net::Async::Blockchain::Client::RPC::ETH->new(
            endpoint        => 'http://node.example',
            max_connections => $max
        ));

    my @done;
    for (0 .. 10) {
        $rpc->accounts();
    }

    is(scalar @peersocks - 1, $max, "Expected number of connections for max=$max");
};

done_testing;
