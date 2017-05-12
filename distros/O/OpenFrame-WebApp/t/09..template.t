#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Template
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

use Error qw( :try );
BEGIN { use_ok("OpenFrame::WebApp::Template") };
BEGIN { use_ok("OpenFrame::WebApp::Template::Error"); }
BEGIN { use_ok('Test::Template'); }

ok( keys( %{ OpenFrame::WebApp::Template->types } ), 'default types' );

ok( OpenFrame::WebApp::Template->types->{test}, 'test type registered' );

my $tmpl = new Test::Template;
ok( $tmpl, "new" ) || die( "can't create new object!" );

my $file = './t/templates/test.tt2';
is( $tmpl->file( $file ), $tmpl, "file(set)" );
is( $tmpl->file, $file,          "file(get)" );

is    ( $tmpl->processor( {} ), $tmpl, "processor(set)" );
isa_ok( $tmpl->processor, 'HASH',      "processor(get)" );

is    ( $tmpl->template_vars( {} ), $tmpl, "template_vars(set)" );
isa_ok( $tmpl->template_vars, 'HASH',      "template_vars(get)" );

my $response = $tmpl->process();
isa_ok( $response, 'OpenFrame::Response',  "process" );
like  ( $response->message, qr/processed/, "process_template");


##
## check for errors
##
my $e;
try {
    new Test::Template()
      ->file( './t/templates/non-existent-file' )
      ->process();
} catch OpenFrame::WebApp::Template::Error with {
    $e = shift;
};

if (isa_ok( $e, 'OpenFrame::WebApp::Template::Error', 'error' )) {
    is( $e->flag, eTemplateNotFound, 'error->flag' );
    ok( $e->template,                'error->template file' );
}

