#!/usr/bin/perl

use t::lib::Test;
use IO::Socket::INET;
use JSON::XS;

my $listen_address = 'localhost:23456';
my $fake_dbg = IO::Socket::INET->new(
    LocalAddr => $listen_address,
    ReusePort => 1,
    Listen    => 5,
);
die "Unable to set up debugger socket: $!" unless $fake_dbg;

run_app('t/apps/base.psgi');
send_request('/?name=debugger');

{
    my $remote = $fake_dbg->accept;

    my $json_text = $remote->getline;
    my $data = JSON::XS->new->allow_nonref->decode($json_text);

    is($data->{event}, "READY", "debugger handshake sanity check");
    sleep 1;

    $remote->close;
}

response_is('Hello, debugger');

done_testing();
