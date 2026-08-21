#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";

# What a conditional GET costs, and what it saves.
#
# Deliberately identical to punk-hello.psgi apart from the plugin line and
# the route option, so the difference between them IS the feature. Read it
# against:
#
#   punk-hello   the same app without any of this
#   bare         a hand-rolled PSGI app, the ceiling
#
# THIS APP DELIBERATELY SERVES A FIVE-BYTE BODY, which is the least
# flattering possible case for the body ETag and the most honest one for the
# validator. Change $BODY below to see the other half of the story.
#
# ---- in-process, 1773-byte JSON body, medians of 5 -------------------------
#
#   plain route                        1434 ns
#   etag => 1,   no If-None-Match      5603 ns   +4169
#   etag => 1,   matching INM (304)    5755 ns   +4321
#   etag => sub, no If-None-Match      1981 ns    +547
#   etag => sub, matching INM (304)    1778 ns    +344   handler skipped
#
# The two halves are not the same feature wearing different spellings.
#
# `etag => 1` hashes the response on the way out. It saves the WIRE and the
# client's parse; it costs the server about 440 ns of machinery plus 2 ns a
# byte, and it costs that on a hit as well as a miss - a 304 still had to
# render the page it is not sending. On this five-byte body that is a bad
# trade by any measure. On a 16 KB page it is 35 us against a render that is
# usually milliseconds, and the client stops re-parsing on every poll.
#
# `etag => sub` answers before the handler runs, so the 304 costs less than
# the 200 does - the only place in this framework where adding a feature
# makes a request cheaper. What it costs is one call to the validator on
# every request, so the validator has to be genuinely cheap: a
# max(updated_at) that is an index scan is fine, one that is a table scan
# has moved the work rather than removed it.
#
# The wire saving is what does not show up in req/s: a 304 is headers only.
# Run this against a client that actually revalidates - curl --etag-save /
# --etag-compare, or a browser reloading - rather than against a load
# generator that never sends If-None-Match, or the 304 path is never
# exercised and the numbers only show the cost.

my $BODY = 'hello';

package BenchConditionalGet;
use Punk;

plugin 'ConditionalGet';

# the validator: one string comparison, no I/O - the floor for this half
get '/' => sub { $_[0]->text($BODY) }, { etag => sub { 'v1' } };

# the same response, tagged from its bytes
get '/body' => sub { $_[0]->text($BODY) }, { etag => 1 };

# and untagged, in the same process, so the three are one run apart
get '/plain' => sub { $_[0]->text($BODY) };

package main;
BenchConditionalGet->to_app;
