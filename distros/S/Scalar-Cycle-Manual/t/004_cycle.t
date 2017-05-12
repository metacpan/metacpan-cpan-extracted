# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Scalar::Cycle::Manual ; 

{
local $Plan = {'access' => 25} ;

my $cyclic_variable = new Scalar::Cycle::Manual( qw( first second third ) ) ;

is($cyclic_variable, 'first', 'access') ;

$cyclic_variable->increment() ;
is($cyclic_variable, 'second', 'increment') ;

$cyclic_variable++ ;
is($cyclic_variable, 'third', '++') ;

$cyclic_variable++ ;
is($cyclic_variable, 'first', 'loops') ;

$cyclic_variable->decrement ;
is($cyclic_variable, 'third', 'decrement') ;

$cyclic_variable--;
is($cyclic_variable, 'second', '--') ;

is($cyclic_variable->next, 'third', 'next') ;
is($cyclic_variable, 'second', 'position unchanged') ;

is($cyclic_variable->previous, 'first', 'next') ;
is($cyclic_variable, 'second', 'position unchanged') ;

$cyclic_variable->auto_increment(1) ;
is($cyclic_variable, 'second', 'position unchanged by auto_increment call') ;
is($cyclic_variable, 'third', 'position incremented by access') ;

$cyclic_variable->auto_increment(0) ;
is($cyclic_variable, 'first', 'position unchanged') ;
is($cyclic_variable, 'first', 'position unchanged') ;
	
is("$cyclic_variable", 'first', 'string') ;

is(<$cyclic_variable>, 'first', 'first <>') ;
is($cyclic_variable, 'second', 'after <>') ;
is(<$cyclic_variable>, 'second', 'second <>') ;

is($cyclic_variable->next, 'first', 'next at -1') ;

$cyclic_variable->reset ;

is("$cyclic_variable", 'first', 'reset') ;
is($cyclic_variable->previous, 'third', 'previous at 0') ;

my $cv = $cyclic_variable ;
is($cv, 'first', 'copy constructor') ;

my $string = "value = " . $cyclic_variable++ . '' ;
is($string,  'value = first', 'copy constructor') ;

my $auto_increment = $cyclic_variable->auto_increment() ;
is($auto_increment, 0, 'auto_increment query') ;

$cyclic_variable->auto_increment(1) ;
$auto_increment = $cyclic_variable->auto_increment() ;
is($auto_increment, 1, 'auto_increment query') ;
}
