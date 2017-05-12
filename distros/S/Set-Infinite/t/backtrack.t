#/bin/perl -w
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Tests for Set::Infinite backtracking

use strict;
# use warnings;

$| = 1;

use Set::Infinite qw($inf);

my ($a, $a_quant, $b, $c, $d, $finite, $q, $r);


my $test = 0;
my ($result, $errors);
my $neg_inf = -$inf;

sub test {
	my ($header, $sub, $expected) = @_;
	$test++;
	# print "    # $header \n";
	$result = eval $sub;
        $result = '' unless defined $result;
	if ("$expected" eq "$result") {
            print "ok $test\n";
            print "    # $header \n";
	}
	else {
	    print "not ok $test\n"; # \n\t# expected \"$expected\" got \"$result\"";
            print "    # $header \n";
	    print "    # $sub expected \"$expected\" got \"$result\" $@\n";
	    $errors++;
	}
	# print " \n";
}


print "1..40\n";
    $a = Set::Infinite->new([$neg_inf,15]);
    $a_quant = $a->quantize(quant => 1);
    $finite = Set::Infinite->new([10,20]);

    $b = Set::Infinite->new([15,$inf]);

    # print "a = $a\n";

# 1 "too complex"
    $q = $a->quantize(quant => 1);
    # print "q = ",$q,"\n";
    test ('complex', '$q', $Set::Infinite::too_complex);

# 2 quantize has min/max
    $q = $a->quantize(quant => 1);
    # print " q $q ",$q->min," $q ",$q->max," ",$q->intersection($finite),"\n";
    test ('min', '$q->min', "$neg_inf");
    test ('max', '$q->max', '16'  );
    test ('span', '$q->span', "($neg_inf..16)"  );
    test ('size', '$q->size', $inf  );

    $q = $b->quantize(quant => 1);
    test ('min', '$q->min', '15');

# 7 min/max with open set
    $r = $a->copy->complement(15);
	# print "r = ",$r,"\n";
    $r = $r->quantize(quant => 1);
    test ('max', '$r->max', '15'  );
    test ('span', '$r->span', "($neg_inf..15)"  );
    test ('size', '$r->size', $inf  );

# 10 offset
    $q = $r->offset( value => [ -10, 10 ] );
    # print "r = ",$r->intersection(-100,100),"\n";
    # print "r offset = ... ",$q->intersection(-100,100),"\n";
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    test ('max', '$q->max', '25'  );
    test ('span', '$q->span', "($neg_inf..25)"  );
    test ('size', '$q->size', $inf  );
# $Set::Infinite::TRACE = 0;
# $Set::Infinite::PRETTY_PRINT = 0;

# 13 min/max with open "integer" set
    $r = $r->integer;
    # print "r = ",$r->intersection(-1000,1000),"\n";
    # print "r tolerance = ",$r->tolerance,"\n";
    test ('max', '$r->max', '14'  );
    test ('span', '$r->span', "($neg_inf..14]"  );
    test ('size', '$r->size', $inf  );

# 16 max with union 
    $q = Set::Infinite->new([$neg_inf,15])->quantize;
    $r = Set::Infinite->new([$neg_inf,10])->quantize;
    test ('union-max', '$r->union($q)->max', '16'  );
# max with intersection
    # TODO: test this after we implement last()
    test ('intersection-max', '$r->intersection($q)->max', '11'  );
# min with union
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    $q = Set::Infinite->new([15,$inf])->quantize;
    $r = Set::Infinite->new([10,$inf])->quantize;
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    test ('union-min', '$r->union($q)->min', '10'  );
# min with intersection
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    test ('intersection-min', '$r->intersection($q)->min', '15'  );

# 20 min/max of complement works
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    $r = Set::Infinite->new([$neg_inf,15])->complement(15)->integer->quantize(quant => 1);
	# print "r = ",$r,"\n";
    $r = $r->complement(15);  # complement doesn't backtrack yet
	# print "r = ",$r,"\n";
    test ('complement-max', '$r->max', '14'  );
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    $r = $r->complement;
    test ('complement-max=inf', '$r->max', $inf  );  
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
    #  (14..inf)
    test ('complement-min', '$r->min', '15'  );   
# $Set::Infinite::TRACE = 0;
# $Set::Infinite::PRETTY_PRINT = 0;

# 23 scalar
    $q = $a->quantize(quant => 1);
    # print "r = ",$q->intersection(10,20),"\n";
    test ('intersection', '$q->intersection(10,20)', '[10..16)');

# 24 "date"
	$a = Set::Infinite->new([$neg_inf,3800]);
	# print "s = ",$a->quantize(quant => 1, unit => 'hours')->intersection(1000,15000),"\n";
	test ('date', '$a->quantize(quant => 1, unit => \'hours\')->intersection(1000,15000)', 
		'[1000..7200)');

# 25 almost-intersecting "date"
	$a = Set::Infinite->new([$neg_inf,3800]);
	# print "t = ",$a->quantize(quant => 1, unit => 'hours')->intersection(3700,15000),"\n";
	test ('', '$a->quantize(quant => 1, unit => \'hours\')->intersection(3700,15000)', 
		'[3700..7200)');
	test ('', '$a->quantize(quant => 1, unit => \'hours\')->intersection(3900,15000)', 
		'[3900..7200)');

# 27 null "date"
	# print "u = ",$a->quantize(quant => 1, unit => 'hours')->intersection(9000,15000),"\n";
	test ('', '$a->quantize(quant => 1, unit => \'hours\')->intersection(9000,15000)', 
		'');

# 28 recursive 
	# print "v: ", $a->quantize(quant => 1)->quantize(quant => 1)->intersection(10,20), "\n";
	test ('', '$a->quantize(quant => 1)->quantize(quant => 1)->intersection(10,20)', 
		'[10..20]');

# 29 intersection with 'b' complex
	# print "w: ", $finite->intersection( $a->quantize(quant => 1) ), "\n";
	test ('', '$finite->intersection( $a->quantize(quant => 1) )', 
		'[10..20]');

# 30 intersection with both 'a' and 'b' complex
        $a = Set::Infinite->new([$neg_inf,15]);
        $a_quant = $a->quantize(quant => 1);
	$b = Set::Infinite->new([10,$inf])->quantize(quant => 1);
	$c = Set::Infinite->new([20,$inf])->quantize(quant => 1);
	$d = Set::Infinite->new([$neg_inf,12])->quantize(quant => 1);

	# intersecting 
	# print "x = ",$a_quant->intersection($b),"\n";
	test ('complex intersection', '$a_quant->intersection($b)', 
		'[10..16)');

	# non-intersecting
	# print "y = ",$a_quant->intersection($c),"\n";
	test ('complex no-intersection', '$a_quant->intersection($c)', 
		'');

	# intersecting but too complex
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
	# print "z = ",$a_quant->intersection($d),"\n";
	test ('too-complex intersection', '$a_quant->intersection($d)', 
		"($neg_inf..13)" );
# $Set::Infinite::TRACE = 0;
# $Set::Infinite::PRETTY_PRINT = 0;

	# intersecting but too complex, then intersect again
	# print "i = ",$a_quant->intersection($d)->intersection($finite),"\n";
	test ('', '$a_quant->intersection($d)->intersection($finite)', 
		'[10..13)');

# 13 - 15 offset
	# print "j = ",$a->quantize(quant => 4)->offset( value => [1,-1] )->intersection($finite),"\n";
# $Set::Infinite::TRACE = 1;
# $Set::Infinite::PRETTY_PRINT = 1;
	test ('', '$a->quantize(quant => 4)->offset( value => [1,-1] )->intersection($finite)', 
		'[10..11),[13..15)');
# $Set::Infinite::TRACE = 0;
# $Set::Infinite::PRETTY_PRINT = 0;

	# BIG offset
	# print "k = ",$a->quantize(quant => 4)->offset( value => [20,18] )->intersection($finite),"\n";
	test ('', '$a->quantize(quant => 4)->offset( value => [20,18] )->intersection($finite)', 
		'[12..14),[16..18),20');

	# intersecting, both complex
	$a = Set::Infinite->new([$neg_inf,15]);
	test ('', '$a->quantize(quant => 4)->offset( value => [1,-1] )->intersection($b)->intersection($finite)', 
		'[10..11),[13..15)');

# select
	# print "l = ", $a->quantize(quant => 2)->select( freq => 3 )->intersection($finite), "\n";
	# test ('', '$a->quantize(quant => 1)->select( by => [ 2, 4, 6, 8 ] )->intersection($finite)', 
	#	'[10..11),[12..13),[14..15)');

	# BIG, negative select
	# -- wrong! (TODO ????)
	# test ('', '$a->quantize(quant => 1)->select( freq => 2, by => [-10,10] )->intersection($finite)', 
	#	'[10..11),[12..13),[14..15)');

	# intersecting, both complex
	#  (TODO ????)

# intersects

	# intersecting 
	test ('', '$a_quant->intersects($b)', 
		'1');

	# non-intersecting
	test ('', '$a_quant->intersects($c)', 
		'0');

# union
	test ('', '$a_quant->union([50,60])->intersection([0,100])', 
		'[0..16),[50..60]');

# complement
	#  (TODO ????)
        # $Set::Infinite::TRACE = 1;
        # $Set::Infinite::DEBUG_BT = 1;
        test ('', '$a_quant->complement->intersection([0,25])', '[16..25]');

# size
	#  (TODO ????)

# contains
	# -- wrong! (TODO ????)
	# test ('', '$a_quant->contains([0,100])', 
	#	'');

1;
