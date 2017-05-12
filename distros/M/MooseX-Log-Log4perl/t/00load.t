use Test::More tests => 2;

BEGIN {
	use_ok( 'MooseX::Log::Log4perl' );
	use_ok( 'MooseX::Log::Log4perl::Easy' );
}

diag( "Testing MooseX::Log::Log4perl $MooseX::Log::Log4perl::VERSION, ::Easy $MooseX::Log::Log4perl::Easy::VERSION" );
