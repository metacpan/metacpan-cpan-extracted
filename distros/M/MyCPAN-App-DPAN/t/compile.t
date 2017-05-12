use File::Spec::Functions qw(catfile);
use Test::Output;

use vars qw( @scripts );

BEGIN {	
	@scripts = catfile( qw( script dpan ) );
	}

use Test::More tests => 2 * scalar @scripts;

foreach my $script ( @scripts )
	{
	ok( -e $script, "$script exists" );
	
	my $output = `$^X -c $script 2>&1`;
	
	print "Bail out! $script did not compile\n"
		unless like( $output, qr/syntax ok/i, "Script $script compiles" );
	}
