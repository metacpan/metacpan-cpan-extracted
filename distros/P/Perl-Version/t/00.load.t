use Test::More tests => 1;

BEGIN {
  use_ok( 'Perl::Version' );
}

diag( "Testing Perl::Version $Perl::Version::VERSION" );
