#!/bin/perl
package SVGraph::2D::ring;
use SVGraph::2D;
use strict;


our @ISA=("SVGraph::2D");



sub new
{
	my $class=shift;
	my %env=@_;
	my $self={};
    
	%{$self->{ENV}}=%env;
  
	$self->{grid_y_scale_minimum}=$env{grid_y_scale_minimum};
	$self->{grid_y_scale_maximum}=$env{grid_y_scale_maximum};
	$self->{grid_y_main_spacing}=$env{grid_y_main_spacing};
 
	$self->{type}="columns";
 
	return bless $self,$class;
}





sub prepare
{
	my $self=shift;

	$self->{SVG}=SVG->new(width=>$self->{ENV}{x},height=>$self->{ENV}{y});

	# draw the block
	$self->prepare_block();

	# add the title text
	$self->prepare_title();

	# prepare the columns
	$self->prepare_columns();

 #
 # VYPOCITANIE POCTU ROWSOV - $self->{grid_x_main_lines}
 # VYPOCITANIE MAX VALUE - $self->{value_max}
 #
 #$self->prepare_axis_calculate();
 #$self->prepare_axis_x_markArea(front=>0);
 #$self->prepare_axis_x(); 
 #$self->prepare_axis_x_mark(front=>0); 
 #$self->prepare_axis_y_markArea(front=>0);
 #$self->prepare_axis_y();
 #$self->prepare_axis_y_mark(front=>0);

	$self->prepare_legend();


	$self->{SVG}->ellipse
	(
	'cx'=>300,
	'cy'=>150,
	'rx'=>200,
	'ry'=>80,
	'stroke'=>"black",
	'stroke-width'=>"1pt",
	);

 
 
 #$self->prepare_axis_x_markArea(front=>1);
 #$self->prepare_axis_x_mark(front=>1);
 #$self->prepare_axis_y_markArea(front=>1);
 #$self->prepare_axis_y_mark(front=>1);
 #$self->prepare_axis();

 # posledny vystup 
	$self->{SVG_out}=$self->{SVG}->xmlify
	(
#	-namespace => "svg",
	-pubid => "-//W3C//DTD SVG 1.0//EN",
#	-inline   => 1
	);
	return $self->{SVG_out};
}







