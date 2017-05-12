#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 6;
use POE;

BEGIN {
    use_ok('POE::Component::Server::Bayeux');
    use_ok('POE::Component::Client::Bayeux');
}

my $test_port = 60601;

my $server = POE::Component::Server::Bayeux->spawn(
    Port => $test_port,
    Alias => 'server',
    Services => {
        echo => sub {
            my $message = shift;
            return $message->{data};
        },
        math => sub {
            my $message = shift;
            my $payload = $message->{data}{data};

            my $code = sprintf '$answer = %s %s %s', $payload->{a}, $payload->{operand}, $payload->{b};
            my $answer;
            eval "$code";

            return { data => { answer => $answer } };
        },
    },
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

    $heap->{waiting}{'/service/echo'} = 1;
    $kernel->post('client', 'subscribe', '/service/echo', 'new_message');
    $kernel->post('client', 'publish', '/service/echo', {
        message => "I am a walrus",
    });


    $heap->{waiting}{'/service/math'} = 1;
    $kernel->post('client', 'subscribe', '/service/math', 'new_message');
    $kernel->post('client', 'publish', '/service/math', {
        a => 10,
        operand => '*',
        b => 2,
    });
}

sub new_message {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

    if ($message->{channel} eq '/service/echo') {
        is( $message->{data}{message}, 'I am a walrus', "Test service echo" );
    }
    elsif ($message->{channel} eq '/service/math') {
        is( $message->{data}{answer}, 20, "Test service math" );
    }

    $heap->{waiting}{$message->{channel}}--;
    delete $heap->{waiting}{$message->{channel}} if ! $heap->{waiting}{$message->{channel}};
    my @still_waiting = keys %{ $heap->{waiting} };
    return if @still_waiting;

    $kernel->call('client', 'disconnect');
    $kernel->delay('stop', 1);
}
