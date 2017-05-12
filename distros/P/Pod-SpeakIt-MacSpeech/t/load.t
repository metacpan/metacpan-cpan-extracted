# $Id: load.t,v 1.2 2004/09/08 00:25:42 comdog Exp $
BEGIN {
	@classes = qw(Pod::SpeakIt::MacSpeech);
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	print "bail out! $class did not compile\n" unless use_ok( $class );
	}
