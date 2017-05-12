use lib 't/event' ;

unless ( eval { require Event } ) {

	print "1..0 # Skip Event.pm is not installed\n" ;
	exit ;
}

@ARGV = 'event' ;
require 'event_test.pl' ;
