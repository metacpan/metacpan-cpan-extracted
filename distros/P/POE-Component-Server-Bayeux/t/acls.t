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
    MessageACL => sub {
        my ($client, $message) = @_;

        return unless $message->isa('POE::Component::Server::Bayeux::Message::Meta');
        if ($message->type eq 'subscribe' && $message->subscription =~ m{^/private/}) {
            $message->is_error("Private channel prohibited");
        }
    },
    Debug => $ENV{DEBUG} ? 1 : 0,
);
isa_ok($server, 'POE::Component::Server::Bayeux');

my $client = POE::Component::Client::Bayeux->spawn(
    Host => '127.0.0.1',
    Port => $test_port,
    Alias => 'client',
    ErrorCallback => \&errors,
    Debug => $ENV{DEBUG} ? 1 : 0,
);
isa_ok($client, 'POE::Component::Client::Bayeux');

POE::Session->create(
    inline_states => {
        _start => \&start,
        delay_stop => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];
            $kernel->delay('stop', 1);
        },
        stop => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];

            $kernel->call('client', 'shutdown');
            $kernel->call('server', 'shutdown');
            $kernel->alias_remove('test_session');
            $kernel->stop();
        },
    },
);

$poe_kernel->run();

sub start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_set('test_session');

    $kernel->post('client', 'init');
    $kernel->post('client', 'subscribe', '/private/top/secret', 'new_message');
}

sub errors {
    my ($message) = @_;

    ok(defined $message->{successful} && ! $message->{successful}, "Unsuccessful message");
    is($message->{subscription}, '/private/top/secret', "Subscription failed");

    $poe_kernel->call('client', 'disconnect');
    $poe_kernel->call('test_session', 'delay_stop');
}
