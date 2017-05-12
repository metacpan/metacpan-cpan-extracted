
use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;
#use Test::UniqueTestNames ;

BEGIN { use_ok( '{{$FULL_MODULE_NAME}}' ) or BAIL_OUT("Can't load module"); } ;

my $object = new {{$FULL_MODULE_NAME}} ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, '{{$FULL_MODULE_NAME}}');

my $new_config = $object->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , '{{$FULL_MODULE_NAME}}');

dies_ok
	{
	{{$FULL_MODULE_NAME}}::new () ;
	} "invalid constructor" ;
