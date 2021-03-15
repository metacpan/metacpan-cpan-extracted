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
use Photonic::Geometry::FromEpsilon;
use Photonic::WE::S::Metric;
use Photonic::WE::S::AllH;

use Test::More tests => 16;
use lib 't/lib';
use TestUtils;

my $fn = make_fn();
make_default_store($fn);

#Check haydock coefficients for simple 1D system
my ($ea, $eb)=(1+2*i, 3+4*i);
my $f=6/11;
my $eps=$ea*(zeroes(11)->xvals<5)+ $eb*(zeroes(11)->xvals>=5)+0*i;
my $g=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps);
my $m=Photonic::WE::S::Metric->new(
    geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl(2), wavevector=>pdl([1])
    );
my $a=Photonic::WE::S::AllH->new(metric=>$m,
   polarization=>pdl([1])->r2C, nh=>10);
$a->run;
my $as=$a->as;
my $bs=$a->bs;
my $b2s=$a->b2s;
is($a->iteration, 2, "Number of iterations 1D longitudinal x");
ok(Cagree(($b2s->[0]), 1), "1D L b_0^2");
ok(Cagree(($b2s->[1]), ($eb-$ea)**2*$f*(1-$f)), "1D L b_1^2");
ok(Cagree(($as->[0]), (1-$ea)*(1-$f)+(1-$eb)*$f), "1D L a_0");
ok(Cagree(($as->[1]), (1-$ea)*$f+(1-$eb)*(1-$f)), "1D L a_1");
ok(Cagree(pdl($b2s)->mv(-1,1)->complex, pdl($bs)->mv(-1,1)->complex**2),
	"1D L b2==b^2");

#Check haydock coefficients for simple 1D system other longitudinal y
my $eps1l=$ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11,1)->xvals>=5)+0*i;
my $g1l=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps1l);
my $m1l=Photonic::WE::S::Metric->new(
    geometry=>$g1l, epsilon=>pdl(1), wavenumber=>pdl(.0002),
    wavevector=>pdl([0,.000001])
    );
my $a1l=Photonic::WE::S::AllH->new(metric=>$m1l,
   polarization=>pdl([0,1])->r2C, nh=>10, smallH=>1e-4);
$a1l->run;
my $as1l=$a1l->as;
my $bs1l=$a1l->bs;
my $b2s1l=$a1l->b2s;
is($a1l->iteration, 1, "Number of iterations 1D long y");
ok(Cagree(($b2s1l->[0]), 1), "1D L b_0^2");
ok(Cagree(($as1l->[0]), (1-$ea)*(1-$f)+(1-$eb)*$f), "1D L a_0");

#Check haydock coefficients for simple 1D system transverse prop x pol y
my $epst=$ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11,1)->xvals>=5)+0*i;
my $gt=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$epst);
my $mt=Photonic::WE::S::Metric->new(
    geometry=>$gt, epsilon=>pdl(1), wavenumber=>pdl(.0002),
    wavevector=>pdl([.000001,0])
    );
my $at=Photonic::WE::S::AllH->new(metric=>$mt,
   polarization=>pdl([0,1])->r2C, nh=>10, smallH=>1e-4);
$at->run;
my $ast=$at->as;
my $bst=$at->bs;
my $b2st=$at->b2s;
is($at->iteration, 1, "Number of iterations 1D trans");
ok(Cagree(($b2st->[0]), 1), "1D L b_0^2");
ok(Cagree(($ast->[0]), (1-$ea)*(1-$f)+(1-$eb)*$f), "1D L a_0");

#check reorthogonalize with square array
my $Bs=zeroes(9,9)->rvals<4;
my $epss=r2C((1-$Bs)+5*$Bs);
my $gs=Photonic::Geometry::FromEpsilon->new(epsilon=>$epss, L=>pdl(1,1));
my $ms=Photonic::WE::S::Metric->new(geometry=>$gs, epsilon=>pdl(1),
   wavenumber=>pdl(.01), wavevector=>pdl([.001,0]));
my $als=Photonic::WE::S::AllH
    ->new(metric=>$ms, polarization=>r2C(pdl([0,1])), nh=>2*9*9,
    reorthogonalize=>1, accuracy=>machine_epsilon(),
    noise=>1e1*machine_epsilon(), normOp=>1e0, smallH=>1e-7);
$als->run;
ok($als->iteration < 2*9*9,
   "No more iterations than dimensions. Square. Long wavelength.");
diag("Actual iterations: " . $als->iteration
     . " Actual orthogonalizations: ", $als->orthogonalizations);

{
    #check reorthogonalize with even numbers
    my $Be=zeroes(10,10)->rvals<4;
    my $epse=r2C((1-$Be)+5*$Be);
    my $ge=Photonic::Geometry::FromEpsilon->new(epsilon=>$epse, L=>pdl(1,1));
    my $me=Photonic::WE::S::Metric->new(
	geometry=>$ge, epsilon=>pdl(1),	wavenumber=>pdl(.01),
	wavevector=>pdl([.001,0]));
    my $ale=Photonic::WE::S::AllH
	->new(metric=>$me, polarization=>r2C(pdl([0,1])), nh=>2*15*15,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e1*machine_epsilon(), normOp=>1e0, smallH=>1e-7,
	      use_mask=>1);
    $ale->run;
    ok($ale->iteration < 2*10*10,
       "No more iterations than dimensions. Square. Long wavelength. Even.");
    diag("Actual iterations: " . $ale->iteration
	 . " Actual orthogonalizations: ", $ale->orthogonalizations);
}

{
    #check reorthogonalize with even numbers
    my $Be=zeroes(10,10)->rvals<4;
    my $epse=r2C((1-$Be)+5*$Be);
    my $ge=Photonic::Geometry::FromEpsilon->new(epsilon=>$epse, L=>pdl(1,1));
    my $me=Photonic::WE::S::Metric->new(
	geometry=>$ge, epsilon=>pdl(1),	wavenumber=>pdl(3.6),
	wavevector=>pdl([1.01*3.6,0]));
    my $ale=Photonic::WE::S::AllH
	->new(metric=>$me, polarization=>r2C(pdl([0,1])), nh=>2*15*15,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e1*machine_epsilon(), normOp=>1e0, smallH=>1e-7,
	      use_mask=>1);
    $ale->run;
    ok($ale->iteration < 2*10*10,
       "No more iterations than dimensions. Square. Short wavelength. Even.");
    diag("Actual iterations: " . $ale->iteration
	 . " Actual orthogonalizations: ", $ale->orthogonalizations);
}

{
    #check reorthogonalize with even numbers
    my $Be=zeroes(10,10)->rvals<4;
    my $epse=r2C((1-$Be)+5*$Be);
    my $ge=Photonic::Geometry::FromEpsilon->new(epsilon=>$epse, L=>pdl(1,1));
    my $me=Photonic::WE::S::Metric->new(
	geometry=>$ge, epsilon=>pdl(1),	wavenumber=>pdl(3.6),
	wavevector=>pdl([1.01*3.6,0]));
    my $ale=Photonic::WE::S::AllH
	->new(metric=>$me, polarization=>r2C(pdl([0,1])), nh=>2*15*15,
	      reorthogonalize=>1, accuracy=>machine_epsilon(),
	      noise=>1e1*machine_epsilon(), normOp=>1e0, smallH=>1e-7,
	      use_mask=>1, stateFN=>$fn);
    $ale->run;
    ok($ale->iteration < 2*10*10,
    "No more iterations than dimensions. Square. Short wavelength. Even. Disk");
    diag("Actual iterations: " . $ale->iteration
	 . " Actual orthogonalizations: ", $ale->orthogonalizations);
}

__END__

#check reorthogonalize again with square array
my $B1s=zeroes(21,21)->rvals>2; #21,21, 2
my $eps1s=r2C(10*(1-$B1s)+1*$B1s);
my $g1s=Photonic::Geometry::FromEpsilon->new(epsilon=>$eps1s, L=>pdl(1,1));
my $m1s=Photonic::WE::S::Metric->new(geometry=>$g1s, epsilon=>pdl(10),
   wavenumber=>pdl(3.6), wavevector=>pdl([1.01*3.6,0]));
my $al1s=Photonic::WE::S::AllH
    ->new(metric=>$m1s, polarization=>r2C(pdl([0,1])), nh=>3*21*21,
    reorthogonalize=>1, accuracy=>machine_epsilon(),
    noise=>1e3*machine_epsilon(), normOp=>1e0, smallH=>1e-7);
$al1s->run;
ok($al1s->iteration <= 2*21*21, "No more iterations than dimensions");
diag("Actual iterations: " . $al1s->iteration
     . " Actual orthogonalizations: ", $al1s->orthogonalizations);


#foreach(@$st){
#    my $pr=$als->innerProduct($_, $st->[0]);
#    print "$pr\n";
#}

