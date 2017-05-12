#!/usr/bin/env perl
use strict;
use local::lib qw(perl5);

use POE;
use POE::Component::Client::Ping ':const';
use NetAddr::IP;

my @IPs = map {
    map { $_->addr }
        @{ NetAddr::IP->new($_) }
} @ARGV;

POE::Component::Client::Ping->spawn( OneReply => 1 );

POE::Session->create(
    inline_states => {
        _start => \&_start,
        pong   => \&_pong,
    }
);

sub _start { POE::Kernel->post( 'pinger', 'ping', 'pong', $_ ) for @IPs; }

sub _pong {
    my ( $request, $response ) = @_[ ARG0, ARG1 ];
    my $ip = sprintf '%-15.15s', $request->[REQ_ADDRESS];

    # The response address is defined if this is a response.
    print defined $response->[RES_ADDRESS] ? "$ip ok\n" : "$ip missing\n";
}

POE::Kernel->run;
