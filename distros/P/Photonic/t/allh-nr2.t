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

use Test::More;
use lib 't/lib';
use TestUtils;

my $fn = make_fn();

#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
my $a=Photonic::LE::NR2::Haydock->new(geometry=>$g, nh=>10);
$a->run;
my $as=$a->as;
my $bs=$a->bs;
my $b2s=$a->b2s;
ok(agree(pdl($a->iteration), 2), "Number of iterations 1D longitudinal");
ok(agree($b2s, pdl([1, $g->f*(1-$g->f)])), "1D L b^2");
ok(agree($as, pdl([$g->f, 1-$g->f])), "1D L a");
ok(agree($b2s, $bs**2), "1D L b2==b^2");

#View 1D system as 2D. Transverse direction
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $gt=Photonic::Geometry::FromB->new(B=>$Bt, Direction0=>pdl([1,0])); #trans
my $at=Photonic::LE::NR2::Haydock->new(geometry=>$gt, nh=>10);
$at->run;
my $ast=$a->as;
my $bst=$a->bs;
my $b2st=$a->b2s;
ok(agree(pdl($at->iteration), 1), "Number of iterations 1D trans");
ok(agree($b2st->slice("(0)"), 1), "1D T b_0^2");
ok(agree($ast->slice("(0)"), $g->f), "1D T a_0");
ok(agree($b2st, $bst**2), "1D T b2==b^2");

{
    #check reorthogonalize with square array
    my $Bs=zeroes(15,15)->rvals<5;
    my $gs=Photonic::Geometry::FromB->new(B=>$Bs, Direction0=>pdl([1,0]));
    my $als=Photonic::LE::NR2::Haydock
	->new(geometry=>$gs, nh=>2*15*15, reorthogonalize=>1,
	      accuracy=>machine_epsilon(), noise=>machine_epsilon(),
	      normOp=>1);
    $als->run;
    ok($als->iteration <= 15*15,
       "No more iterations than dimensions. Square. States in mem.");
    diag("Actual iterations: " . $als->iteration
	 . " Actual orthogonalizations: ", $als->orthogonalizations);
}
{
    #check reorthogonalize with square array. Data in file.
    my $Bs=zeroes(15,15)->rvals<5;
    my $gs=Photonic::Geometry::FromB->new(B=>$Bs, Direction0=>pdl([1,0]));
    my $als=Photonic::LE::NR2::Haydock
	->new(geometry=>$gs, nh=>2*15*15, reorthogonalize=>1,
	      accuracy=>machine_epsilon(), noise=>machine_epsilon(),
	      normOp=>1, stateFN=>$fn);
    $als->run;
    ok($als->iteration <= 15*15,
       "No more iterations than dimensions. Square. States in file");
    diag("Actual iterations: " . $als->iteration
	 . " Actual orthogonalizations: ", $als->orthogonalizations);
}

done_testing;
