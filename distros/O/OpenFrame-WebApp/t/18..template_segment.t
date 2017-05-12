#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::Template
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use Pipeline::Store::ISA;
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::Template"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::Template"); }

my $tl_seg = new Test::Template::Segment;
ok( $tl_seg, "new" ) || die( "can't create new object!" );

## test registered template type in Simple store
my $pt    = new Pipeline::Segment::Tester;
my $prod1 = $pt->test( $tl_seg, new Test::Template );
isa_ok( $prod1, 'Test::Template', "finds known type in simple stores" );

## test unregistered template type in ISA store
$pt->pipe->store( new Pipeline::Store::ISA );

my $prod2 = $pt->test( $tl_seg, new Test::Template2 );
isa_ok( $prod2, 'Test::Template2', "finds unknown type in isa stores" );


package Test::Template;
use Pipeline::Production;
use base qw( OpenFrame::WebApp::Template );
# need a BEGIN or this gets executed last:
BEGIN { OpenFrame::WebApp::Template->types->{test} = __PACKAGE__; }

package Test::Template2;
use base qw( Test::Template );
# unregistered

package Test::Template::Segment;
use base qw( OpenFrame::WebApp::Segment::Template );
sub dispatch { new Pipeline::Production()->contents( shift->get_template_from_store ); }

