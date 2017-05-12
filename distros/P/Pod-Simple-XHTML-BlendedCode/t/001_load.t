use Test::More 0.61 tests => 3;

BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

    ok(($] > 5.008001), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
    use_ok( 'Pod::Simple::XHTML::BlendedCode' );
    use_ok( 'Pod::Simple::XHTML::BlendedCode::Blender' );
    diag( "Testing Pod::Simple::XHTML::BlendedCode $Pod::Simple::XHTML::BlendedCode::VERSION" );
}

