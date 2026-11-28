#!/usr/bin/env perl
#
# predict() of an lm/glm fitted with offset(): the offset is evaluated on
# newdata and added to the linear predictor, as predict.lm and predict.glm do.
#
# Provenance: R 4.6.1, options(digits=17), the data below; the generator is
# t/predict.offset.R.R (run with Rscript; this test never calls it).
# Rules: predict.lm / predict.glm (stats), which take offset() terms from the
# model frame of newdata.
#
# Tolerance: 1e-9 relative; the worst disagreement seen was 3e-15 on a double
# build, headroom for long double and quadmath.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(:all);

my %d = (
	y => [1.2,2.9,3.1,4.8,5.2,6.9,7.1,8.4,9.9,10.3,11.8,12.1],
	x => [1,2.5,3,4.5,5,6.5,7,8.5,9,10.5,11,12.5],
	z => [2,3,5,4,6,8,7,9,12,11,13,15.5],
	a => [('p','q','r') x 4],
);
my %c = (%d, y => [1,3,2,6,4,9,7,12,8,15,11,20]);
my %nd = (x => [2.5,6.5,9.5], z => [3.5,6,10], a => [qw(q p r)]);

sub check {
	my ($got, $want, $name) = @_;
	for my $i (0 .. 2) {
		my $g = $got->{ $i + 1 };
		cmp_ok(abs($g - $want->[$i]), '<=', 1e-9 * abs($want->[$i]), "$name row " . ($i + 1)) or diag("got $g want $want->[$i]");
	}
}

check(predict(lm(formula => 'y~x+offset(z/2)', data => \%d), \%nd),
	[2.9556927881885295, 5.8905309483248161, 9.1541595684270316], 'lm offset(z/2)');
check(predict(lm(formula => 'y~a+x+offset(log(z))', data => \%d), \%nd),
	[2.9103158033013976, 6.6543555063482884, 9.516880043045699], 'lm factor + offset(log(z))');
my $g = glm(formula => 'y~x+offset(log(z))', data => \%c, family => 'poisson');
check(predict($g, \%nd, type => 'link'),
	[1.0092560577189411, 1.7222671986168514, 2.3636038025067601], 'glm poisson link');
check(predict($g, \%nd),
	[2.7435592059231544, 5.5972040631065152, 10.629188006939772], 'glm poisson response');
done_testing;
