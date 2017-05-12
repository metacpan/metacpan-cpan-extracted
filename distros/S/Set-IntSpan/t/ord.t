# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK
{
    my($function, $test) = @_;

    $test ||= [];
    for (@$test) { defined $_ or $_ = '<undef>' }
    my $expected = pop @$test;

    print "ok $N $function: @$test\t-> $expected\n";

    $N++;
}

my @Ord_die =
(
 [ '(-0',  42, '<die>' ],
);

my @Ord_test =
(
 [ '-'	  	    ,  0, undef ],
 [ '0'	  	    ,  0, 0     ],
 [ '1'	  	    ,  0, undef ],
 [ '1'	  	    ,  2, undef ],
 [ '1,3-5'	    ,  0, undef ],
 [ '1,3-5'	    ,  1, 0     ],
 [ '1,3-5'	    ,  2, undef ],
 [ '1,3-5'	    ,  3, 1     ],
 [ '1,3-5'	    ,  4, 2     ],
 [ '1,3-5'	    ,  5, 3     ],
 [ '1,3-5'	    ,  6, undef ],
 [ '1-)'  	    ,  0, undef ],
 [ '1-)'  	    ,  1, 0     ],
 [ '1-)'  	    ,  8, 7     ],
 [ '1-5,11-15,21-25', 21, 10    ],
);

print "1..", @Ord_die + @Ord_test, "\n";

for my $test (@Ord_die)
{
    my($run_list, $n) = @$test;

    eval { Set::IntSpan->new($run_list)->ord($n) };
    $@ or Not; OK("ord", $test);
}

for my $test (@Ord_test)
{
    my($run_list, $n, $i) = @$test;

    equal(Set::IntSpan->new($run_list)->ord($n), $i) or Not; OK("ord", $test);
}

sub equal
{
    my($a, $b) = @_;

    not defined $a and not defined $b or
        defined $a and     defined $b and $a == $b
}
