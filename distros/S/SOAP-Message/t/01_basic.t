
	use strict;
	use warnings;
	use Test::More tests => 2;
	use SOAP::Message;
	
	ok(1, "Module loaded ok");
	ok( SOAP::Message::create(data => 'a'), "Create returns something, that's good");
	
