# $Id: 24_pod_cover.t 668 2006-10-02 16:09:19Z tinita $

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 3;
pod_coverage_ok( "Parse::BBCode", "Parse::BBCode is covered");
pod_coverage_ok( "Parse::BBCode::Tag", "Parse::BBCode::Tag is covered");
pod_coverage_ok( "Parse::BBCode::HTML", "Parse::BBCode::HTML is covered");

