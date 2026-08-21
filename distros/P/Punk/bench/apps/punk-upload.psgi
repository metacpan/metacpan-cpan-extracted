#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";

# What an upload costs, on the route that receives one.
#
# Not a throughput benchmark - the wire dominates, and wrk does not post
# multipart bodies. This exists so the claim has a number attached in the
# repository rather than in a commit message, and so a change that quietly
# reintroduces a copy has somewhere to show up.
#
# Measured end to end through a socket, into a handler that holds the upload:
#
#              worker RSS     before the streaming work
#    16 MiB      13.2 MiB
#    64 MiB       9.2 MiB      137.5 MiB
#   128 MiB      15.5 MiB
#
# Flat. An uploaded file used to be resident FOUR times before a handler saw
# it - Hyperman's read buffer, the SV behind psgi.input, Punk's slurp of the
# body, and the decoded part - and is now resident none of them.
#
# Drive it with:
#
#   curl -F f=@somefile http://127.0.0.1:5000/upload
#
# and watch the worker's RSS rather than the request rate.

package BenchUpload;
use Punk;

upload_dir '/tmp';

post '/upload' => sub {
    my ($c) = @_;
    my $up = $c->req->upload('f');
    return $c->text('no file', 400) unless $up;

    # ->size and ->path never read the bytes; ->content would.
    $c->text(join ' ', $up->size,
                       ($up->path ? 'on-disk' : 'in-memory'),
                       $up->filename);
}, { max_body => 0 };

package main;
BenchUpload->to_app;
