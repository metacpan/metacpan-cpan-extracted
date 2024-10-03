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
use Photonic::WE::R2::Metric;
use Photonic::WE::S::Metric;
use Photonic::WE::ST::Metric;
use Test::More;
use lib 't/lib';
use TestUtils;

#my $pi=4*atan2(1,1);

my $B=zeroes(11)->xvals<5; #1D system
my $g=Photonic::Geometry::FromB->new(B=>$B);

my $gGG=Photonic::WE::R2::Metric->new(geometry=>$g, epsilon=>pdl(2),
   wavenumber=>pdl(1), wavevector=>pdl([1]));
my $v=$gGG->value;
ok($v->ndims==3,"Number of dimensions of metric for 1d");
ok(agree(pdl($v->dims),pdl(1,1,11)), "Actual dimensions of metric for 1d");
ok(agree($v, ones(1,1,11)), "Actual metric for 1d");

$B=zeroes(1,11)->xvals<5; #2D system
$g=Photonic::Geometry::FromB->new(B=>$B);

$gGG=Photonic::WE::R2::Metric->new(geometry=>$g, epsilon=>pdl(2),
   wavenumber=>pdl(1), wavevector=>pdl([0,1]));
$v=$gGG->value;
ok($v->ndims==4,"Number of dimensions of metric for 2d");
ok(agree(pdl($v->dims),pdl(2,2,1,11)), "Actual dimensions of metric for 2d");
ok(agree($v->((1),(1)), ones(1,11)),
			"Longitudinal component of metric in 2D");
ok(agree($v->((0),(0)), 2/(2-((pdl([0,1])+$g->G)**2)->sumover)),
			"Transverse component of metric in 2D");

my $gsGG=Photonic::WE::S::Metric->new(geometry=>$g, epsilon=>pdl(3),
   wavenumber=>pdl(1), wavevector=>pdl([1,1]));
my $vs=$gsGG->value;

my $gstGG=Photonic::WE::ST::Metric->new(geometry=>$g, epsilon=>pdl(3),
   wavenumber=>pdl(1), wavevector=>pdl([1,1]));
my $vst=$gstGG->value;

$gGG=Photonic::WE::R2::Metric->new(geometry=>$g, epsilon=>pdl(3),
   wavenumber=>pdl(1), wavevector=>pdl([1,1]));
$v=$gGG->value;
ok(agree($vs->(:,:,(0)), $v), "S and R2 metrics agree for k");
ok(agree($vst->(:,:,(0)), $v), "ST and R2 metrics agree for k");

$gGG=Photonic::WE::R2::Metric->new(geometry=>$g, epsilon=>pdl(3),
   wavenumber=>pdl(1), wavevector=>-pdl([1,1]));
$v=$gGG->value;
ok(agree($vs->(:,:,(1)), $v), "S and R2 metrics agree for -k");
ok(agree($vst->(:,:,(1)), $v), "ST and R2 metrics agree for -k");

done_testing;