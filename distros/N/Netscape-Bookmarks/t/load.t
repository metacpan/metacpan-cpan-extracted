BEGIN {
	@classes = map { my $x = $_;
			$x =~ s|^blib/lib/||;
			$x =~ s|/|::|g;
			$x =~ s|\.pm$||;
			$x;
			} glob( 'blib/lib/Netscape/*.pm blib/lib/Netscape/Bookmarks/*.pm' );
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "bail out! $class did not compile!" unless use_ok( $class );
	}
