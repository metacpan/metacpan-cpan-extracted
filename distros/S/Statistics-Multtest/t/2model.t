use Test::More tests => 13;
use List::Vectorize;
use constant {EPS => 1e-6};
use strict;

BEGIN {
	use_ok("Statistics::Multtest", qw(:all));
}

my $p1 = [0.0455565,
          0.5281055,
		  0.8924190,
		  0.5514350,
		  0.4566147,
		  0.9568333,
		  0.4533342,
		  0.6775706,
		  0.5726334,
		  0.1029247];

my $compare;
$compare = mapply( bonferroni($p1), [0.455565, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( holm($p1), [0.455565, 1, 1, 1, 1, 1, 1, 1, 1, 0.9263221],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( hommel($p1), [0.455565, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.8589501],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( hochberg($p1), [0.455565, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9568333, 0.9263221],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( BH($p1), [0.455565, 0.8180477, 0.9568333, 0.8180477, 0.8180477, 0.9568333, 0.8180477, 0.8469633, 0.8180477, 0.5146234],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$compare = mapply( BY($p1), [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

my $p2 = {x1 => 0.07675929,
          x2 => 0.15053771,
          x3 => 0.37055800,
		  x4 => 0.17876729,
          x5 => 0.81925688,
		  x6 => 0.01817646,
		  x7 => 0.34618198,
		  x8 => 0.74689182,
		  x9 => 0.06483379,
		  x10 => 0.47162777};

my $adjp;
$adjp = bonferroni($p2);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}],
                   [0.7675929, 1.0000000, 1.0000000, 1.0000000, 1.0000000, 0.1817646, 1.0000000, 1.0000000, 0.6483379, 1.0000000],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$adjp = holm($p2);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}],
                   [0.6140743, 1.0000000, 1.0000000, 1.0000000, 1.0000000, 0.1817646, 1.0000000, 1.0000000, 0.5835041, 1.0000000],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$adjp = hommel($p2);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}],
                   [0.5373151, 0.7526886, 0.8192569, 0.7860463, 0.8192569, 0.1817646, 0.8192569, 0.8192569, 0.4767128, 0.8192569],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$adjp = hochberg($p2);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}],
                   [0.6140743, 0.8192569, 0.8192569, 0.8192569, 0.8192569, 0.1817646, 0.8192569, 0.8192569, 0.5835041, 0.8192569],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$adjp = BH($p2);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}],
                   [0.2558643, 0.3575346, 0.5293686, 0.3575346, 0.8192569, 0.1817646, 0.5293686, 0.8192569, 0.2558643, 0.5895347],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

$adjp = BY($p2);
$compare = mapply( [$adjp->{x1}, $adjp->{x2}, $adjp->{x3}, $adjp->{x4}, $adjp->{x5}, $adjp->{x6}, $adjp->{x7}, $adjp->{x8}, $adjp->{x9}, $adjp->{x10}],
                   [0.7494184, 1.0000000, 1.0000000, 1.0000000, 1.0000000, 0.5323826, 1.0000000, 1.0000000, 0.7494184, 1.0000000],
                   sub { (abs($_[0] - $_[1]) < EPS) + 0 } );
is_deeply($compare, rep(1, 10));

