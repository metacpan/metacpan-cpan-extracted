#!/usr/bin/env perl
# Calculate and plot the macroscopic response of a honeycomb lattice of metallic cylinders
use warnings;
use strict;
use v5.12;
use Getopt::Long;
use List::Util qw(reduce);
use IO::Prompter;
use PDL;
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot;
use Photonic 0.020;
use Photonic::Utils qw(tile);
use Photonic::Geometry::FromB;
use Photonic::LE::NR2::Haydock;
use Photonic::LE::NR2::EpsTensor;
my $N; # 2N+1 is number of pixels along x
my $epsa; # dielectric function of host
my $tau; # drude lifetime, normalized to w_p=1
my ($wmin, $wmax, $Nw); # Min, max and number of frequencies.
my $radius; # radius of cylinders
my $nh; # number of Haydock coefficients to use

my $options=q(
      'N=i'=>\$N, # 2N+1=unit cell pixels
      'epsa=f'=>\$epsa, # dielectric function of host
      'tau=f'=>\$tau, # Drude lifetime
      'wmin=f'=>\$wmin, # minimum frequency
      'wmax=f'=>\$wmax, # maximum frequency
      'Nw=i'=>\$Nw, # Number of frequencies
      'radius=f'=>\$radius, # radius of cylinders
      'nh=i'=>\$nh, # number of Haydock coefficients to use
);
my %options=(eval $options);
die "Bad option definition; $@" if $@;
GetOptions(%options) or usage($options, "Bad options");
usage($options, "Undefined parameters")
   unless List::Util::all
	 {defined $_}
	 ($N, $epsa, $tau, $wmin, $wmax, $Nw, $radius, $nh);
$epsa=r2C($epsa); #make complex
my $w=zeroes($Nw)->xlinvals($wmin, $wmax);
my $epsb=1-1/($w*($w+i()/$tau)); # Drude
my $lattice_name="Honeycomb lattice";
my $pi=atan2(1,1)*4;
my $r1=pdl(1,tan($pi/6));
my $N2=2*$N+1; # pixels of cell;
my $units=pdl[[1,0], [1/2, sqrt(3)/2]];
my $L=pdl(1,1);
my $B=zeroes($N2+1, $N2+1);
# $B->ndcoords has indices a,n,m, with a=0,1 numbering primitive
# vectors and n,m numbering pixels
# $units has coordinates i,a with i Cartesian indices and a numering
# primitive vectors. Thus, to sum over a we have to transpose units
# and add a dummy index (i) to $B->ndcoords
my $r=($B->ndcoords->dummy(1)/$N2*$units->mv(1,0))->sumover; # coordinates
$B= reduce { $a|$b } # distance to corners smaller than radius
map {($r-$r(:,$_->[0], $_->[1]))->abs2->sumover<$radius**2}
([0,0], [$N2,0], [$N2, $N2], [0,$N2]);
$B |= ($r-$r1)->abs2->sumover<$radius**2; # center particle
$B=$B(0:-2, 0:-2); # remove redundant edges
# Initialize a geometry
my $g=Photonic::Geometry::FromB->new(B=>$B, L=>$L, units=>$units);
my $epsM=epst($g, $nh, $epsa, $epsb);
sub epst {
my ($geometry, $nh, $epsa, $epsb)=@_;
my $epst=null;
my $haydock;
_epst($epsa, $epsb, $epst, $geometry, $haydock, $nh);
$epst;
}

BEGIN {
thread_define '_epst(epsa();epsb();[o]epst(n=2,n=2)), NOtherPars=>3'
=> over {
  my ($epsa, $epsb, $epst, $geometry, $haydock, $nh)=@_;
  if(defined $haydock){
      $epst.=Photonic::LE::NR2::EpsTensor->new(
	  geometry=>$geometry, epsA=>$epsa, epsB=>$epsb,
	  haydock=>$haydock, nh=>$nh, reorthogonalize=>1
	  )->epsTensor;
  }else{
      my $epsObj=Photonic::LE::NR2::EpsTensor->new(
	  geometry=>$geometry, epsA=>$epsa, epsB=>$epsb, nh=>$nh,
	  reorthogonalize=>1);
      my $rem=$epsObj->epsTensor;
      $epst.=$epsObj->epsTensor;
      $haydock=$epsObj->haydock;
      $_[4]=$haydock; # Modify argument for next threaded calls!
  }
};
}
my $f=$g->f; # filling fraction
my $epsMG=$epsa*($epsa*(1-$f)+$epsb*(1+$f))
      /($epsa*(1+$f)+$epsb*(1-$f));
# Plot the characteristic function
my $gp=PDL::Graphics::Gnuplot->new;
my $B_tiled=tile($B, 3,3);
my $r_tiled=($B_tiled->ndcoords->dummy(1)/$N2*$units->mv(1,0))->sumover;
$gp->plot({title=>"$lattice_name, r=$radius, N=$N",
	 colorbox=>0, justify=>1},
      with=>'image', $r_tiled((0)), $r_tiled((1)), $B_tiled);
prompt -void, -single, "Ready?";
# Plot the macroscopic response
$gp->plot({title=>"Macroscopic response, $lattice_name, r=$radius, N=$N, nh=$nh",
       xlabel=>"Frequency {/Symbol w}",
       ylabel=>"Macroscopic response {/Symbol e}_M"},
      {legend=>'xx re', with=>'lines'},
       $w, $epsM((0),(0))->re,
      {legend=>'yy re', with=>'lines'},
       with=>'lines', $w, $epsM((1),(1))->re,
      {legend=>'xy re', with=>'lines'},
	with=>'lines', $w, $epsM((0),(1))->re,
      {legend=>'MG re', with=>'lines'},
	with=>'lines', $w, $epsMG->re,
      {legend=>'xx im', with=>'lines'},
	with=>'lines', $w, $epsM((0),(0))->im,
      {legend=>'yy im', with=>'lines'},
	with=>'lines', $w, $epsM((1),(1))->im,
      {legend=>'xy im', with=>'lines'},
	with=>'lines', $w, $epsM((0),(1))->im,
      {legend=>'MG im', with=>'lines'},
	with=>'lines', $w, $epsMG->im);
prompt -void, -single, "Ready?";
sub usage {
  my ($options, $message)=@_;
  say $message if defined $message;
  say $options;
  exit 1;
}
