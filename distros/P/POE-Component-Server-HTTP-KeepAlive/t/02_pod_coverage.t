#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 1;
pod_coverage_ok(
        "POE::Component::Server::HTTP::KeepAlive",
        { also_private => [ qw(
    add
    close_event
    conn_ID
    conn_close
    conn_from_resp
    conn_get
    conn_ka
    conn_ka_inc
    conn_on_close
    conn_wheel
    connection
    create_events
    drop
    drop_response
    dump
    enforce
    finish
    get
    get_heap
    keep
    keep_response
    new
    remove
    start
    status_close
    timeout
    timeout_event
)
                ], 
        },
        "POE::Component::Server::HTTP::KeepAlive, ignoring private functions",
);

