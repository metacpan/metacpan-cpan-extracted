#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::Template::Loader
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use OpenFrame::Request;
use OpenFrame::Response;
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::Template::Error"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::Template::Loader"); }

my $tl_seg = new OpenFrame::WebApp::Segment::Template::Loader;
ok( $tl_seg, "new" ) || die( "can't create new object!" );


## test known types in Simple store
my $pt    = new Pipeline::Segment::Tester;
my $tmpl  = new Test::Template;
my $prod1 = $pt->test( $tl_seg, $tmpl );
like( $prod1, qr/processed/, "dispatch() finds known type in simple stores" );


## test error handling
$pt         = new Pipeline::Segment::Tester;
my $request = new OpenFrame::Request()->uri( 'http://localhost/test.tt2' );
my $tmpl2   = new Test::Template2()->file( './t/templates/test.tt2' );
my $prod3   = $pt->test( $tl_seg, $tmpl2, $request );

if (isa_ok( $prod3, 'OpenFrame::Response', 'error response' )) {
    is  ( $prod3->code, ofERROR,                'error->code' );
    like( $prod3->message, qr/template error/i, 'error->message' );
    print( "template errors will look like this:\n", $prod3->message, "\n" );
}


package Test::Template;
use Pipeline::Production;
use base qw( OpenFrame::WebApp::Template );
# need a BEGIN or this gets executed last:
BEGIN { OpenFrame::WebApp::Template->types->{test} = __PACKAGE__; }
sub process { return new Pipeline::Production()->contents("processed"); }

package Test::Template2;
use OpenFrame::WebApp::Template::Error;
use base qw( OpenFrame::WebApp::Template );
# need a BEGIN or this gets executed last:
BEGIN { OpenFrame::WebApp::Template->types->{test2} = __PACKAGE__; }
sub process {
    my $self = shift;
    throw OpenFrame::WebApp::Template::Error(
					     flag     => eTemplateError,
					     template => $self->file,
					     message  => 'test',
					    );
}

