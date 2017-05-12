#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Template::Petal
##

use blib;
use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Petal";
    if ($@) { plan skip_all => 'Petal not installed'; }
    else    { plan no_plan => 1; }
}

use Error qw( :try );

BEGIN { use_ok("OpenFrame::WebApp::Template::Petal"); }
BEGIN { use_ok("OpenFrame::WebApp::Template::Error"); }

ok( OpenFrame::WebApp::Template->types->{petal}, 'petal registered' );

my $tmpl = new OpenFrame::WebApp::Template::Petal;
ok( $tmpl, "new" ) || die( "can't create new object!" );

$tmpl->template_vars( {test => 1} )
     ->file('./t/templates/test.petal');

my $response = $tmpl->process();
isa_ok( $response, 'OpenFrame::Response', "process" );
like  ( $response->message, qr/Petal ok/, "process_template" );

##
## test processing errors
##
my $e;
try {
    my $tmpl2 = new OpenFrame::WebApp::Template::Petal()
      ->file('./t/templates/error.petal')
      ->process();
} catch OpenFrame::WebApp::Template::Error with {
    $e = shift;
};

if (isa_ok( $e, 'OpenFrame::WebApp::Template::Error', 'error' )) {
    is( $e->flag, eTemplateError, 'error->flag' );
    ok( $e->template,             'error->template file' );
    ok( $e->message,              'error->message' );
    print ( "got message:\n", $e->message, "\n" );
}

