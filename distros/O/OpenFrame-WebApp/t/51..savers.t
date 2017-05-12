#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::*Save*
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Pipeline::Segment::Tester;

use OpenFrame::WebApp::User;
use OpenFrame::WebApp::Session::MemCache;

## test user savers
if (use_ok("OpenFrame::WebApp::Segment::User::SaveInSession")) {
    my $pt   = new Pipeline::Segment::Tester;
    my $seg  = new OpenFrame::WebApp::Segment::User::SaveInSession;
    my $user = new OpenFrame::WebApp::User;
    my $session = new OpenFrame::WebApp::Session::MemCache;
    $pt->test( $seg, $session, $user );
    ok( $session->get( 'user' ), "user saved" );
}
