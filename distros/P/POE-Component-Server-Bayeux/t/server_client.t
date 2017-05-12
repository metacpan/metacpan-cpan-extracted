#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More qw(no_plan);
use POE;

BEGIN {
    use_ok('POE::Component::Server::Bayeux');
    use_ok('POE::Component::Client::Bayeux');
}

my $test_port = 60601;

my $server = POE::Component::Server::Bayeux->spawn(
    Port => $test_port,
    Alias => 'server',
    Debug => $ENV{DEBUG} ? 1 : 0,
);
isa_ok($server, 'POE::Component::Server::Bayeux');

my $client = POE::Component::Client::Bayeux->spawn(
    Host => '127.0.0.1',
    Port => $test_port,
    Alias => 'client',
    Debug => $ENV{DEBUG} ? 1 : 0,
);
isa_ok($client, 'POE::Component::Client::Bayeux');

POE::Session->create(
    inline_states => {
        _start => \&start,
        new_message => \&new_message,
        stop => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];

            $kernel->call('client', 'shutdown');
            $kernel->call('server', 'shutdown');
            $kernel->alias_remove('test_session');
            $kernel->stop();
        },
    },
    ($ENV{POE_DEBUG} ? (
    options => { trace => 1, debug => 1 },
    ) : ()),
);

$poe_kernel->run();

sub start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_set('test_session');

    $kernel->post('client', 'init');
    $kernel->post('client', 'subscribe', '/test/*', 'new_message');
    $kernel->post('client', 'publish', '/test/channel', {
        message => "I am a walrus",
    });
}

sub new_message {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

    is( $message->{data}{message}, 'I am a walrus', "Test message received" );

    $kernel->call('client', 'disconnect');
    $kernel->delay('stop', 1);
}
