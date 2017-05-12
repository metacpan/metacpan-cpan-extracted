# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

my @Cardinality = 
#		 C  E  F  N  P  I  U   <      >
    (['  -   ',  0, 1, 1, 0, 0, 0, 0,  undef, undef ],
     [' (-)  ', -1, 0, 0, 1, 1, 1, 1,  undef, undef ],
     [' (-0  ', -1, 0, 0, 1, 0, 1, 0,  undef, 0     ],
     [' 0-)  ', -1, 0, 0, 0, 1, 1, 0,  0    , undef ],
     ['  1   ',  1, 0, 1, 0, 0, 0, 0,  1    , 1     ],
     ['  5   ',  1, 0, 1, 0, 0, 0, 0,  5    , 5     ],
     [' 1,3,5',  3, 0, 1, 0, 0, 0, 0,  1    , 5     ],
     [' 1,3-5',  4, 0, 1, 0, 0, 0, 0,  1    , 5     ],
     ['-1-5  ',  7, 0, 1, 0, 0, 0, 0, -1    , 5     ],
     );


print "1..", 9 * @Cardinality, "\n";
Cardinality();
Empty();
Finite();
Neg_inf();
Pos_inf();
Infinite();
Universal();
Min();
Max();


sub Cardinality
{
    print "#cardinality\n";

    for my $t (@Cardinality)
    {
	my $operand = $t->[0];
	my $set = new Set::IntSpan $operand;
	my $expected = $t->[1];

	my $result = $set->cardinality();
	printf "#%-12s %-12s -> %d\n", 'cardinality', $operand, $result;
	$result == $expected or Not; OK;
    }
}


sub Empty     { Size("empty"    , 2) }
sub Finite    { Size("finite"   , 3) }
sub Neg_inf   { Size("neg_inf"  , 4) }
sub Pos_inf   { Size("pos_inf"  , 5) }
sub Infinite  { Size("infinite" , 6) }
sub Universal { Size("universal", 7) }

sub Size
{
    my($method, $column) = @_;
   
    print "#$method\n";

    for my $t (@Cardinality)
    {
	my $operand = $t->[0];
	my $set = new Set::IntSpan $operand;
	my $expected = $t->[$column];
	my $result = $set->$method();

	printf "#%-12s %-12s -> %d\n", $method, $operand, $result;
	$result ? $expected : ! $expected or Not; OK;
    }
}


sub Min { Extrema("min", 8) }
sub Max { Extrema("max", 9) }


sub Extrema
{
    my($method, $column) = @_;
   
    print "#$method\n";

    for my $t (@Cardinality)
    {
	my $operand  = $t->[0];
	my $set      = new Set::IntSpan $operand;
	my $expected = $t->[$column];
	my $result   = $set->$method();

	printf "#%-12s %-12s -> %s\n", 
	$method, $operand, defined $result ? $result : 'undef';

	not defined $result and not defined $expected or 
	    defined $result and     defined $expected and $result==$expected or
		Not; OK;
    }
}


