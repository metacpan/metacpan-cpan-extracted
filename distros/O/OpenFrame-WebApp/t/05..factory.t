#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Factory
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Error qw( :try );
use Test::More qw( no_plan => 1 );

BEGIN { use_ok("OpenFrame::WebApp::Factory") };

my $factory = new OpenFrame::WebApp::Factory;
ok( $factory, "new" ) || die( "can't create new object!" );

{
    my $e;
    try { $e = $factory->get_types_class; }
    catch Error with { $e = shift; };
    isa_ok( $e, 'OpenFrame::WebApp::Error::Abstract', 'get_types_class' )
      or diag( $e );
}

my $CLASS;
{
    no warnings;
    eval "
	sub OpenFrame::WebApp::Factory::get_types_class {
	    my \$self = shift;
	    return \$CLASS;
	}
    ";
}

is( $factory->type( 'test' ), $factory, "type(set)" );
is( $factory->type, 'test',        "type(get)" );

{
    my $e;
    $CLASS = 'Test::NonExistentClass';
    try { $factory->load_types_class; }
    catch Error with { $e = shift; };
    isa_ok( $e, 'OpenFrame::WebApp::Error::LoadClass', 'load_types_class error' )
      or diag( $e );
}

$CLASS = 'Test::Template';
is( $factory->load_types_class, $CLASS, 'load_types_class' );

my $tmpl = $factory->new_object( 'test.txt' );
isa_ok( $tmpl, 'Test::Template',      "new_template" );

