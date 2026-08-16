#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
# BENCH-PATH: /books?page=3&per_page=20

# The validate route option on the hot path: per request the C guard
# (punk_validate.h) fetches the merged params, runs the boot-compiled
# schema through the JSON::Schema::Fast ABI, stashes the Result, and the
# handler reads the typed values back. Compare against punk-dyn for what
# the guard costs over a bare dynamic route.
package BenchValidate;
use Punk;

get '/books' => sub {
    my ($c) = @_;
    my $p = $c->validate->valid;
    { page => $p->{page}, per_page => $p->{per_page} // 20 };
}, {
    validate => {
        type       => 'object',
        required   => ['page'],
        properties => {
            page     => { type => 'integer', minimum => 1 },
            per_page => { type => 'integer', minimum => 1, maximum => 100 },
        },
    },
};

package main;
BenchValidate->to_app;
