#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Template::TT2
##

use blib;
use strict;
use warnings;

BEGIN {
    eval "use Template";
    if ($@) {
	eval "use Test::More skip_all => 'Template::Toolkit not installed'";
    }
    eval "use Test::More no_plan => 1";
}

use Error qw( :try );

BEGIN { use_ok("OpenFrame::WebApp::Template::TT2"); }
BEGIN { use_ok("OpenFrame::WebApp::Template::Error"); }

ok( OpenFrame::WebApp::Template->types->{tt2}, 'tt2 registered' );

my $tmpl = new OpenFrame::WebApp::Template::TT2;
ok( $tmpl, "new" ) || die( "can't create new object!" );

$tmpl->processor(new Template( RELATIVE => 1 ))
     ->template_vars( {test => 1} )
     ->file('./t/templates/test.tt2');

my $response = $tmpl->process();
isa_ok( $response, 'OpenFrame::Response', "process" );
like  ( $response->message, qr/TT2 ok/,   "process_template" );

##
## test processing errors
##
my $e;
try {
    $tmpl->file('./t/templates/error.tt2')
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

