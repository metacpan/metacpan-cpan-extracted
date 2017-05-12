#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Data::Dumper;
use JSON::Any qw(XS);
use lib "$FindBin::Bin/../lib";

use POE qw(Component::Client::Bayeux);

POE::Component::Client::Bayeux->spawn(
    Host => 'localhost',
    Port => $ARGV[0] || '8095',
    Path => '/cometd',
    Alias => 'comet',
    Debug => 1,
);

POE::Session->create(
    inline_states => {
        _start => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];
            $kernel->alias_set('my_client');

            # Allow for startup
            $kernel->yield('init');
        },
        init => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];

            print "Calling comet init\n";

            $kernel->post('comet', 'init');
            $kernel->post('comet', 'subscribe', '/chat/demo', 'events');
            $kernel->post('comet', 'publish', '/chat/demo', {
                user => "POE",
                chat => "POE has joined",
                join => JSON::XS::true,
            });
            $kernel->delay('publish', 5);
        },
        publish => sub {
            my ($kernel, $heap) = @_[KERNEL, HEAP];

            $kernel->post('comet', 'publish', '/chat/demo', {
                user => "POE",
                chat => "wants you to know that it loves you long time",
            });
        },
        events => sub {
            my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0];

            print STDERR "Client got subscribed message:\n" . Dumper($message);
        },
    },
);

$poe_kernel->run();
