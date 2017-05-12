my @classes = qw(
		Module::Release
		Module::Release::Kwalitee
		Module::Release::WebUpload::Mojo
		Module::Release::PAUSE
		Module::Release::SVN
		Module::Release::MANIFEST
		);

use Test::More;

foreach my $class ( @classes ) {
	BAIL_OUT( "$class did not compile!" ) unless use_ok( $class );
	}

done_testing();
