#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::Session
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use Pipeline::Store::ISA;
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::Session"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::Session"); }

my $tl_seg = new Test::Session::Segment;
ok( $tl_seg, "new" ) || die( "can't create new object!" );

## test registered session type in Simple store
my $pt    = new Pipeline::Segment::Tester;
my $prod1 = $pt->test( $tl_seg, new Test::Session );
isa_ok( $prod1, 'Test::Session', "finds known type in simple stores" );

## test unregistered session type in ISA store
$pt->pipe->store( new Pipeline::Store::ISA );

my $prod2 = $pt->test( $tl_seg, new Test::Session2 );
isa_ok( $prod2, 'Test::Session2', "finds unknown type in isa stores" );


package Test::Session;
use Pipeline::Production;
use base qw( OpenFrame::WebApp::Session );
# need a BEGIN or this gets executed last:
BEGIN { OpenFrame::WebApp::Session->types->{test} = __PACKAGE__; }

package Test::Session2;
use base qw( Test::Session );
# unregistered

package Test::Session::Segment;
use base qw( OpenFrame::WebApp::Segment::Session );
sub dispatch { new Pipeline::Production()->contents( shift->get_session_from_store ); }

