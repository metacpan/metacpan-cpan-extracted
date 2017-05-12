#!/usr/bin/perl -Tw

use Test::More tests => 8;
use warnings;
use strict;
$^W = 1;

BEGIN { use_ok( 'RayApp::Source' ) }

BEGIN { use_ok( 'RayApp::String' ) }

BEGIN { use_ok( 'RayApp::XML' ) }

BEGIN { use_ok( 'RayApp::DSD' ) }

BEGIN { use_ok( 'RayApp' ) }

my $rayapp = new RayApp;
isa_ok($rayapp, 'RayApp', 'RayApp object');

is($RayApp::VERSION, '2.004', 'Do tests match the version of RayApp?');

use_ok( 'RayApp::CGI' );

1;

