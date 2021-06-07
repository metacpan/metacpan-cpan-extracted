#!/usr/bin/env perl
# toroid.pl dielectric response of a tetragonal lattice of tori
# The tori lie on the x-y- plane
#
# Use example:
# ./toroid.pl -ratio 3 -fraction .3 -Nz 20 -Nxy 80 \
#    -eps_a 1 -eps_b 5 -eps_a 1 -eps_b 10 -eps_a 1 \
#     -eps_b 25 -Nh 100 -cores 4
# gets dielectric function of a torus formed by a disk of radius a
# that follows a circle of radius b with ratio b/a=3, filling fraction
# .3 using a tetragonal lattice of 80x80x20 cubic voxels for various
# combinations (eps_a, eps_b) of the dielectric functions of the host
# (a) and the tori (b) using 100 Haydock coefficients and trying to
# employ 4 cpu cores.

use strict;
use warnings;
use v5.12;
use Getopt::Long;
use Exporter::Renaming;
use List::Util Renaming=>[all=>'luall'];
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use PDL::Complex;
use Photonic::Geometry::FromB;
use Photonic::LE::NR2::AllH;
use Photonic::LE::NR2::EpsL;

my $ratio; # b/a for torus
my $fraction; # target filling fraction
my (@eps_a, @eps_b); # conductivities of medium and torus
my $Nxy; # seminumber of voxels along x and y
my $Nz;  # and along z. I assume cubic voxels
my $Nh; #Number of Haydock coefficients to use
my $cores; #Number of cores to use

my $options=q(
	'ratio=f'=>\$ratio,
	'fraction=f'=>\$fraction,
	'eps_a=f'=>\@eps_a,
	'eps_b=f'=>\@eps_b,
	'Nxy=i'=>\$Nxy,
	'Nz=i'=>\$Nz,
	'Nh=i'=>\$Nh,
	'cores=i'=>\$cores;
	);
my %options=(eval $options);
die "Bad option definition: $@" if $@;
GetOptions(
    %options
    )
    or usage($options, "Bad options");
usage($options, "Missing options")
     unless luall {defined $_}
     ($ratio, $fraction, @eps_a, @eps_b, $Nxy, $Nz, $Nh);
usage($options, "Missing eps") unless @eps_a>0 and @eps_a==@eps_b;
usage($options, "Voxel numbers should be possitive") unless luall {$_>0} ($Nxy, $Nz);
usage($options, "Ratio of large to small radius should be > 1") unless $ratio>=1;
set_autopthread_targ($cores) if defined $cores;;
my ($Nxy2, $Nz2)=(2*$Nxy+1, 2*$Nz+1);
my $unit_cell_volume=$Nxy2*$Nxy2*$Nz2;

my $small_radius=($fraction*$unit_cell_volume/(2*PI**2*$ratio))**(1/3);
my $large_radius=$ratio*$small_radius;
warn "Tori overlap" if $small_radius>$Nz or $large_radius+$small_radius>$Nxy;

my $r=zeroes($Nxy2, $Nxy2, $Nz2)->ndcoords-pdl($Nxy, $Nxy, $Nz); #positions array
my $B=(sqrt($r((0))**2+$r((1))**2)-$large_radius)**2+$r((2))**2 < $small_radius**2;
my $gx=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl(1,0,0));
my $gz=Photonic::Geometry::FromB->new(B=>$B, Direction0=>pdl(0,0,1));
my $nrx=Photonic::LE::NR2::AllH->new(geometry=>$gx, nh=>$Nh);
my $nrz=Photonic::LE::NR2::AllH->new(geometry=>$gz, nh=>$Nh);
my $epsx_calc=Photonic::LE::NR2::EpsL->new(nr=>$nrx, nh=>$Nh);
my $epsz_calc=Photonic::LE::NR2::EpsL->new(nr=>$nrz, nh=>$Nh);
say "#ratio Nxy Nz Nh f-nom f-act medium torus epsxx epszz";
foreach(0..@eps_a-1){
    my ($ea, $eb)=(pdl($eps_a[$_])->r2C, pdl($eps_b[$_])->r2C);
    my $resultx=$epsx_calc->evaluate($ea, $eb);
    my $resultz=$epsz_calc->evaluate($ea, $eb);
    say sprintf "%.4f %d %d %d %.4f %.4f %.4f %.4f %.4f %.4f",
    $ratio, $Nxy, $Nz, $Nh, $fraction, $gx->f, $ea->re, $eb->re,
    $resultx->re, $resultz->re;
    say "x-no-covergió" unless $epsx_calc->converged;
    say "z-no-covergió" unless $epsz_calc->converged;
}

sub usage { # quick to write, but not too useful for others
    my ($options, $message)=@_;
    say $message;
    say $options;
    die;
}
