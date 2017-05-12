use Test::More 0.98;
eval "use Test::Pod::Coverage";

if( $@ ) {
	plan skip_all => "Test::Pod::Coverage required for testing POD";
	}
else {
	plan tests => 1;

	pod_coverage_ok( "Net::MAC::Vendor" );      
	}
