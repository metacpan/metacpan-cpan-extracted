#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::User::SessionLoader
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Pipeline::Segment::Tester;

use OpenFrame::WebApp::User;
use OpenFrame::WebApp::User::Factory;
use OpenFrame::WebApp::Session::Factory;
use OpenFrame::WebApp::Session::MemCache;

my $ufactory = new OpenFrame::WebApp::User::Factory()->type( 'webapp' );
my $sfactory = new OpenFrame::WebApp::Session::Factory()->type( 'mem_cache' );

if (use_ok( "OpenFrame::WebApp::Segment::User::SessionLoader" )) {
    my $seg = new OpenFrame::WebApp::Segment::User::SessionLoader;
    ok( $seg, "new" ) || die( "can't create new object!" );

    my $pt   = new Pipeline::Segment::Tester;
    my $sess = $sfactory->new_session->set( 'user', $ufactory->new_user->id( 'test' ) );
    my $prod = $pt->test( $seg, $ufactory, $sess );

    my $user = $pt->pipe->store->get('OpenFrame::WebApp::User');
    if (ok( $user, 'user found in store' )) {
	is( $user->id, 'test', 'ids match' );
    }
}

