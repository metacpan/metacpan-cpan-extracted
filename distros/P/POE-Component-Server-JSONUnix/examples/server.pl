#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# A small demonstration server. Run it, then talk to it with examples/client.pl
# (or any tool that can write newline-delimited JSON to a Unix socket).
#
#   perl -Ilib examples/server.pl [/path/to/socket]
#
# Try, from another terminal:
#   perl -Ilib examples/client.pl ping
#   perl -Ilib examples/client.pl add '{"numbers":[1,2,3,4]}'
#   perl -Ilib examples/client.pl slow

use POE;
use POE::Component::Server::JSONUnix;

my $socket_path = $ARGV[0] // '/tmp/jsonunix.sock';

my $server = POE::Component::Server::JSONUnix->spawn(
    socket_path => $socket_path,
    socket_mode => 0600,

    commands => {
        # Synchronous: just return a result.
        add => sub {
            my ( $server, $request, $ctx ) = @_;
            my $sum = 0;
            $sum += $_ for @{ $request->{args}{numbers} // [] };
            return { sum => $sum };
        },

        # Synchronous error: die with a message.
        divide => sub {
            my ( $server, $request, $ctx ) = @_;
            my ( $n, $d ) = @{ $request->{args} }{qw(numerator denominator)};
            die "denominator must be non-zero\n" if !$d;
            return { quotient => $n / $d };
        },

        # Asynchronous: return undef now, answer from a timer later.
        slow => sub {
            my ( $server, $request, $ctx ) = @_;
            $poe_kernel->post( worker => do_slow => $ctx );
            return;    # nothing yet; the worker session will reply
        },
    },
);

# A separate session that services the asynchronous "slow" command.
POE::Session->create(
    inline_states => {
        _start  => sub { $_[KERNEL]->alias_set('worker') },
        do_slow => sub {
            my ( $kernel, $ctx ) = @_[ KERNEL, ARG0 ];
            $kernel->delay_add( finish_slow => 1.0, $ctx );
        },
        finish_slow => sub {
            my $ctx = $_[ARG0];
            $ctx->respond_result( { slept => 1, answer => 42 } );
        },
    },
);

# Register one more command after spawn, just to show it can be done live.
$server->register(
    now => sub {
        my ( $server, $request, $ctx ) = @_;
        return { epoch => time(), iso => scalar localtime() };
    },
);

# Shut down tidily on Ctrl-C.
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->sig( INT  => 'stop' );
            $_[KERNEL]->sig( TERM => 'stop' );
        },
        stop => sub {
            my $kernel = $_[KERNEL];
            $kernel->sig_handled;
            warn "shutting down...\n";
            $server->shutdown;
        },
    },
);

warn "listening on $socket_path  (Ctrl-C to stop)\n";
warn "try:  perl -Ilib examples/client.pl ping\n";

$poe_kernel->run;
exit 0;
