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
use Photonic::Iterator;

use Test::More;
use lib 't/lib';
use TestUtils;

my $fn = make_fn();
make_default_store($fn);

{
    #Check haydock coefficients for simple 1D system
    my $B=zeroes(11,1)->xvals<5; #1D system
    my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1,0])); #long
    my $ad=Photonic::LE::NR2::Haydock->new(
	geometry=>$g, nh=>10, stateFN=>$fn, keepStates=>1);
    $ad->run;
    my $itd=$ad->state_iterator;
    is $itd->iterator, $itd;
    my $am=Photonic::LE::NR2::Haydock->new(geometry=>$g, nh=>10, keepStates=>1);
    $am->run;
    my $itm=$am->state_iterator;
    my $n=0;
    while(defined(my $d=$itd->nextval)){
	ok(defined(my $m=$itm->nextval),
	   "State $n defined in memory and disk. 1D long.");
	ok(Cagree($d, $m), "State $n in memory agree with disk. 1D long.");
	++$n;
    }
    ok(!defined(my $m=$itm->nextval),
	"Same num. of states in memory and disk. 1D long");
}
{
    #Check haydock coefficients for simple 1D system
    my $B=zeroes(11,1)->xvals<5; #1D system
    my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([0,1])); #trans
    my $ad=Photonic::LE::NR2::Haydock->new(
	geometry=>$g, nh=>10, stateFN=>$fn, keepStates=>1);
    $ad->run;
    my $itd=$ad->state_iterator;
    my $am=Photonic::LE::NR2::Haydock->new(geometry=>$g, nh=>10, keepStates=>1);
    $am->run;
    my $itm=$am->state_iterator;
    my $n=0;
    while(defined(my $d=$itd->nextval)){
	ok(defined(my $m=$itm->nextval),
	   "State $n defined in memory and disk. 1D trans.");
	ok(Cagree($d, $m), "State $n in memory agree with disk. 1D trans.");
	++$n;
    }
    ok(!defined(my $m=$itm->nextval),
	"Same num. of states in memory and disk. 1D trans.");
}
done_testing;
