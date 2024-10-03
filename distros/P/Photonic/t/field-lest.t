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
use Photonic::LE::ST::Haydock;
use Photonic::LE::ST::Field;

use Test::More tests => 4;
use lib 't/lib';
use TestUtils;

my $ea=1+2*i;
my $eb=3+4*i;
#Check field for simple 1D system
my $B=zeroes(11)->xvals<5; #1D system
my $epsilon=($ea*(1-$B)+$eb*$B)->slice("*1,*1"); # *identity(1);
my $gl=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
my $haydock=Photonic::LE::ST::Haydock->new(geometry=>$gl, nh=>10,
   keepStates=>1, epsilon=>$epsilon);
my $flo=Photonic::LE::ST::Field->new(haydock=>$haydock, nh=>10);
my $flv=$flo->field;
my $fle=$flo->epsL;
my $fla=1/$ea;
my $flb=1/$eb;
my $fproml=$fla*(1-$gl->f)+$flb*($gl->f);
my $flex=1/$fproml;
($fla, $flb)=map {$_/$fproml} ($fla, $flb);
my $flx=($fla*(1-$B)+$flb*$B)->slice("*1");
ok(Cagree($flv, $flx), "1D long field") or diag "got: $flv\nexpected: $flx";
ok(Cagree($fle, $flex), "1D long response") or diag "got: $fle\nexpected: $flex";

#View 2D from 1D superlattice.
my $Bt=zeroes(1,11)->yvals<5; #2D flat system
my $epsilont=($ea*(1-$Bt)+$eb*$Bt)->slice("*1,*1")*identity(2);
my $gt=Photonic::Geometry::FromB->new(B=>$Bt, Direction0=>pdl([1,0])); #trans
my $nt=Photonic::LE::ST::Haydock->new(geometry=>$gt, nh=>10,
				  keepStates=>1, epsilon=>$epsilont);
my $fto=Photonic::LE::ST::Field->new(haydock=>$nt, nh=>10);
my $ftv=$fto->field;
my $fte=$fto->epsL;
my $ftx=pdl([1, 0])->r2C;
ok(Cagree($ftv, $ftx), "1D trans field") or diag "got: $ftv\nexpected: $ftx";;
my $fpromt=$ea*(1-$gt->f)+$eb*($gt->f);
ok(Cagree($fte, $fpromt), "1D trans response") or diag "got: $fte\nexpected: $fpromt";
