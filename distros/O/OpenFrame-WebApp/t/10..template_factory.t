#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Template::Factory
##

use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

BEGIN { use_ok("OpenFrame::WebApp::Template::Factory") };

my $tf = new OpenFrame::WebApp::Template::Factory;
ok( $tf, "new" ) || die( "can't create new object!" );

is( $tf->directory( './t' ), $tf, "directory(set)" );
is( $tf->directory, './t',        "directory(get)" );

is( $tf->type( 'test' ), $tf, "type(set)" );
is( $tf->type, 'test',        "type(get)" );

is( $tf->processor( 't' ), $tf, "processor(set)" );
is( $tf->processor, 't',        "processor(get)" );

my $tmpl = $tf->new_template( 'test.txt' );
isa_ok( $tmpl, 'Test::Template',      "new_template" );
like  ( $tmpl->file, qr/test\.txt/,   "new_template file" );
isa_ok( $tmpl->template_vars, 'HASH', "new_template vars" );


package Test::Template;
use base qw( OpenFrame::WebApp::Template );
# need a BEGIN or this gets executed last:
BEGIN { OpenFrame::WebApp::Template->types->{test} = __PACKAGE__; }

