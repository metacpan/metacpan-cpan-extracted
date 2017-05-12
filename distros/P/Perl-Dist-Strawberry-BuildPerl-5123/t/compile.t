use Test::More tests => 2;

BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

    ok(($] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
    use_ok( 'Perl::Dist::Strawberry::BuildPerl::5123' );
    diag( "Testing Perl::Dist::Strawberry::BuildPerl::5123 $Perl::Dist::Strawberry::BuildPerl::5123::VERSION" );
}

