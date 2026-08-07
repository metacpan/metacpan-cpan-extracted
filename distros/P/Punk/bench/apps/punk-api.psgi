#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";

# The same spec + handler as oa-plack.psgi through Punk's api mount:
# $api->match (C), guard walk, $api->validate_request (C), controller,
# auto-JSON - the pure-Perl pipeline phase 6 moves into C.

my $spec = {
    openapi => '3.1.0',
    info    => { title => 'Bench', version => '1' },
    paths   => { '/' => { get => {
        operationId => 'hello',
        parameters  => [ {
            name => 'limit', in => 'query',
            schema => { type => 'integer', minimum => 1, maximum => 100 },
        } ],
        responses => { 200 => { description => 'ok' } },
    } } },
};

package BenchApi;
use Punk;

api $spec => { handlers => { hello => sub { { hello => 'world' } } } };

package main;
BenchApi->to_app;
