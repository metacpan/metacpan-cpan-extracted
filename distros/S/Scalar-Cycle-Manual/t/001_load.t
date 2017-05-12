
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Scalar::Cycle::Manual' ) or BAIL_OUT("Can't load module"); } ;

my $object = new Scalar::Cycle::Manual ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, 'Scalar::Cycle::Manual');

my $new_config = $object->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'Scalar::Cycle::Manual');

lives_ok
	{
	Scalar::Cycle::Manual::new () ;
	} "invalid constructor" ;
