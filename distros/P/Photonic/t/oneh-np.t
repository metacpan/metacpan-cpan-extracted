=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

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
use PDL::Complex;
use Photonic::Geometry::FromEpsilon;
use Photonic::LE::NP::OneH;

use Test::More tests => 4;

#my $pi=4*atan2(1,1);

sub Cagree {
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)->Cabs2)->sum<=1e-7;
}

#Check haydock coefficients for simple 1D system
#1D system e=1 or 2
my ($ea, $eb)=(1+2*i, 3+4*i);
my $f=6/11;
my $eps=$ea*(zeroes(11)->xvals<5)+ $eb*(zeroes(11)->xvals>=5)+0*i;
my $g=Photonic::Geometry::FromEpsilon
    ->new(epsilon=>$eps, Direction0=>pdl([1]));
my $o=Photonic::LE::NP::OneH->new(geometry=>$g);
$o->iterate;
ok(Cagree(pdl($o->current_a), $ea*(1-$f)+$eb*$f), "1D a_0");
ok(Cagree(pdl($o->next_b2), ($eb-$ea)**2*$f*(1-$f)), "1D b_1^2");
$o->iterate;
ok(Cagree(pdl($o->current_a), $ea*$f+$eb*(1-$f)), "1D a_1");
ok(Cagree(pdl($o->next_b2), 0), "1D b_2^2");
