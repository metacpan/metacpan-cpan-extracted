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
use PDL::Complex;
use Photonic::WE::R2::Metric;
use Photonic::WE::R2::AllH;

use Test::More tests => 10;
use lib 't/lib';
use TestUtils;

my $fn = make_fn();
make_default_store($fn);

#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $g=Photonic::Geometry::FromB->new(B=>$B); #long
my $m=Photonic::WE::R2::Metric->new(geometry=>$g, epsilon=>pdl(1),
   wavenumber=>pdl(1), wavevector=>pdl([0.01]));
my $a=Photonic::WE::R2::AllH->new(metric=>$m,
   polarization=>pdl([1])->r2C, nh=>10);
$a->run;
my $as=$a->as;
my $bs=$a->bs;
my $b2s=$a->b2s;
ok(agree(pdl($a->iteration), 2), "Number of iterations 1D longitudinal");
ok(agree(pdl($b2s->[0]), 1), "1D L b_0^2");
ok(agree(pdl($b2s->[1]), $g->f*(1-$g->f)), "1D L b_1^2");
ok(agree(pdl($as->[0]), $g->f), "1D L a_0");
ok(agree(pdl($as->[1]), 1-$g->f), "1D L a_1");
ok(agree(pdl($b2s), pdl($bs)**2), "1D L b2==b^2");

{
    #check reorthogonalize with square array
    my $Bs=zeroes(15,15)->rvals<5;
    my $gs=Photonic::Geometry::FromB->new(B=>$Bs);
    my $ms=Photonic::WE::R2::Metric->new(
	geometry=>$gs, epsilon=>pdl(1), wavenumber=>pdl(.01),
	wavevector=>pdl([.001,0]));
    my $als=Photonic::WE::R2::AllH
	->new(metric=>$ms, polarization=>r2C(pdl([0,1])), nh=>2*15*15,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e0*machine_epsilon(), normOp=>1e0, smallH=>1e-7);
    $als->run;
    ok($als->iteration <= 15*15,
       "No more iterations than dimensions. Long wavelength.");
    diag("Actual iterations: " . $als->iteration
	 . " Actual orthogonalizations: ", $als->orthogonalizations);
}
{
    #check reorthogonalize again with square array
    my $B1s=zeroes(21,21)->rvals>2; #21,21, 2
    my $g1s=Photonic::Geometry::FromB->new(B=>$B1s, L=>pdl(1,1));
    my $m1s=Photonic::WE::R2::Metric->new(
	geometry=>$g1s, epsilon=>pdl(10), wavenumber=>pdl(3.6),
	wavevector=>pdl([1.01*3.6,0]));
    my $al1s=Photonic::WE::R2::AllH
	->new(metric=>$m1s, polarization=>r2C(pdl([0,1])), nh=>3*21*21,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e3*machine_epsilon(), normOp=>1e0, smallH=>1e-7);
    $al1s->run;
    ok($al1s->iteration <= 2*21*21,
       "No more iterations than dimensions. Small wavelength.");
    diag("Actual iterations: " . $al1s->iteration
	 . " Actual orthogonalizations: ", $al1s->orthogonalizations);
}
{
    #check reorthogonalize again with square array even number
    my $B2s=zeroes(10,10)->rvals>4;
    my $g2s=Photonic::Geometry::FromB->new(B=>$B2s, L=>pdl(1,1));
    my $m2s=Photonic::WE::R2::Metric->new(
	geometry=>$g2s, epsilon=>pdl(10), wavenumber=>pdl(3.6),
	wavevector=>pdl([1.01*3.6,0]));
    my $al2s=Photonic::WE::R2::AllH
	->new(metric=>$m2s, polarization=>r2C(pdl([0,1])), nh=>3*10*10,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e0*machine_epsilon(), normOp=>1e0, smallH=>1e-7,
	      use_mask=>1);
    $al2s->run;
    ok($al2s->iteration <= 2*10*10,
       "No more iterations than dimensions. Small wavelength. Even.");
    diag("Actual iterations: " . $al2s->iteration
	 . " Actual orthogonalizations: ", $al2s->orthogonalizations);
}
{
    #check reorthogonalize again with square array even number
    my $B2s=zeroes(10,10)->rvals>4;
    my $g2s=Photonic::Geometry::FromB->new(B=>$B2s, L=>pdl(1,1));
    my $m2s=Photonic::WE::R2::Metric->new(
	geometry=>$g2s, epsilon=>pdl(10), wavenumber=>pdl(3.6),
	wavevector=>pdl([1.01*3.6,0]));
    my $al2s=Photonic::WE::R2::AllH
	->new(metric=>$m2s, polarization=>r2C(pdl([0,1])), nh=>3*10*10,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e0*machine_epsilon(), normOp=>1e0, smallH=>1e-7,
	      use_mask=>1, stateFN=>$fn);
    $al2s->run;
    ok($al2s->iteration <= 2*10*10,
       "No more iterations than dimensions. Small wavelength. Even. Disk.");
    diag("Actual iterations: " . $al2s->iteration
	 . " Actual orthogonalizations: ", $al2s->orthogonalizations);
}
