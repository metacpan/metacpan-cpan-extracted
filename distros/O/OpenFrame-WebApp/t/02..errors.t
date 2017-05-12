#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Error
##

use blib;
use strict;
use warnings;

use Test::More qw( no_plan => 1 );

use Error qw( :try );
BEGIN { use_ok("OpenFrame::WebApp::Error") }

my $error = new OpenFrame::WebApp::Error;

isa_ok( $error, 'OpenFrame::WebApp::Error', 'new' );

is( $error->flag(1), $error, 'flag(set)' );
is( $error->flag, 1,         'flag(get)' );


try {
    throw OpenFrame::WebApp::Error( flag => 'some.error' );
} catch OpenFrame::WebApp::Error with {
    my $e = shift;
    isa_ok( $e, 'OpenFrame::WebApp::Error',  'throw' );
    is    ( $e->flag, 'some.error', 'flag' );
    is    ( "$e", 'some.error',     'stringify' );
    print "printed errors will look like this: $e\n";
}
