#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

plan tests => 1 + 1;

use Net::WebSocket::Constants ();

is(
    Net::WebSocket::Constants::status_code_to_name(
        Net::WebSocket::Constants::STATUS()->{'SERVER_ERROR'},
    ),
    'INTERNAL_ERROR',
    'SERVER_ERROR’s code round-trips to INTERNAL_ERROR',
);
