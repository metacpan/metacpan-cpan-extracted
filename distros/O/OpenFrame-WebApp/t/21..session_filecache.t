#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Session::FileCache
##

use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

BEGIN { use_ok("OpenFrame::WebApp::Session::FileCache") };

ok( OpenFrame::WebApp::Session->types->{file_cache}, 'file_cache registered' );

my $sess = new OpenFrame::WebApp::Session::FileCache;
ok( $sess, "new" ) || die( "can't create new object!" );

my $id = $sess->set( 1, 2 )->expiry('10 secs')->store;
ok( $id, 'store' );

my $sess2 = OpenFrame::WebApp::Session::FileCache->fetch( $id );

if (isa_ok( $sess2, 'OpenFrame::WebApp::Session', 'fetch session')) {
    is( $sess2->get( 1 ), 2, 'same keys' );
}

is( $sess->remove, $sess, 'remove' );

