use Test::More tests => 6;

BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

    ok(($] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
    use_ok( 'Module::Release::CSJEWELL' );
    use_ok( 'Module::Release::PermissionFix' );
    use_ok( 'Module::Release::Twitter' );
    use_ok( 'Module::Release::UploadOwnSite' );
    use_ok( 'Module::Release::OpenRepository' );
    diag( "Testing Module::Release::CSJEWELL $Module::Release::CSJEWELL::VERSION" );
}

