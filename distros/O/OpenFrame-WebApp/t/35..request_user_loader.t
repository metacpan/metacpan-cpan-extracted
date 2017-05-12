#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::User::RequestLoader
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use OpenFrame::Request;
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::User"); }
BEGIN { use_ok("OpenFrame::WebApp::User::Factory"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::User::RequestLoader"); }

my $ul_seg = new OpenFrame::WebApp::Segment::User::RequestLoader;
ok( $ul_seg, "new" ) || die( "can't create new object!" );

my $pt       = new Pipeline::Segment::Tester;
my $ufactory = new OpenFrame::WebApp::User::Factory()->type( 'webapp' );
my $request  = new OpenFrame::Request()->arguments({user_id => 'test'});
my $prod     = $pt->test( $ul_seg, $ufactory, $request );

my $user = $pt->pipe->store->get('OpenFrame::WebApp::User');
if (ok( $user, 'user found in store' )) {
    is( $user->id, 'test', 'ids match' );
}

