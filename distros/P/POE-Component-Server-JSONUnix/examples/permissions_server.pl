#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;

# Demonstration of the optional user/group permission system.
#
# Run the server:
#   perl -Ilib examples/permissions_server.pl [/path/to/socket]
#
# Then walk through the rules with the companion client:
#   perl -Ilib examples/permissions_client.pl
#
# The policy below is built around whoever starts the server: your user and
# your primary group are woven into the rules, so as a normal user you can
# watch both the allowed and the denied side of the gate from one terminal.
# (Run the client as a different user, or as root, to see the other side.)

use POE;
use POE::Component::Server::JSONUnix;

my $socket_path = $ARGV[0] // '/tmp/jsonunix_perms.sock';

my $run_user = ( getpwuid($>) )[0]
    // die "cannot resolve our own username\n";
my $run_group = getgrgid( ( getpwuid($>) )[3] )
    // die "cannot resolve our own primary group\n";

my $server = POE::Component::Server::JSONUnix->spawn(
    socket_path => $socket_path,
    socket_mode => 0666,    # let other users connect, so you can demo denials

    permissions => {
        # Last-resort policy; everything below is covered by '%DEFAULT%'
        # before this is ever consulted.
        default => 'deny',

        commands => {
            # Fallback rule for every command without an entry of its own:
            # the user who started the server. The built-ins (ping,
            # commands, auth_info-style stuff) and "greet" below land here.
            '%DEFAULT%' => { users => [$run_user] },

            # Anyone may ask, even before authenticating.
            status => 'allow',

            # Group-gated: any member of the server owner's primary group.
            # Secondary (supplementary) memberships count too.
            reload => { groups => [$run_group] },

            # Only root, by name or by uid.
            shutdown_server => { users => [ 'root', 0 ] },

            # A rule the lists cannot express: allowed for anyone
            # authenticated, but only with args.dry_run set.
            danger => {
                check => sub {
                    my ( $server, $ctx, $command ) = @_;
                    return $ctx->request->{args}{dry_run};
                },
            },
        },
    },

    commands => {
        status => sub { return { up => 1, since => $^T } },

        # No rule of its own, so '%DEFAULT%' applies.
        greet => sub {
            my ( $server, $request, $ctx ) = @_;
            return { hello => $ctx->username };
        },

        # Shows what the server knows about the caller, via the context
        # accessors the permission system provides.
        permissions_info => sub {
            my ( $server, $request, $ctx ) = @_;
            return {
                username     => $ctx->username,
                groups       => $ctx->groups,
                in_run_group => $ctx->in_group($run_group) ? 1 : 0,
                # Note: may('danger') evaluates its check coderef against
                # THIS request, which has no dry_run arg -- so it reports 0
                # here even though a dry_run call would be allowed.
                may => {
                    map { $_ => $ctx->may($_) ? 1 : 0 }
                        qw(greet reload shutdown_server danger)
                },
            };
        },

        reload => sub { return { reloaded => 1 } },

        danger => sub { return { would_have => 'rebooted the world' } },

        shutdown_server => sub {
            my ( $server, $request, $ctx ) = @_;
            $ctx->respond_result( { stopping => 1 } );
            $server->shutdown;
            return;
        },
    },
);

# Shut down tidily on Ctrl-C / SIGTERM.
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
warn "policy: %DEFAULT% => $run_user, reload => \@$run_group, shutdown_server => root\n";
warn "try:  perl -Ilib examples/permissions_client.pl\n";

$poe_kernel->run;
exit 0;
