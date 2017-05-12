#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::User
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use Pipeline::Store::ISA;
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::User"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::User"); }

my $tl_seg = new Test::User::Segment;
ok( $tl_seg, "new" ) || die( "can't create new object!" );

## test registered user type in Simple store
my $pt    = new Pipeline::Segment::Tester;
my $prod1 = $pt->test( $tl_seg, new Test::User );
isa_ok( $prod1, 'Test::User', "finds known type in simple stores" );

## test unregistered user type in ISA store
$pt->pipe->store( new Pipeline::Store::ISA );

my $prod2 = $pt->test( $tl_seg, new Test::User2 );
isa_ok( $prod2, 'Test::User2', "finds unknown type in isa stores" );


package Test::User;
use Pipeline::Production;
use base qw( OpenFrame::WebApp::User );
# need a BEGIN or this gets executed last:
BEGIN { OpenFrame::WebApp::User->types->{test} = __PACKAGE__; }

package Test::User2;
use base qw( Test::User );
# unregistered

package Test::User::Segment;
use base qw( OpenFrame::WebApp::Segment::User );
sub dispatch { new Pipeline::Production()->contents( shift->get_user_from_store ); }

