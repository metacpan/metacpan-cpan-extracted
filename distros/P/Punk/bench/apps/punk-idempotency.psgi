#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
use File::Temp ();

# What recognising a retry costs, and what it saves.
#
# Deliberately the same route three ways, in one process, so the numbers are
# one run apart rather than one deploy apart:
#
#   /plain   no plugin work at all
#   /keyed   idempotent, and the client sends a key
#   /same    idempotent, and every request replays one stored response
#
# ---- in-process, medians of 5, 4000 requests a pass ------------------------
#
#   plain POST                             1880 ns
#   idempotent route, no key sent          1906 ns      +26
#   keyed, replayed (handler skipped)     14211 ns   +12330
#
# TWENTY-SIX NANOSECONDS is the number to notice first. A route that opted in
# but received no key pays a hash fetch and a branch, so marking a route
# idempotent is not a decision that needs defending on cost.
#
# The 12 us is a file-store read plus the key and fingerprint hashes, and it
# is charged against a handler that did nothing. Against a POST that writes a
# row it disappears; against this one it is most of the request. The right
# comparison is not "how much does the plugin cost" but "how much does the
# work cost that a replay does not do" - and for the endpoints anybody makes
# idempotent, that is a database write, an external call, or both.
#
# ---- the window ------------------------------------------------------------
#
# Recording adds about 3 us after the handler returns: the after-dispatch
# chain plus one store write. That gap is the window in which a crash still
# doubles the work, and it is the number the POD quotes. Every after_dispatch
# hook an application adds runs inside it.
#
# ---- how to read this over a socket ----------------------------------------
#
# A load generator that never sends Idempotency-Key exercises only the cost
# and never the saving, and will make this plugin look like pure overhead.
# Drive it with the same key twice per connection, or it is measuring the
# wrong half.

my $dir = File::Temp->newdir(CLEANUP => 1);

package BenchIdempotency;
use Punk;

cache 'file', dir => "$dir";
plugin 'Idempotency' => { scope => sub { $_[0]->env->{HTTP_X_USER} // 'bench' } };

post '/plain' => sub { $_[0]->json({ ok => 1 }) };
post '/keyed' => sub { $_[0]->json({ ok => 1 }) }, { idempotent => 1 };
post '/same'  => sub { $_[0]->json({ ok => 1 }) }, { idempotent => 1 };

package main;
BenchIdempotency->to_app;
