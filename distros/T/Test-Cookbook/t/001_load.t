
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Test::Cookbook' ) or BAIL_OUT("Can't load module"); } ;

dies_ok
	{
	my $object = new Test::Cookbook ;
	} "no constructor" ;

dies_ok
	{
	Test::Cookbook::new () ;
	} "no constructor" ;
