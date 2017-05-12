#!/usr/bin/perl
use PDL::LiteF;
use PDL::LinearAlgebra;
use PDL::LinearAlgebra::Trans qw //;
use PDL::Complex;
use Test;

BEGIN { plan tests => 9 };

sub fapprox {
	my($a,$b) = @_;
	PDL::abs($a-$b)->max < 0.0001;
}

$a = pdl([[1.7,3.2],[9.2,7.3]]);
ok(fapprox($a->t,$a->xchg(0,1)));

$aa = cplx random(2,2,2);
ok(fapprox($aa->t(0),$aa->xchg(1,2)));

$id = pdl([[1,0],[0,1]]);
ok(fapprox($a->minv x $a,$id));

ok(fapprox($a->mcrossprod->mposinv->tritosym x $a->mcrossprod,$id));

ok(fapprox($a->mdet ,-17.03 ));

ok($a->mcrossprod->mposdet !=0);


ok(fapprox($a->mcos->macos,pdl([[1.7018092, 0.093001244],[0.26737858,1.8645614]])));
ok(fapprox($a->msin->masin,pdl([[ -1.4397834,0.093001244],[0.26737858,-1.2770313]])));
ok(fapprox($a->mexp->mlog,$a));
