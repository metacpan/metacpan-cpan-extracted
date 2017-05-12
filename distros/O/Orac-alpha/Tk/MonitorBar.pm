package Tk::MonitorBar;

use Tk;
use Tk::ProgressBar;
use Carp;
use strict;

use base qw(Tk::Derived Tk::ProgressBar);

Construct Tk::Widget 'MonitorBar';

sub _arrange {
    my $c = shift;

    my $checker = Tk::Exists($c);

    unless ($checker)
    {
       return;
    }
    my $why = $c->{'layout_pending'};

    $c->{'layout_pending'} = 0;

    my $w = $c->Width;
    my $h = $c->Height;
    my $bw = $c->cget('-borderwidth') + $c->cget('-highlightthickness');
    my $x = abs(int($c->{Configure}{'-padx'})) + $bw;
    my $y = abs(int($c->{Configure}{'-pady'})) + $bw;
    my $value = $c->value;
    my $from = $c->{Configure}{'-from'}; 
    my $to   = $c->{Configure}{'-to'};
    my $horz = $c->{Configure}{'-anchor'} =~ /[ew]/i ? 1 : 0;
    my $dir  = $c->{Configure}{'-anchor'} =~ /[nw]/i ? -1 : 1;

    my($minv,$maxv) = $from < $to ? ($from,$to) : ($to,$from);

    if($w == 1 && $h == 1) {
	my $bw = $c->cget('-borderwidth');
	my $defw = 10 + $y*2 + $bw *2;
	my $defl = ($maxv - $minv) + $x*2 + $bw*2;

	$h = $c->{Configure}{'-length'} || $defw;
	$w = $c->{Configure}{'-width'}  || $defl;

	($w,$h) = ($h,$w) unless $horz;
	$c->GeometryRequest($w,$h);
	$c->parent->update;
	$c->update;

	$w = $c->Width;
	$h = $c->Height;
    }

    $w -= $x*2;
    $h -= $y*2;

    my $length = $horz ? $w : $h;
    my $width  = $horz ? $h : $w;
   
    my $blocks = int($c->{Configure}{'-blocks'});
    my $gap    = int($c->{Configure}{'-gap'});

    $blocks = 1 if $blocks < 1;

    my $gwidth = $gap * ( $blocks - 1);
    my $bwidth = ($length - $gwidth) / $blocks;

    if($bwidth < 3 || $blocks <= 1 || $gap <= 0) {
	$blocks = 1;
	$bwidth = $length;
	$gap = 0;
    }

    if($why & 1) {
	my $colors = $c->{Configure}{'-colors'} || [];
	my $bdir = $from < $to ? $dir : 0 - $dir;

	$c->delete($c->find('all'));

	$c->createRectangle(0,0,$w+$x*2,$h+$y*2,
		-fill =>  $c->{Configure}{'-troughcolor'},
		-width => 0,
		-outline => undef);

	$c->{'cover'} =	$c->createRectangle($x,$y,$w,$h,
		-fill =>  $c->{Configure}{'-troughcolor'},
		-width => 0,
		-outline => undef);

	my($x0,$y0,$x1,$y1);

	if($horz) {
	    if($bdir > 0) {
		($x0,$y0) = ($x - $gap,$y);
	    }
	    else {
		($x0,$y0) = ($length + $x + $gap,$y);
	    }
	    ($x1,$y1) = ($x0,$y0 + $width);
	}
	else {
	    if($bdir > 0) {
		($x0,$y0) = ($x,$y - $gap);
	    }
	    else {
		($x0,$y0) = ($x,$length + $y + $gap);
	    }
	    ($x1,$y1) = ($x0 + $width,$y0);
	}

	my $blks  = $blocks;
	my $dval  = ($maxv - $minv) / $blocks;
	my $color = $c->cget('-foreground');
	my $pos   = 0;
	my $val   = $minv;

	while($val < $maxv) {
	    my($bw,$nval);

	    while(($pos < @$colors) && $colors->[$pos] <= $val) {
		$color = $colors->[$pos+1];
		$pos += 2;
	    }

	    if($blocks == 1) {
		$nval = defined($colors->[$pos])
			? $colors->[$pos] : $maxv;
		$bw = (($nval - $val) / ($maxv - $minv)) * $length;
	    }
	    else {
		$bw = $bwidth;
		$nval = $val + $dval if($blocks > 1);
	    }

	    if($horz) {
		if($bdir > 0) {
		    $x0 = $x1 + $gap;
		    $x1 = $x0 + $bw;
		}
		else {
		    $x1 = $x0 - $gap;
		    $x0 = $x1 - $bw;
		}
	    }
	    else {
		if($bdir > 0) {
		    $y0 = $y1 + $gap;
		    $y1 = $y0 + $bw;
		}
		else {
		    $y1 = $y0 - $gap;
		    $y0 = $y1 - $bw;
		}
	    }

	    $c->createRectangle($x0,$y0,$x1,$y1,
		-fill => $color,
		-width => 0,
		-outline => undef
	    );
	    $val = $nval;
	}
    }

    my $cover = $c->{'cover'};
    my $ddir = $from > $to ? 1 : -1;

    if(($value <=> $to) == (0-$ddir)) {
	$c->lower($cover);
    }
    elsif(($value <=> $from) == $ddir) {
	$c->raise($cover);
	my $x1 = $horz ? $x + $length : $x + $width;
	my $y1 = $horz ? $y + $width : $y + $length;
	$c->coords($cover,$x,$y,$x1,$y1);
    }
    else {
	my $step;
	$value = int($value / $step) * $step
	    if(defined($step = $c->{Configure}{'-resolution'}) && $step > 0);

	$maxv = $minv+1
	    if $minv == $maxv;

	my $range = $maxv - $minv;
	my $bval = $range / $blocks;
	my $offset = abs($value - $from);
	my $ioff = int($offset / $bval);
	my $start = $ioff * ($bwidth + $gap);
	$start += ($offset - ($ioff * $bval)) / $bval * $bwidth;

	my($x0,$x1,$y0,$y1);
	
	if($horz) {
	    $y0 = $y;
	    $y1 = $y + $h;
	    if($dir > 0) {
		$x0 = $x + $start;
		$x1 = $x + $w;
	    }
	    else {
		$x0 = $x;
		$x1 = $w + $x - $start;
	    }
	}
	else {
	    $x0 = $x;
	    $x1 = $x + $w;
	    if($dir > 0) {
		$y0 = $y + $start;
		$y1 = $y + $h;
	    }
	    else {
		$y0 = $y;
		$y1 = $h + $y - $start;
	    }
	}

	
	$c->raise($cover);
	$c->coords($cover,$x0,$y0,$x1,$y1);
    }
}

1;
