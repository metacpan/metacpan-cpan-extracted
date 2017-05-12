use Test::More;
use strict;
use constant {EPS => 1e-5};
use List::Vectorize;


eval 'use Test::Exception';
my $test_exception = 0;
if($@) {
	$test_exception = 1;
}

BEGIN {
	use_ok("Statistics::Multtest", qw(qvalue));
}

my $p1 = [qw(0.75 0.22 0.41 0.29 0.29 0.59 0.30 0.94 0.44 0.79)];
		  
my $compare;
$compare = mapply( qvalue($p1), [qw(0.6383838 0.5333333 0.5333333 0.5333333 0.5333333 0.6129870 0.5333333 0.6836364 0.5333333 0.6383838)],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( qvalue($p1, 'robust' => 1), [qw(0.6383839 0.5349559 0.5349559 0.5349559 0.5349559 0.6130693 0.5349559 0.6836364 0.5349559 0.6383839)],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

my $p2 = [qw(0.48 0.10 0.09 0.16 0.68 0.49 0.09 0.01 0.45 0.08)];

if($test_exception) {
	eval 'dies_ok {qvalue($p2)}, "pi0 is not positive."';
}

$compare = mapply( qvalue($p2, 'lambda' => [0.5]), [qw(0.10888889 0.04000000 0.04000000 0.05333333 0.13600000 0.10888889 0.04000000 0.02000000 0.10888889 0.040000008)],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( qvalue($p2, 'lambda' => [0.5], 'robust' => 1), [qw(0.10901867 0.06141360 0.06141360 0.06463873 0.13600153 0.10901867 0.06141360 0.06141360 0.10901867 0.06141360)],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

my $p3 = {'x1' => 0.0,
          'x2' => 0.1,
		  'x3' => 0.2,
		  'x4' => 0.3,
		  'x5' => 0.4,
		  'x6' => 0.5,
		  'x7' => 0.6,
		  'x8' => 0.7,
		  'x9' => 0.8,
		  'x10' => 0.9,
		  'x11' => 1.0};
my $adjp = qvalue($p3);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}, $adjp->{x11}],
                   [qw(0.0000000 0.5263158 0.7017544 0.7894737 0.8421053 0.8771930 0.9022556 0.9210526 0.9356725 0.9473684 0.9569378)],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 11));

$p3 = {'x1' => 0.1,
          'x2' => 0.1,
		  'x3' => 0.1,
		  'x4' => 0.1,
		  'x5' => 0.1,
		  'x6' => 0.1,
		  'x7' => 0.1,
		  'x8' => 0.1,
		  'x9' => 0.1,
		  'x10' => 0.1,
		  'x11' => 0.1};
if($test_exception) {
	eval 'dies_ok {qvalue($p3)}, "pi0 is not positive."';
}

$p3 = {'x1' => 0.9,
          'x2' => 0.9,
		  'x3' => 0.9,
		  'x4' => 0.9,
		  'x5' => 0.9,
		  'x6' => 0.9,
		  'x7' => 0.9,
		  'x8' => 0.9,
		  'x9' => 0.9,
		  'x10' => 0.9,
		  'x11' => 0.9};
$adjp = qvalue($p3);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}, $adjp->{x11}],
                   [qw(0.9 0.9 0.9 0.9 0.9 0.9 0.9 0.9 0.9 0.9 0.9)],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 11));

done_testing();

