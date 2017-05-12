#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib  lib);

use Net::OBEX::Response;

my $connect_raw
= pack 'H*', 'a0001f10001406';
my $raw = pack 'H*', 'a00003';

my $res = Net::OBEX::Response->new;

my $connect_response_ref = $res->parse( $connect_raw, 1 );
my $response_ref = $res->parse( $raw );
