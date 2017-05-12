# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..153\n";}
END {print "not ok 1\n" unless $loaded;}
use Set::Window;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $N = 2;

sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

sub Identical
{
    not defined $_[0] and not defined $_[1] and return 1;
        defined $_[0] and     defined $_[1] or  return 0;

    my($a, $b) = @_;

    ref $a eq ref $b or return 0;

    for (ref $a)
    {
	/^$/    and return $a eq $b;

	/ARRAY/ and do
	{
	    $#$a==$#$b or return 0;
	    my $i;
	    for $i (0..$#$a) { Identical($a->[$i], $b->[$i]) or return 0 }
	    return 1
	};

	/Set::Window/ and do
	{
	    return Identical([@$a], [@$b])
	};
    }

    0
}

sub Print
{
    defined $_[0] or return 'undef';
    my $a = shift;

    for (ref $a)
    {
	/^$/    and return $a;

	/ARRAY/ and return "[" . join(',', map { Print($_) } @$a) . "]";

	/HASH/  and do
	{
	    my(@pairs, $key, $val);
	    while (($key, $val) = each %$a) { push @pairs, "$key=>$val" }
	    my $pairs = join(',', @pairs);
	    return "{$pairs}"
	};

	/Set::Window/ and return "(@$a)";
    }

    die "Print: unknown reference: ", ref $a, "\n";
}


Creation    ();
Access      ();
Predicates  ();
Modification();
Cover       ();
Intersect   ();
Series      ();


sub Creation
{
    print "#Creation\n";

    my @tests = ([ 'empty' , [     ], [ 0,-1] ],
		 [ 'new_lr', [ 3, 6], [ 3, 6] ],
		 [ 'new_lr', [ 3, 0], [ 0,-1] ],
		 [ 'new_lr', [-1, 0], [-1, 0] ],
		 [ 'new_ll', [ 3, 6], [ 3, 8] ],
		 [ 'new_ll', [ 3,-3], [ 0,-1] ]);

    my $test;
    for $test (@tests)
    {
	my($method, $args, $expected) = @$test;
        my $result = Set::Window->$method(@$args);
	print "#$N: Set::Window->$method(@$args) -> (@$result)\n";
	Identical([@$result], $expected) or Not; OK;
    }
}


sub Access
{
    print "#Access\n";

    my @tests = ([[0,-1], { size     => 0, 
			    elements => [] } ],
		
		 [[3, 7], { left     => 3, 
			    right    => 7, 
			    size     => 5, 
			    bounds   => [3,7], 
			    elements => [3..7] } ] );
    
    my $test;
    for $test (@tests)
    {
	my($bounds, $answer) = @$test;
	my $window = new_lr Set::Window @$bounds;

	my $method;
	for $method (qw(left right size bounds elements))
	{
	    my $result   = $window->$method();
	    my $expected = $answer->{$method};
	    print "#$N: (@$window)->$method -> ", Print($result), "\n";
	    Identical($result, $expected) or Not; OK;
	}
    }

    my($bounds, $answer) = @{$tests[1]};
    my $window = new_lr Set::Window @$bounds;

    my $method;
    for $method (qw(bounds elements))
    {
	my @result   = $window->$method();
	my $expected = $answer->{$method};
	print "#$N: (@$window)->$method -> ", Print(\@result), "\n";
	Identical(\@result, $expected) or Not; OK;
    }
}


sub Predicates
{
    print "#Predicates\n";

    my @bounds = ([0,-1], [0,0], [1,3], [4,4], [2,9], [-7,-5]);

    my @empty = (1, 0, 0, 0, 0, 0);

    my @equiv = ([1, 0, 0, 0, 0, 0],
		 [0, 1, 0, 1, 0, 0],
		 [0, 0, 1, 0, 0, 1],
		 [0, 1, 0, 1, 0, 0],
		 [0, 0, 0, 0, 1, 0],
		 [0, 0, 1, 0, 0, 1]);

    my($i, $j);
    for $i (0..$#bounds)
    {
	my $bounds = $bounds[$i];
	my $w1 = new_lr Set::Window @$bounds;
	my $result   = $w1->empty;
	my $expected = $empty[$i];
	print "#$N: empty      (@$bounds) -> $result\n";
	$result==$expected or Not; OK;

	for $j (0..$#bounds)
	{
	    my $w2 = new_lr Set::Window @{$bounds[$j]};

	    $result   = equal $w1 $w2;
	    $expected = $i==$j;
	    print "#$N: equal      (@$w1) (@$w2) -> $result\n";
	    $result==$expected or Not; OK;

	    $result   = equivalent $w1 $w2;
	    $expected = $equiv[$i][$j];
	    print "#$N: equivalent (@$w1) (@$w2) -> $result\n";
	    $result==$expected or Not; OK;

	}
    }
}


sub Modification
{
    print "#Modification\n";

                 #  bounds   delta  copy     offset   inset
    my @tests = ([ [0,- 1],     1, [ 0,-1], [ 0,-1], [ 0,-1] ],
		 [ [0,- 1],    -1, [ 0,-1], [ 0,-1], [ 0,-1] ],
		 [ [0,  0],     1, [ 0, 0], [ 1, 1], [ 0,-1] ],
		 [ [0,  0],    -1, [ 0, 0], [-1,-1], [-1, 1] ],
		 [ [1,  3],     6, [ 1, 3], [ 7, 9], [ 0,-1] ],
		 [ [4,  4],    -4, [ 4, 4], [ 0, 0], [ 0, 8] ],
		 [ [2,  9],     3, [ 2, 9], [ 5,12], [ 5, 6] ],
		 [ [-7,-5],     1, [-7,-5], [-6,-4], [-6,-6] ]);

	
    my $test;
    for $test (@tests)
    {
	my($bounds, $delta, $copy, $offset, $inset) = @$test;
	my $window = new_lr Set::Window @$bounds;
	my %expected = ( copy   => $copy,
			 offset => $offset,
			 inset  => $inset );

	my $method;
	for $method (qw(copy offset inset))
	{
	    my $result   = $window->$method($delta);
	    my $expected = $expected{$method};
	    print "#$N: (@$window)->$method -> (@$result)\n";
	    Identical([@$result], $expected) or Not; OK;
	}
    }
}


sub Cover
{
    print "#Cover\n";

    my @bounds   = ([0,-1], [0,0], [1,3], [4,4], [2,9], [-7,-5]);
    my @expected = ([0,-1], [0,0], [0,3], [0,4], [0,9], [-7, 9]);
    
    my $i;
    for $i (0..$#bounds)
    {
	my $window = new_lr Set::Window @{$bounds[$i]};
	my $result = cover $window 
	    map { new_lr Set::Window @$_ } @bounds[0..$i-1];
	my $expected = $expected[$i];
	print "#$N: cover ", (map { "(@$_)" } @bounds[0..$i]), " -> ",
	"@$result\n";
	Identical([@$result], $expected) or Not; OK;
    }
}


sub Intersect
{
    print "#Intersect\n";
    my @bounds   = ([5,20], [5,15], [7,30], [10,10], [20,40], [0,-1]);
    my @expected = ([5,20], [5,15], [7,15], [10,10], [ 0,-1], [0,-1]);
    
    my $i;
    for $i (0..$#bounds)
    {
	my $window = new_lr Set::Window @{$bounds[$i]};
	my $result = intersect $window
	    map { new_lr Set::Window @$_ } @bounds[0..$i-1];
	my $expected = $expected[$i];
	print "#$N: intersect ", (map { "(@$_)" } @bounds[0..$i]), " -> ",
	"@$result\n";
	Identical([@$result], $expected) or Not; OK;
    }
}


sub Series
{
    print "#Series\n";

    my @tests = ([[0,-1], 1, []],

		 [[0, 0], 0, undef   ],
		 [[0, 0], 1, [[0,0]] ],

		 [[0, 1], 0, undef,        ],
		 [[0, 1], 1, [[0,0],[1,1]] ],
		 [[0, 1], 2, [[0,1]]       ],
		 [[0, 1], 3, []            ],

		 [[0, 2], 1, [[0,0],[1,1],[2,2]] ],
		 [[0, 2], 2, [[0,1],[1,2]]       ],
		 [[0, 2], 3, [[0,2]]             ],
		 [[0, 2], 4, []                  ],
		 );

    my $test;
    for $test (@tests)
    {
	my($bounds, $length, $series) = @$test;
	my $window   = new_lr Set::Window @$bounds;
	my $expected = defined $series ? 
	    [ map { new_lr Set::Window @$_ } @$series ] : 
	    $series;

	my $result   = $window->series($length);
	print "#$N: (@$bounds)->series($length) -> ", Print($result), "\n";
	Identical($result, $expected) or Not; OK;

	defined $result or next;

	@result = $window->series($length);
	print "#$N: (@$bounds)->series($length) -> ", Print(\@result), "\n";
	Identical([@result], $expected) or Not; OK;
    }
}
