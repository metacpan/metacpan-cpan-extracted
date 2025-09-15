package Schedule::Easing::Function;

use strict;
use warnings;
use Carp qw/carp/;

our $VERSION='0.1.4';

my %shapes=(
	linear=>\&linearShape,
	power =>\&powerShape,
	step  =>\&stepShape,
);

my %unshapes=(
	linear=>\&linearInverse,
	power =>\&powerInverse,
	step  =>\&stepInverse,
);

sub shape {
	my ($shape)=@_;
	if(my $f=$shapes{$shape}) { return $f }
	carp("Shape not supported:  $shape");
	return \&linearShape;
}

sub inverse {
	my ($shape)=@_;
	if(my $f=$unshapes{$shape}) { return $f }
	carp("Inverse not supported:  $shape");
	return \&linearInverse;
}

sub linearShape {
	my ($ts,$tsA,$tsB,$begin,$final)=@_;
	if($ts<=$tsA) { return $begin }
	if($ts>=$tsB) { return $final }
	return ($ts-$tsA)*($final-$begin)/($tsB-$tsA)+$begin;
}

sub linearInverse {
	my ($y,$tsA,$tsB,$ymin,$ymax)=@_;
	if   (($ymax>$ymin)&&(($y<$ymin)||($y>$ymax))) { return }
	elsif(($ymax<$ymin)&&(($y>$ymin)||($y<$ymax))) { return }
	if($ymax>$ymin) { return linearShape($y,$ymin,$ymax,$tsA,$tsB) }
	else            { return linearShape($ymax+$ymin-$y,$ymax,$ymin,$tsA,$tsB) }
}

sub powerShape {
	my ($ts,$tsA,$tsB,$begin,$final,$power)=@_;
	if($ts<=$tsA) { return $begin }
	if($ts>=$tsB) { return $final }
	return (($ts-$tsA)/($tsB-$tsA))**$power*($final-$begin)+$begin;
}

sub powerInverse {
	my ($y,$tsA,$tsB,$ymin,$ymax,$power)=@_;
	if   (($ymax>$ymin)&&(($y<$ymin)||($y>$ymax))) { return }
	elsif(($ymax<$ymin)&&(($y>$ymin)||($y<$ymax))) { return }
	if($ymin<$ymax) { return powerShape($y,$ymin,$ymax,$tsA,$tsB,1/$power) }
	else { return powerShape($ymax+$ymin-$y,$ymax,$ymin,$tsA,$tsB,1/$power) }
}

sub stepShape {
	my ($ts,$tsA,$tsB,$begin,$final,$steps)=@_;
	if($ts<=$tsA) { return $begin }
	if($ts>=$tsB) { return $final }
	return int(($ts-$tsA)/($tsB-$tsA)*$steps)/$steps*($final-$begin)+$begin;
}

sub stepInverse {
	my ($y,$tsA,$tsB,$ymin,$ymax,$steps)=@_;
	if   (($ymax>$ymin)&&(($y<$ymin)||($y>$ymax))) { return }
	elsif(($ymax<$ymin)&&(($y>$ymin)||($y<$ymax))) { return }
	if($ymin<$ymax) { return stepShape($y,$ymin,$ymax,$tsA,$tsB,$steps) }
	else            { return stepShape($ymax+$ymin-$y,$ymax,$ymin,$tsA,$tsB,$steps) }
}

1;
