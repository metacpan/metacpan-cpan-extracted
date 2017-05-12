use lib 't/event' ;

unless ( eval { require Stem::Event::Tk } ) {

	print "1..0 # Skip Tk is not installed\n" ;
	exit ;
}

@ARGV = 'tk' ;
eval{ require 'event_test.pl' } ;
#print "ERR [$@]\n" if $@ ;