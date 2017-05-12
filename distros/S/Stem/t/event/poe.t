use lib 't/event' ;

unless ( eval { require POE } ) {

	print "1..0 # Skip POE is not installed\n" ;
	exit ;
}

print "1..0 # Skip POE is not supported yet\n" ;
exit ;

@ARGV = 'poe' ;
require 'event_test.pl' ;
