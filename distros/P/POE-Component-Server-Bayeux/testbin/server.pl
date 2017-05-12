#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Data::Dumper;
use lib "$FindBin::Bin/../lib";

use POE qw(Component::Server::Bayeux);

my $server = POE::Component::Server::Bayeux->spawn(
    Port => '8095',
    Alias => 'bayeux_server',
    Debug => 1,
    LogFile => $FindBin::Bin.'/../bayeux.log',
    DocumentRoot => $FindBin::Bin . '/../htdocs',
    Services => {
        echo => sub {
            my ($message) = @_;

            # Echo the payload back to the client
            return $message->{data};
        },
    },
    MessageACL => sub {
        my ($client, $message) = @_;

        if ($message->isa('POE::Component::Server::Bayeux::Message::Meta')) {
            if ($message->type eq 'handshake') {
                #$message->is_error("Client ".$self->ip." is not permitted to handshake on this server");
            }
            elsif ($message->type eq 'subscribe') {
                my $denied = 0;
                while (1) {
                    # Don't restrict locally connected clients
                    last if $client->session;
                    last if $message->subscription eq '/private/' . $client->id;
                    $denied = 1 if $message->subscription =~ m{^/private/};
                    last;
                }
                $message->is_error("Permission denied") if $denied;
            }
        }
    },

    # For basic HTTP server
    TypeExpires => {
        # Cache images for one hour
        'image/png'  => 1 * 60 * 60,
        'image/jpeg' => 1 * 60 * 60,
        'image/gif'  => 1 * 60 * 60,

        # Cache CSS and JS for 2 hours
        'text/css'               => 2 * 60 * 60,
        'application/javascript' => 2 * 60 * 60,
    },
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];
            $kernel->alias_set('test_local_client');
            $kernel->post('bayeux_server', 'subscribe', {
                channel => '/chat/demo',
                client_id => $heap->{client_id},
                args => {
                    state => 'subscribe_response',
                },
            });
        },
        subscribe_response => sub {
            my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

            $server->logger->debug("Local client received:\n". Dumper($message));

            # Don't auto-reply to my own messages
            return if $message->{clientId} eq $heap->{client_id};

            $kernel->post('bayeux_server', 'publish', {
                channel => $message->{channel},
                client_id => $heap->{client_id},
                data => {
                    user => 'Jerkbot',
                    chat => "I got your message, ".($message->{data}{user} || 'anon'),
                },
            });
        },
    },
    heap => {
        client_id => 'ewaters@xmission.com/test_local_client',
    },
);

$poe_kernel->run();
