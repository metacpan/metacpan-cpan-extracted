use utf8;
use strict;

use vars qw( @classes );

BEGIN {
	use File::Find;
	use File::Find::Closures;
	use File::Spec;
	
	my( $wanted, $reporter ) = File::Find::Closures::find_by_regex( qr/\.pm\z/ );
	find( $wanted, File::Spec->catfile( qw(blib lib) ) );

	@classes = map {
		s/\.pm\z//;
		
		my @parts = File::Spec->splitdir( $_ );
		splice @parts, 0, 2, ();
		join "::", @parts;
		} $reporter->();
	}

use Test::More 0.95;

foreach my $class ( @classes ) {
	next if $class =~ /::(?:Tk|Curses|ANSIText)/;
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();
