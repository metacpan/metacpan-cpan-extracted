use Test::More;
eval "use Test::Pod::Coverage";

if( $@ ) {
	plan skip_all => "Test::Pod::Coverage required for testing POD";
	}
else {
	my @modules = qw(
		Test::Data
		Test::Data::Array
		Test::Data::Function
		Test::Data::Hash
		Test::Data::Scalar
		);

	plan tests => scalar @modules;

	pod_coverage_ok( $_, { trustme => [ qr/VERSION/ ] } )
		foreach ( @modules );
	}
