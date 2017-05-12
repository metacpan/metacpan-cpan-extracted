#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Session
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

BEGIN { use_ok("OpenFrame::WebApp::Session") };
BEGIN { use_ok("Test::Session") };

ok( keys( %{ OpenFrame::WebApp::Session->types } ), 'default types' );

ok( OpenFrame::WebApp::Session->types->{test}, 'test type registered' );

my $sess = new Test::Session;
ok( $sess, "new" ) || die( "can't create new object!" );

ok  ( $sess->id, "id(get)" );
isnt( $sess->id, $sess->generate_id, "generate_id" );

is( $sess->expiry("+10 min"), $sess,  "expiry(set)" );
is( $sess->get_expiry_seconds, 10*60, "get_expiry_seconds" );

is( $sess->set( 1,2 ), $sess, "set" );
is( $sess->get( 1 ), 2,       "get" );


