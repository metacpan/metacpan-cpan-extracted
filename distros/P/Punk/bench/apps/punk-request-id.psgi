#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";

# What an id per request costs, on the hot path.
#
# Deliberately identical to punk-hello.psgi apart from one line, so the
# difference between the two IS the plugin: same route, same handler, same
# response. Read it against:
#
#   punk-hello   the same app without the plugin - the only comparison that
#                means anything here
#   bare         a hand-rolled PSGI app, the ceiling
#
# Two numbers, and the gap between them is the point.
#
# In-process dispatch measures the plugin at about +310 ns a request, roughly
# a third of a bare Punk request. Over a socket it nearly disappears. Two
# separate runs, two workers:
#
#                     run A                 run B
#   bare              202112 req/s          201670 req/s
#   punk-hello        203471 (100.7%)       204546 (101.4%)
#   punk-request-id   197369  (97.7%)       202286 (100.3%)
#
# Both runs are shown deliberately. The plugin measures 3% down in one and 1%
# in the other, and the spread BETWEEN runs is about the size of the effect -
# so the honest reading is "somewhere around one to three percent, at the edge
# of what this bench can resolve", not whichever number flatters it. The
# in-process figure is the reliable one; this one says the socket, the parse
# and the write dominate everything the framework does.
#
# A route returning a fixed string is the least forgiving place there is to
# put a plugin. Run punk-db alongside it to see the share on a request that
# does actual work.
#
# The wire cost is the part that does not shrink: 153.48MB against
# punk-hello's 107.44MB over the same run, which is 46 bytes a response -
# "X-Request-Id: " plus 32 hex characters. On a five-byte body the header is
# nine times the body. That is an argument for `header => 0` on an endpoint
# serving tiny responses at volume, and no argument at all anywhere else.
#
# Two thirds of the cost is not the id. Minting is cheap - entropy is drawn
# 256 bytes at a time, sixteen ids per syscall, because getentropy costs per
# CALL rather than per byte. The rest is carrying it: the context and stash
# it lives on, and the two strings pushed onto the response headers on the
# way out. `plugin 'RequestId' => { header => 0 }` mints without sending,
# and measured about 125 ns cheaper - so if you want the split, run this
# app twice with that one option changed.

package BenchRequestId;
use Punk;

plugin 'RequestId';

get '/' => sub { $_[0]->text('hello') };

package main;
BenchRequestId->to_app;
