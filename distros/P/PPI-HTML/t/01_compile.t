#!/usr/bin/perl -w

# Load testing for PPI::HTML

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 3;




# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Load the modules
use_ok( 'PPI::HTML'           );
use_ok( 'PPI::HTML::Fragment' );

exit();
