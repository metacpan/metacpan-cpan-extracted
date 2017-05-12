#!/usr/bin/perl

# Compile-testing for PITA

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 26;
use Test::Script;

BEGIN {
	ok( $] > 5.006, 'Perl version is 5.006 or newer' );

	# Only three use statements should be enough
	# to load all of the classes (for now).
	use_ok( 'PITA'                             );
	use_ok( 'PITA::Guest'                      );
	use_ok( 'PITA::Guest::Driver'              );
	use_ok( 'PITA::Guest::Driver::Local'       );
	use_ok( 'PITA::Guest::Driver::Image'       );
	use_ok( 'PITA::Guest::Driver::Image::Test' );
	use_ok( 'PITA::Guest::Server'              );
	use_ok( 'PITA::Guest::Server::HTTP'        );
	use_ok( 'PITA::Guest::Storage'             );
	use_ok( 'PITA::Guest::Storage::Simple'     );
}

script_compiles_ok( 't/bin/pita-imagetest' );

ok( $PITA::VERSION,      'PITA was loaded'      );
ok( $PITA::XML::VERSION, 'PITA::XML was loaded' );

foreach my $c ( qw{
	PITA::Guest
	PITA::Guest::Driver
	PITA::Guest::Driver::Local
	PITA::Guest::Driver::Image
	PITA::Guest::Driver::Image::Test
	PITA::Guest::Server
	PITA::Guest::Server::HTTP
	PITA::Guest::Storage
	PITA::Guest::Storage::Simple
} ) {
	eval "is( \$PITA::VERSION, \$${c}::VERSION, '$c was loaded and versions match' );";
}

# Double check the method we use to find a workarea directory
my $workarea = File::Spec->tmpdir;
ok( -d $workarea, 'Workarea directory exists'       );
ok( -r $workarea, 'Workarea directory is readable'  );
ok( -w $workarea, 'Workarea directory is writeable' );
