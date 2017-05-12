#!/usr/bin/perl
use strict; use warnings;

use SOAP::Lite;
use Data::Dumper qw( Dumper );

print "The sum of 8,6,7,5,3,0,9,183 is: ";

print SOAP::Lite
	-> uri('http://localhost:32080/')
	-> proxy('http://localhost:32080/?session=MyServer')
	-> Sum_Things( 8, 6, 7, 5, 3, 0, 9, 183 )
	-> result
	;
print "\n\nNow, the time is: ";

print SOAP::Lite
	-> uri('http://localhost:32080/')
	-> proxy('http://localhost:32080/?session=TimeServer')
	-> Time()
	-> result
	;
print "\n\nNow, for a pretty Data::Dumper output of a hash:\n";

print SOAP::Lite
	-> uri('http://localhost:32080/')
	-> proxy('http://localhost:32080/?session=MyServer')
	-> DUMP(
		{
			'Foo'		=>	'Baz',
			'Hello'		=>	'World!',
			'Frobnicate'	=>	45,
		},
	)-> result
	;
print "\n\nNow, let's see some raw XML!\n";

print Dumper( SOAP::Lite
	-> uri('http://localhost:32080/')
	-> proxy('http://localhost:32080/?session=MyServer')
	-> Get_XML()
	-> result
	);
