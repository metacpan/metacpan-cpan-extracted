#!perl

# Number::Uncertainty test harness
use Test::More tests => 98;

use strict;
use warnings;

use File::Spec;
use Data::Dumper;

# load modules
require_ok("Number::Uncertainty");

# T E S T S ------------------------------------------------------------------

# test the tet system
ok(1);

my ( $obj0, $obj1, $obj2, $obj3, $obj4, $obj5, $obj6, $obj7 );

$obj0 = new Number::Uncertainty( Value => 2 );
				 
$obj1 = new Number::Uncertainty( Value => 2,
				 Error => 5 );

$obj2 = new Number::Uncertainty( Value => 2,
				 Lower => 3,
     				 Upper => 5 );

$obj3 = new Number::Uncertainty( Value => 2,
				 Min   => -1,
     				 Max   => 7 );

$obj4 = new Number::Uncertainty( Value => 2,
				 Bound => 'lower' );

$obj5 = new Number::Uncertainty( Value => 2,
                                 Bound => 'upper' );

isa_ok( $obj0, "Number::Uncertainty" );
isa_ok( $obj1, "Number::Uncertainty" );
isa_ok( $obj2, "Number::Uncertainty" );
isa_ok( $obj3, "Number::Uncertainty" );
isa_ok( $obj4, "Number::Uncertainty" );
isa_ok( $obj5, "Number::Uncertainty" );

# Error bar
is( $obj0->error(),0, "Error bar on \$obj0" );
is( $obj1->error(),5, "Error bar on \$obj1" );
is( $obj2->error(),8, "Error bar on \$obj2" );
is( $obj3->error(),8, "Error bar on \$obj3" );
is( $obj4->error(),undef, "Error bar on \$obj4" );
is( $obj5->error(),undef, "Error bar on \$obj5" );

# Minimum Value
is( $obj0->min(),2, "Minimum value of \$obj0" );
is( $obj1->min(),-0.5, "Minimum value of \$obj1" );
is( $obj2->min(),-1, "Minimum value of \$obj2" );
is( $obj3->min(),-1, "Minimum value of \$obj3" );
is( $obj4->min(),2, "Minimum value of \$obj4" );
is( $obj5->min(),undef, "Minimum value of \$obj5" );

# Maximum value
is( $obj0->max(),2, "Maximum value of \$obj0" );
is( $obj1->max(),4.5, "Maximum value of \$obj1" );
is( $obj2->max(),7, "Maximum value of \$obj2" );
is( $obj3->max(),7, "Maximum value of \$obj3" );
is( $obj4->max(),undef, "Maximum value of \$obj4" );
is( $obj5->max(),2, "Maximum value of \$obj5" );

# Equals
ok( $obj0 == $obj1, "\$obj0 equals \$obj1" );
ok( $obj0 == $obj2, "\$obj0 equals \$obj2" );
ok( $obj0 == $obj3, "\$obj0 equals \$obj3" );
ok( $obj0 == $obj4, "\$obj0 equals \$obj4" );
ok( $obj0 == $obj5, "\$obj0 equals \$obj5" );

ok( $obj1 == $obj0, "\$obj1 equals \$obj0" );
ok( $obj1 == $obj2, "\$obj1 equals \$obj2" );
ok( $obj1 == $obj3, "\$obj1 equals \$obj3" );
ok( $obj1 == $obj4, "\$obj1 equals \$obj4" );
ok( $obj1 == $obj5, "\$obj1 equals \$obj5" );

ok( $obj2 == $obj0, "\$obj2 equals \$obj0" );
ok( $obj2 == $obj1, "\$obj2 equals \$obj1" );
ok( $obj2 == $obj3, "\$obj2 equals \$obj3" );
ok( $obj2 == $obj4, "\$obj2 equals \$obj4" );
ok( $obj2 == $obj5, "\$obj2 equals \$obj5" );

ok( $obj3 == $obj0, "\$obj3 equals \$obj0" );
ok( $obj3 == $obj1, "\$obj3 equals \$obj1" );
ok( $obj3 == $obj2, "\$obj3 equals \$obj2" );
ok( $obj3 == $obj4, "\$obj3 equals \$obj4" );
ok( $obj3 == $obj5, "\$obj3 equals \$obj5" );

ok( $obj4 == $obj0, "\$obj4 equals \$obj0" );
ok( $obj4 == $obj1, "\$obj4 equals \$obj1" );
ok( $obj4 == $obj2, "\$obj4 equals \$obj2" );
ok( $obj4 == $obj3, "\$obj4 equals \$obj3" );
ok( $obj4 == $obj5, "\$obj4 equals \$obj5" );

ok( $obj5 == $obj0, "\$obj5 equals \$obj0" );
ok( $obj5 == $obj1, "\$obj5 equals \$obj1" );
ok( $obj5 == $obj2, "\$obj5 equals \$obj2" );
ok( $obj5 == $obj3, "\$obj5 equals \$obj3" );
ok( $obj5 == $obj4, "\$obj5 equals \$obj4" );

# not equal
ok( !( $obj0 != $obj1 ), "! \$obj0 not equal \$obj1" );
ok( !( $obj0 != $obj2 ), "! \$obj0 not equal \$obj2" );
ok( !( $obj0 != $obj3 ), "! \$obj0 not equal \$obj3" );
ok( !( $obj0 != $obj4 ), "! \$obj0 not equal \$obj4" );
ok( !( $obj0 != $obj5 ), "! \$obj0 not equal \$obj5" );

ok( !( $obj1 != $obj0 ), "! \$obj1 not equal \$obj0" );
ok( !( $obj1 != $obj2 ), "! \$obj1 not equal \$obj2" );
ok( !( $obj1 != $obj3 ), "! \$obj1 not equal \$obj3" );
ok( !( $obj1 != $obj4 ), "! \$obj1 not equal \$obj4" );
ok( !( $obj1 != $obj5 ), "! \$obj1 not equal \$obj5" );

ok( !( $obj2 != $obj0 ), "! \$obj2 not equal \$obj0" );
ok( !( $obj2 != $obj1 ), "! \$obj2 not equal \$obj1" );
ok( !( $obj2 != $obj3 ), "! \$obj2 not equal \$obj3" );
ok( !( $obj2 != $obj4 ), "! \$obj2 not equal \$obj4" );
ok( !( $obj2 != $obj5 ), "! \$obj2 not equal \$obj5" );

ok( !( $obj3 != $obj0 ), "! \$obj3 not equal \$obj0" );
ok( !( $obj3 != $obj1 ), "! \$obj3 not equal \$obj1" );
ok( !( $obj3 != $obj2 ), "! \$obj3 not equal \$obj2" );
ok( !( $obj3 != $obj4 ), "! \$obj3 not equal \$obj4" );
ok( !( $obj3 != $obj5 ), "! \$obj3 not equal \$obj5" );

ok( !( $obj4 != $obj0 ), "! \$obj4 not equal \$obj0" );
ok( !( $obj4 != $obj1 ), "! \$obj4 not equal \$obj1" );
ok( !( $obj4 != $obj2 ), "! \$obj4 not equal \$obj2" );
ok( !( $obj4 != $obj3 ), "! \$obj4 not equal \$obj3" );
ok( !( $obj4 != $obj5 ), "! \$obj4 not equal \$obj5" );

ok( !( $obj5 != $obj0 ), "! \$obj5 not equal \$obj0" );
ok( !( $obj5 != $obj1 ), "! \$obj5 not equal \$obj1" );
ok( !( $obj5 != $obj2 ), "! \$obj5 not equal \$obj2" );
ok( !( $obj5 != $obj3 ), "! \$obj5 not equal \$obj3" );
ok( !( $obj5 != $obj4 ), "! \$obj5 not equal \$obj4" );

# A not equal point
$obj6 = new Number::Uncertainty( Value => 17,
				 Error => 5 );
ok( !( $obj6 == $obj1 ), "! \$obj6 equal to \$obj1" );
ok( $obj6 != $obj1, "\$obj6 not equal \$obj1" );
is( "$obj6", "17 +- 2.5", "Trying to stringify" );
	
	
				 
# A negative point
$obj7 = new Number::Uncertainty( Value => -10,
				 Error => 30 );	

is( $obj7->min(),-25, "Minimum value of \$obj7" );
is( $obj7->max(),5, "Maximum value of \$obj7" );
				 
				 			 
is( $obj7 == $obj1,1, "\$obj7 equal to \$obj1" );


# multiply
my $mult;
ok( $mult = $obj1*$obj2 );
isa_ok( $mult, "Number::Uncertainty" );


# Greater than.
my $obj10 = new Number::Uncertainty( Value => 4,
                                     Error => 4 );
my $obj11 = new Number::Uncertainty( Value => 5,
                                     Error => 2 );
ok( ( $obj10 > $obj11 ), "\$obj10 > \$obj11" );
ok( ( $obj10->greater_than( $obj11 ) ), "\$obj10 greater_than \$obj11" );
ok( ( $obj10 < $obj11 ), "\$obj10 < \$obj11" );
ok( ( $obj10->less_than( $obj11 ) ), "\$obj10 less_than \$obj11" );


# L A S T   O R D E R S   A T   T H E   B A R --------------------------------

END {
  exit;
}
