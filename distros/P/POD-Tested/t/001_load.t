
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);

use Test::Exception ;

BEGIN { use_ok( 'POD::Tested' ) or BAIL_OUT("Can't load module"); } ;

my $object = new POD::Tested(STRING => '') ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, 'POD::Tested');

throws_ok
	{
	new POD::Tested('only one argument') ;
	}
	qr/Invalid constructor call/, 'invalid arguments' ;
	


