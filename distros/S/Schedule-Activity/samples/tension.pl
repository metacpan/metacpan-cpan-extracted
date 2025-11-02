#!/usr/bin/perl

# This generates graphs of theoretical actions counts as:
#
# Let G=3000 be the goal time.
# Let t=30   be the action time.
# Let dt=10  be the slack/buffer time (equal in this example).
# Let s,r    be the slack/buffer tension.

use strict;
use warnings;
use GD;

sub distribution {
	my ($t,$G,$dt,$s,$r)=@_;
	my %pchart;
	$s=1-$s; $r=1-$r;
	foreach my $n (1..(2*$G/$t)) {
		my $lhs=($s+$r)*$n*$dt;
		my $rhs=$G-$n*$t+$s*$n*$dt;
		my $P;
		if($lhs<$rhs)  { $P=1 }
		elsif($rhs<=0) { $P=0 }
		else { $P=$rhs/$lhs }
		my $Q=1-$P;
		$pchart{$n}=$Q;
	}
	#
	my %res;
	my $leftover=1;
	foreach my $n (1..(2*$G/$t)) {
		if($pchart{$n}<=0) { next }
		if($leftover<=0)   { next }
		$res{$n}=$leftover*$pchart{$n};
		$leftover*=(1-$pchart{$n});
		if($leftover<1e-4) { $leftover=0 }
	}
	return %res;
}

sub drawdist {
	my ($im,$w,$h,$x,$y,$color,$C,$tslack,$tbuffer)=@_;
	my ($xmin,$xmax,$ymin,$ymax)=(75,125,0,0.3);
	my ($xrange,$yrange)=($xmax-$xmin,$ymax-$ymin);
	my $xp=sub { my ($xcoor)=@_; return $x+$w*($xcoor-$xmin)/$xrange };
	$im->rectangle($x,$y,$x+$w,$y-$h,$$color{black});
	$im->string(gdMediumBoldFont,&$xp($xmax)-73,$y-45,sprintf('slack %0.2f', $tslack), $$color{blue});
	$im->string(gdMediumBoldFont,&$xp($xmax)-80,$y-30,sprintf('buffer %0.2f',$tbuffer),$$color{blue});
	for(my $xv=$xmin+5;$xv<=$xmax-5;$xv+=10) { $im->line(&$xp($xv),$y,&$xp($xv),$y-5,$$color{black}) }
	if($y-$h>5) { for(my $xv=$xmin+5;$xv<=$xmax-5;$xv+=10) {
		$im->string(gdSmallFont,&$xp($xv)-2.7*length($xv),$y-$h,"$xv",$$color{black});
	} }
	my $poly=GD::Polygon->new();
	foreach my $xv ($xmin..$xmax) {
		my $yv=$$C{$xv}//0; if($yv>$ymax) { $yv=$ymax }
		$poly->addPt(&$xp($xv),$y-$h*($yv-$ymin)/$yrange);
	}
	$im->openPolygon($poly,$$color{black});
}

my ($ds,$dr)=(0.25,0.25);
my ($stepss,$stepsr)=(int(1/$ds),int(1/$dr));
my ($w,$h)=(200,200);
my ($W,$H)=($w*(1+$stepss),$h*(1+$stepsr));
my $im=GD::Image->new($W,$H);
my %color=(
	white=>$im->colorAllocate(255,255,255),
	black=>$im->colorAllocate(0,0,0),
	blue =>$im->colorAllocate(0,0,255),
);

my ($G,$t,$dt)=(3000,30,10);
foreach my $steps (0..$stepss) {
foreach my $stepr (0..$stepsr) {
	my ($s,$r)=($steps*$ds,,$stepr*$dr);
	my %C=distribution($t,$G,$dt,$s,$r);
	drawdist($im,$w,$h,$steps*$w,(1+$stepr)*$h,\%color,\%C,$s,$r);
} }

open(my $fh,'>','tension.png');
binmode($fh);
print $fh $im->png();
close($fh);
