#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Session::Factory
##

use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

BEGIN { use_ok("OpenFrame::WebApp::Session::Factory") };
BEGIN { use_ok("OpenFrame::WebApp::Session::MemCache") };

my $sf = new OpenFrame::WebApp::Session::Factory;
ok( $sf, "new" ) || die( "can't create new object!" );

is( $sf->type( 'mem_cache' ), $sf, "type(set)" );
is( $sf->type, 'mem_cache',        "type(get)" );

my $id   = $sf->new_session()->set(1,2)->store;
my $sess = $sf->fetch_session( $id );

if (isa_ok( $sess, 'OpenFrame::WebApp::Session', "new/fetch" )) {
    is    ( $sess->get( 1 ), 2, "same keys" );
    $sess->remove;
}

