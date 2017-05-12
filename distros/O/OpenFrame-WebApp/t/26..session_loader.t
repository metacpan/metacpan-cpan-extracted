#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::Session::Loader
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::Session::Factory"); }
BEGIN { use_ok("OpenFrame::WebApp::Session::MemCache"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::Session::Loader"); }

my $sl_seg = new Test::Session::Loader;
ok( $sl_seg, "new" ) || die( "can't create new object!" );

my $pt       = new Pipeline::Segment::Tester;
my $sfactory = new OpenFrame::WebApp::Session::Factory()->type('mem_cache');
my $prod     = $pt->test( $sl_seg, $sfactory );

my $session  = $pt->pipe->store->get('OpenFrame::WebApp::Session::MemCache');
if (ok( $session, 'session found in store' )) {
    my $session2 = $sfactory->fetch_session( $session->id );
    is( $session2->get( 1 ), 2, 'same keys' );
    $session->remove;
}


package Test::Session::Loader;
use base qw( OpenFrame::WebApp::Segment::Session::Loader );
sub dispatch {
    my $self = shift;
    my ($session, @args) = $self->SUPER::dispatch(@_);
    $session->set( 1,2 );
    return ($session, @args);
}
sub find_session_id {}
