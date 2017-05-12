use lib 't/event' ;

unless ( eval { require Gtk } ) {

	print "1..0 # Skip Gtk is not installed\n" ;
	exit ;
}

print "1..0 # Skip Gtk is not supported yet\n" ;
exit ;

@ARGV = 'gtk' ;
require 'event_test.pl' ;
