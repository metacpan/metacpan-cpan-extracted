=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use Photonic::Geometry::FromB;
use Photonic::Geometry::FromImage2D;
use Photonic::Geometry::FromEpsilon;
use Photonic::Utils qw(lu_solve);
use lib 't/lib';
use TestUtils;
use Test::More;
my $pi=4*atan2(1,1);

my $B=zeroes(11,11)->rvals<=5;
my $g=Photonic::Geometry::FromB->new(B=>$B);
my $gl=Photonic::Geometry::FromB->new(B=>$B, L=>pdl(1,1));
ok(defined $g, "Create geometry from B");
ok(agree($g->B,$B), "Recover B");
ok($g->L->ndims==1, "L is a vector");
ok(($g->L->dims)[0]==2, "L is a 2D vector");
ok(($g->L->dims)[0]==2, "L is a 2D vector");
ok(agree(pdl($g->L),pdl(11,11)), "correct L values");
ok(agree($g->units, identity(2)), "units");
ok($g->npoints==11*11, "npoints");
ok(agree($g->scale,pdl(1,1)), "Default scale");
ok(agree($gl->scale, pdl(1/11,1/11)), "Scale");
ok(agree($g->r->(:,(5),(5)), pdl(5,5)), "Default coordinates of center");
ok(agree($gl->r->(:,(5),(5)), pdl(5/11,5/11)), "Coordinates of center");
ok(agree($g->G->(:,(0),(0)), pdl(0,0)), "Reciprocal vector at corner");
ok(agree($g->G->(:,(5),(5)), pdl(5*2*$pi/11,5*2*$pi/11)),
   "Default reciprocal vector at center");
ok(agree($g->G->(:,(6),(6)), pdl(-5*2*$pi/11,-5*2*$pi/11)),
   "Default reciprocal vector beyond center");
ok(agree($gl->G->(:,(6),(6)), pdl(-5*2*$pi,-5*2*$pi)),
   "Reciprocal vector beyond center");
ok(!$g->has_Direction0, "False Direction0 predicate");
$g=Photonic::Geometry::FromB->new(B=>$B,Direction0=>pdl(1,0)); #set direction 0
ok($g->has_Direction0, "True Direction0 predicate");
ok(agree($g->GNorm->(:,(0),(0)),pdl(1,0)), "Normalized G=0 reciprocal vector");
ok(agree($g->GNorm->(:,(5),(5)),pdl(1,1)/sqrt(2)),
   "Normalized reciprocal vector at center");
ok(agree($g->GNorm->(:,(0),(0)),pdl(1,0)), "Normalized G=-0 reciprocal vector");
ok(agree($g->mGNorm->(:,(5),(5)),-pdl(1,1)/sqrt(2)),
   "-normalized reciprocal vector at center");
ok(agree($g->GNorm->(:,(0),(0)), $g->pmGNorm->(:,(0),(0),(0)))
    && agree($g->mGNorm->(:,(0),(0)), $g->pmGNorm->(:,(1),(0),(0))),
    "spinor normalized G at corner");
ok(agree($g->GNorm->(:,(5),(5)), $g->pmGNorm->(:,(0),(5),(5)))
    && agree($g->mGNorm->(:,(5),(5)), $g->pmGNorm->(:,(1),(5),(5))),
    "spinor normalized G at center");
ok($g->f==$B->sum/(11*11), "filling fraction");
ok(agree($g->unitPairs, pdl([1,0], pdl(1,1)/sqrt(2), [0,1])), "unitpairs");
my $got = $g->cUnitPairs;
my $expected = czip(identity(2)->dog)/sqrt(2);
ok(Cagree($got, $expected), "cunitpairs")
  or diag "got:$got\nexpected:$expected";
ok(agree($g->unitDyads, pdl([1,0,0],[.5,1,.5],[0,0,1])), "unitDyads");

$got = lu_solve($g->unitDyadsLU, $g->unitDyads->transpose->r2C);
ok(Cagree($got, identity(3)), "unitDyadsLU");

ok(agree($g->Vec2LC_G(zeroes(11,11)->ndcoords->r2C)->re,
	 (zeroes(11,11)->ndcoords*$g->GNorm)->sumover),
   "Vec2LC");
ok(agree($g->LC2Vec_G(ones(11,11)->r2C)->re, $g->GNorm), "LC2Vec_G");

SKIP: {
     skip "image converter not found", 7 unless rpiccan("PNG");
     my $gw=Photonic::Geometry::FromImage2D->new(path=>'data/white.png');
     ok(defined $gw, "Create geometry from Image");
     ok(all($gw->B==ones(11, 11)), "lazy-build B");
     ok($gw->npoints==11*11, "npoints");
     ok($gw->f==1, "filling fraction of white");
     my $gb=Photonic::Geometry::FromImage2D->new(path=>'data/black.png');
     ok($gb->f==0, "filling fraction of black");
     my $gbi=Photonic::Geometry::FromImage2D->new(
     path=>'data/black.png', inverted=>1);
     ok($gbi->f==1, "filling fraction of inverted black");
     my $gh=Photonic::Geometry::FromImage2D->new(path=>'data/half.png');
     ok($gh->f==0.5, "filling fraction of half/half");
}
my $eps=r2C(zeroes(11,11));
my $ge=Photonic::Geometry::FromEpsilon->new(epsilon=>$eps);
ok(defined $ge, "Create geometry from epsilon");
is($ge->ndims, 2, "Number of dimensions");
ok(agree(pdl($ge->dims),pdl(11,11)), "Size of each dimension");

done_testing;
