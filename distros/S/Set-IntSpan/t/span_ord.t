# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }

sub OK_ord
{
    my $test = shift;

    my($runlist, $n, $ord_exp, $span_exp) = @$test;
    $ord_exp = '<undef>' unless defined $ord_exp;
    print "ok $N ord : $runlist $n\t-> $ord_exp\n";
    $N++;
}

sub OK_span
{
    my $test = shift;

    my($runlist, $n, $ord_exp, $span_exp) = @$test;
    $span_exp = defined $span_exp ? join ', ', map { defined($_) ? $_ : '<undef>' } @$span_exp : '<undef>';
    print "ok $N span: $runlist $n\t-> $span_exp\n";

    $N++;
}

my @Span_ord_test =
(
 [ '-'	  	    	  ,  0, undef, undef	      ],
 [ '(-)'  	    	  ,  0, 0    , [undef, undef] ],
 [ '0'	  	    	  ,  0, 0    , [    0,     0] ],
 [ '1'	  	    	  ,  0, undef, undef	      ],
 [ '1'	  	    	  ,  1, 0    , [    1,     1] ],
 [ '1'	  	    	  ,  2, undef, undef	      ],
 [ '1,3-5'	    	  ,  0, undef, undef	      ],
 [ '1,3-5'	    	  ,  1, 0    , [    1,     1] ],
 [ '1,3-5'	    	  ,  2, undef, undef	      ],
 [ '1,3-5'	    	  ,  3, 1    , [    3,     5] ],
 [ '1,3-5'	    	  ,  4, 1    , [    3,     5] ],
 [ '1,3-5'	    	  ,  5, 1    , [    3,     5] ],
 [ '1,3-5'	    	  ,  6, undef, undef	      ],
 [ '1-)'  	    	  ,  0, undef, undef	      ],
 [ '1-)'  	    	  ,  1, 0    , [    1, undef] ],
 [ '1-)'  	    	  ,  2, 0    , [    1, undef] ],
 [ '(-1'  	    	  ,  0, 0    , [undef,     1] ],
 [ '(-1'  	    	  ,  1, 0    , [undef,     1] ],
 [ '(-1'  	    	  ,  2, undef, undef	      ],
 [ '1-5,11-15,21-25'	  , 21, 2    , [   21,    25] ],
 [ '(-5,11-15,21-25'	  , 21, 2    , [   21,    25] ],
 [ '1-5,11-15,21-25,30-40', 21, 2    , [   21,    25] ],
 [ '(-5,11-15,21-25,30-)' , 21, 2    , [   21,    25] ],
 [ '(-5,11-15,21-25,30-)' , 20, undef, undef	      ],
);

print "1..",  2 * @Span_ord_test, "\n";

for my $test (@Span_ord_test)
{
    my($run_list, $n, $ord_exp, $span_exp) = @$test;

    my $set = new Set::IntSpan $run_list;
    my $ord_act = $set->span_ord($n);
    identical_n($ord_act, $ord_exp) or Not; OK_ord($test);

    my $span_act = defined $ord_act ? ($set->spans)[$ord_act] : undef;
    identical_span($span_act, $span_exp) or Not; OK_span($test);
}

sub identical_n
{
    my($a, $b) = @_;

    not defined $a and not defined $b or
        defined $a and     defined $b and $a == $b
}

sub identical_span
{
    my($a, $b) = @_;

    not defined $a and not defined $b or
	defined $a and     defined $b and
	    identical_n($a->[0], $b->[0]) and identical_n($a->[1], $b->[1])
}
