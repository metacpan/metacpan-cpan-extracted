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
use PDL::Complex;
use Photonic::Geometry::FromB;
use Photonic::LE::NR2::OneH;
use Test::More;
use lib 't/lib';
use TestUtils;

#Check haydock coefficients for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1]));
my $o=Photonic::LE::NR2::OneH->new(geometry=>$g);
$o->iterate;
ok(agree(pdl($o->current_a), $g->f), "1D a_0") or diag "got=",$o->current_a, "\nexpected=", $g->f;
ok(agree(pdl($o->next_b2), $g->f*(1-$g->f)), "1D b_1^2");
$o->iterate;
ok(agree(pdl($o->current_a), 1-$g->f), "1D a_1");
ok(agree(pdl($o->next_b2), 0), "1D b_2^2");

my $x = zeroes(1, 2, 11)->r2C;
$x->slice(':,:,0') .= 1;
ok approx($o->magnitude($x), 3.3166247903554), "magnitude";

done_testing;
