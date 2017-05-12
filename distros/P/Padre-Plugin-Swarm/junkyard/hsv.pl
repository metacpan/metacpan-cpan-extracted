#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

{

	my %vars;
	%vars = ( 
		h=>\my $h,
		s=>\my $s,
		v=>\my $v, 
		t=>\my $t,
		f=>\my $f,
		p=>\my $p,
		q=>\my $q,
	);
	my @matrix = (
		[$vars{v}, $vars{t}, $vars{p}],
		[$vars{q}, $vars{v}, $vars{p}],
		[$vars{p}, $vars{v}, $vars{t}],
		[$vars{p}, $vars{q}, $vars{v}],
		[$vars{t}, $vars{p}, $vars{v}],
		[$vars{v}, $vars{p}, $vars{q}],
	);
	
sub compute_rgb {
	($h,$s,$v) = @_;
	warn "Running $h , $s , $v ";	
	my $h_index = ( $h / 60 ) % 6;
	warn "$h_index hextant";

	$f = abs( $h/60 ) - $h_index;
	$p = $v * ( 1 - $s );
	$q = $v * ( 1 - ($f * $s));
	$t = $v * ( 1 - ( 1 - $f ) * $s );
	
	#$q = $v * ( 1 - $s * ($h 
	
	warn sprintf('f=%f , p=%f . q=%f , t=%f ',
		$f, $p, $q, $t
	);
	my $result = $matrix[$h_index];
	my @rgb = map { $$_ } @$result;
	#warn Dumper \@matrix;
	return \@rgb;

}	

}


my @foo = qw( nop rg er eh s );

my $hue = 270;

foreach  my $hue ( 0..240 ) {
my $sat = .75;
my $val = .75;
warn Dumper compute_rgb( $hue, $sat, $val );
}