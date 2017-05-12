#!/usr/bin/perl

use strict;
use Test::Simple tests => 92;
use POE qw( Component::Client::TCPMulti Component::Server::TCP );

my $connects = 30;
my $tests    = $connects;

POE::Component::Server::TCP->new
( Alias => "echo_server",
  Port => 11211,
  ClientInput => sub {
    my ($session, $heap, $input) = @_[ SESSION, HEAP, ARG0 ];
    ok 1;
    $heap->{client}->put($input);
  },
  ClientDisconnected => sub {
    my $kernel = $_[KERNEL];
    unless (--$connects) {
        $kernel->post(echo_server => "shutdown");
    }
  },
#  InlineStates => { _start => sub { ok 1 } },
);

POE::Component::Client::TCPMulti->new
( InputEvent    => sub {
    my ($kernel, $cheap, $input) = @_[ KERNEL, CHEAP, ARG0 ];

    ok $cheap->{test} eq $input;

    $kernel->yield(shutdown => $cheap->ID);
    unless (--$tests) {
        $kernel->yield("die");
    }
  },

  SuccessEvent  => sub {
    my ($kernel, $cheap) = @_[ KERNEL, CHEAP ];

    ok 1;

    $cheap->{test} = join "", map chr 33 + rand 90, 1 .. 200;
    $kernel->yield(send => $cheap->ID, $cheap->{test});
  },

  inline_states => {
    _start => sub {
        my ($kernel) = $_[ KERNEL ];
        ok 1;
        $kernel->yield(connect => "127.0.0.1", 11211) for 1 .. $connects;
    },
    _stop => sub {
        ok 1;
    },
  }
);

run POE::Kernel;
