use Test::More tests => 2;

my $file = 'blib/script/release';

use_ok( 'Module::Release' );
	
my $output = `$^X -Mblib -c $file 2>&1`;
			
like( $output, qr/syntax OK$/, 'script compiles' );
           
