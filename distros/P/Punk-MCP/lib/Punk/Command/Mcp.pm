package Punk::Command::Mcp;

use 5.010;
use strict;
use warnings;
use Punk::Command ();
use Punk::Plugin::MCP ':command';

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Command::Mcp - the C<punk mcp> command

=head1 SYNOPSIS

    punk mcp                          # the application found from here
    punk mcp --dir /srv/acme --token "$TOKEN"

    claude mcp add acme -- punk mcp --dir /srv/acme

=head1 DESCRIPTION

Serves an application's MCP endpoint over stdin and stdout, for an MCP
client that launches its servers as subprocesses. Newline-delimited
JSON-RPC, one message a line each way, and nothing else on stdout: a
C<print> in a controller goes to stderr, as do logs.

The application is found as every C<punk> command finds one (C<--dir>, or
walking up for F<app.psgi>), and must use C<plugin 'MCP'>, or the command
exits 2 saying so.

=head2 Who may call

The endpoint's C<auth> and C<oauth> guards run on every message, with
C<--token> (or C<PUNK_MCP_TOKEN>) as a C<Bearer> token. C<stdio_trust>, a
plugin option, skips them over stdio: the process was started by whoever
owns it, and nothing on a network reaches this path. C<principal> runs as
it does over HTTP.

=head2 What differs from HTTP

The process is the session: it keeps the negotiated version, the log level
and its resource subscriptions, and a resource update is written as a line
the moment it happens. Only updates made in this process arrive: it is not
part of a running server's worker pool, so a change made through the web
application does not reach it. Messages are handled one at a time, so a C<ping> or
a cancellation sent during a call is answered after it. The application's
request hooks do not run, since a message is dispatched directly rather
than as an HTTP request.

C<--env> sets C<PUNK_ENV> before the application loads.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
