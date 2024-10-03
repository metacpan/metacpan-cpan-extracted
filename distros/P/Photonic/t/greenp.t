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
use Photonic::Geometry::FromEpsilon;
use Photonic::WE::S::Metric;
use Photonic::WE::S::Haydock;
use Photonic::WE::S::GreenP;
use Photonic::Geometry::FromEpsilonTensor;
use Photonic::WE::ST::Metric;
use Photonic::WE::ST::Haydock;
use Photonic::WE::ST::GreenP;

use Test::More;
use lib 't/lib';
use TestUtils;

#Check greenp for simple 1D system
my ($ea, $eb)=(r2C(1), r2C(2));
my $f=6/11;
{
    my $eps=$ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11,1)->xvals>=5);
    my $g=Photonic::Geometry::FromEpsilon
	->new(epsilon=>$eps);
    my $m=Photonic::WE::S::Metric->new(
	geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl(2e-5),
	wavevector=>pdl([1,0])*1e-8);
    my $a=Photonic::WE::S::Haydock->new(metric=>$m,
       polarization=>pdl([1,0])->r2C, nh=>10);
    my $gr=Photonic::WE::S::GreenP->new(nh=>10, haydock=>$a);
    my $grv=$gr->Gpp;
    ok(Cagree($grv, ($f/$eb+(1-$f)/$ea)),  "1D long non retarded limit WE::S")
        or diag "got:$grv";
    $a=Photonic::WE::S::Haydock->new(metric=>$m,
       polarization=>pdl([0,1])->r2C, nh=>10);
    $gr=Photonic::WE::S::GreenP->new(nh=>10, haydock=>$a);
    $grv=$gr->Gpp;
    ok(Cagree($grv, 1/($f*$eb+(1-$f)*$ea)), "1D transverse non retarded limit WE::S")
        or diag "got:$grv";
}
{
    my $eps=($ea*(zeroes(11,1)->xvals<5)+ $eb*(zeroes(11,1)->xvals>=5))->slice("*1,*1")*identity(2);
    my $g=Photonic::Geometry::FromEpsilonTensor
	->new(epsilon=>$eps);
    my $m=Photonic::WE::ST::Metric->new(
	geometry=>$g, epsilon=>pdl(1), wavenumber=>pdl(2e-5),
	wavevector=>pdl([1,0])*1e-8);
    my $a=Photonic::WE::ST::Haydock->new(metric=>$m,
       polarization=>pdl([1,0])->r2C, nh=>10);
    my $gr=Photonic::WE::ST::GreenP->new(nh=>10, haydock=>$a);
    my $grv=$gr->Gpp;
    ok(Cagree($grv, ($f/$eb+(1-$f)/$ea)),  "1D long non retarded limit WE::ST")
        or diag "got:$grv";
    $a=Photonic::WE::ST::Haydock->new(metric=>$m,
       polarization=>pdl([0,1])->r2C, nh=>10);
    $gr=Photonic::WE::ST::GreenP->new(nh=>10, haydock=>$a);
    $grv=$gr->Gpp;
    ok(Cagree($grv, 1/($f*$eb+(1-$f)*$ea)), "1D transverse non retarded limit WE::ST")
        or diag "got:$grv";
}
done_testing;
