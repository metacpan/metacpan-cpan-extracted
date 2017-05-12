#!/usr/bin/env perl

use strict;
use Test::More tests => 2;

require_ok( 'Net::FreshBooks::API' );
my $error = Net::FreshBooks::API->new;

can_ok( $error, 'die_on_server_error', '_handle_server_error',
    'last_server_error' );

