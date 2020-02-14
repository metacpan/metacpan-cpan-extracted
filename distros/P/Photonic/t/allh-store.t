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

#Check that the values and states retrived from a file by AllH coincide
#with those kept in memory.

use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Complex;
use Storable qw(fd_retrieve);
use PDL::IO::Storable;
use Data::Dumper;
use Photonic::Geometry::FromB;
use Photonic::LE::NR2::AllH;
use Photonic::Utils qw(HProd);
use Photonic::Iterator;

use Machine::Epsilon;
use List::Util;

use Test::More ;# tests => 12;

#my $pi=4*atan2(1,1);

sub agree {
    my $a=shift;
    my $b=shift//0;
    return (($a-$b)*($a-$b))->sum<=1e-7;
}

{
    #Check haydock coefficients for simple 1D system
    my $fn="scratch/remStore.dat"; #output file name
    my $B=zeroes(11)->xvals<5; #1D system
    my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
    my $a=Photonic::LE::NR2::AllH->new(geometry=>$g, nh=>10,
				       keepStates=>1, storeAllFN=>$fn);
    $a->run;
    my $fh=IO::File->new($fn, "r") or die "Couldn't open $fn: $!";
    my $all=fd_retrieve($fh);
    is($all->{iteration}, $a->iteration,
       "Number of iterations 1D longitudinal");
    foreach(qw(as bs b2s cs bcs gs)){
	ok(agree(pdl($all->{$_}), pdl($a->$_)), "1D L $_");
    }
    my $si=$a->state_iterator;
    my (@readstates, @savedstates);
    foreach(0..$all->{iteration}-1){
	push @readstates, fd_retrieve($fh);
	push @savedstates, $si->nextval;
    }
    ok(agree(pdl(@readstates), pdl(@savedstates)), "1D L states");
}

{
    #full restore allh from previous calculation
    my $fn="scratch/remStore.dat"; #output file name
    my $B=zeroes(11)->xvals<5; #1D system
    my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
    my $a=Photonic::LE::NR2::AllH->new(geometry=>$g, nh=>10, loadAllFN=>$fn);
    $a->run;
    my $fh=IO::File->new($fn, "r") or die "Couldn't open $fn: $!";
    my $all=fd_retrieve($fh);
    is($all->{iteration}, $a->iteration,
       "Number of iterations 1D longitudinal");
    foreach(qw(as bs b2s cs bcs gs)){
	ok(agree(pdl($all->{$_}), pdl($a->$_)), "1D L restored $_");
    }
    my $si=$a->state_iterator;
    my (@readstates, @savedstates);
    foreach(0..$all->{iteration}-1){
	push @readstates, fd_retrieve($fh);
	push @savedstates, $si->nextval;
    }
    ok(agree(pdl(@readstates), pdl(@savedstates)), "1D L restored states");
}

{
    #partial restore allh from previous calculation
    my $fn="scratch/remStore.dat"; #output file name
    my $B=zeroes(11)->xvals<5; #1D system
    my $g=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl([1])); #long
    my $a=Photonic::LE::NR2::AllH->new(geometry=>$g, nh=>1,
				       keepStates=>1, storeAllFN=>$fn);
    $a->run;
    is($a->iteration, 1, "Can stop before exhausting coefficients 1D L");
    my $a2=Photonic::LE::NR2::AllH->new(geometry=>$g, nh=>10,
					keepStates=>1, loadAllFN=>$fn); 
    $a2->run;
    my $a3=Photonic::LE::NR2::AllH->new(geometry=>$g, nh=>10, keepStates=>1);
    $a3->run;
    foreach(qw(iteration as bs b2s cs bcs gs)){
	ok(agree(pdl($a2->$_), pdl($a3->$_)), "1D L retarted $_");
    }
    my $si2=$a2->state_iterator;
    my $si3=$a3->state_iterator;
    my (@states2, @states3);
    foreach(0..$a3->iteration-1){
	push @states2, $si2->nextval;
	push @states3, $si3->nextval;
    }
    ok(agree(pdl(@states2), pdl(@states3)), "1D L restored states");
}

{
    #View 1D system as 2D. Transverse direction
    my $fn="scratch/remStore.dat"; #output file name
    my $Bt=zeroes(1,11)->yvals<5; #2D flat system
    my $gt=Photonic::Geometry::FromB->new(B=>$Bt,
					  Direction0=>pdl([1,0])); #trans
    my $at=Photonic::LE::NR2::AllH->new(geometry=>$gt, nh=>10,
					keepStates=>1, storeAllFN=>$fn);
    $at->run;
    my $fh=IO::File->new($fn, "r") or die "Couldn't open $fn: $!";
    my $all=fd_retrieve($fh);
    is($all->{iteration}, $at->iteration, "Number of iterations 1D transverse");
    foreach(qw(as bs b2s cs bcs gs)){
	ok(agree(pdl($all->{$_}), pdl($at->$_)), "1D T $_");
    }
    my $si=$at->state_iterator;
    my (@readstates, @savedstates);
    foreach(0..$all->{iteration}-1){
	push @readstates, fd_retrieve($fh);
	push @savedstates, $si->nextval;
    }
    ok(agree(pdl(@readstates)->real, pdl(@savedstates)->real), "1D T states");
}

done_testing;
