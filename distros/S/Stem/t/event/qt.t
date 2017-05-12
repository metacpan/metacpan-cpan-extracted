use lib 't/event' ;

unless ( eval { require Qt } ) {

	print "1..0 # Skip Qt is not installed\n" ;
	exit ;
}

print "1..0 # Skip Qt is not supported yet\n" ;
exit ;

@ARGV = 'qt' ;
require 'event_test.pl' ;
