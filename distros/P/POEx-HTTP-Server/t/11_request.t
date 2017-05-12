#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { 
    use_ok('POEx::HTTP::Server::Request');
}

my $resp = POEx::HTTP::Server::Request->new(); 
isa_ok( $resp, 'POEx::HTTP::Server::Request' );
