# -*- Mode: Perl; -*-
#----------------------------------------------------------------------
package main;

use Test::More;
eval "use Test::Pod::Coverage";
plan( skip_all => "Test::Pod::Coverage required for testing pod coverage" )	if ($@);

plan( tests => 3 );

pod_coverage_ok( "REST::Resource" );
pod_coverage_ok( "REST::Request" );
pod_coverage_ok( "REST::RequestFast" );
