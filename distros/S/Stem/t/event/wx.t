use lib 't/event' ;

unless ( eval { require Wx } ) {

	print "1..0 # Skip WxWindows is not installed\n" ;
	exit ;
}

@ARGV = 'wx' ;
require 'event_test.pl' ;
