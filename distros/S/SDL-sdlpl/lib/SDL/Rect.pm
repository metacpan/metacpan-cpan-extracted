#!/usr/bin/perl -w 
#	Rect.pm
#
#	A package for manipulating SDL_Rect *
#
#	David J. Goehrig Copyright (C) 2000

package SDL::Rect;
use strict;
use SDL::sdlpl;

#
# Rect Constructor / Destructor
#

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my %options = @_;
	my $x = $options{-x} || 0;
	my $y = $options{-y} || 0;
	my $w = $options{-width} || 0;
	my $h = $options{-height} || 0;
	$self->{-rect} = SDL::sdlpl::sdl_new_rect($x,$y,$w,$h);
	bless $self,$class;
	return $self;
}

sub DESTROY {
	my $self = shift;
	SDL::sdlpl::sdl_free_rect($self->{-rect});
}

sub x {
	my $self = shift;
	
	if (@_) { 
		my $x = shift; 
		return SDL::sdlpl::sdl_rect_x($self->{-rect},$x);
	} else {
		return SDL::sdlpl::sdl_rect_x($self->{-rect});
	}
}

sub y {
	my $self = shift;
	
	if (@_) { 
		my $y = shift; 
		return SDL::sdlpl::sdl_rect_y($self->{-rect},$y);
	} else {
		return SDL::sdlpl::sdl_rect_y($self->{-rect});
	}
}

sub width {
	my $self = shift;

	if (@_) { 
		my $d = shift; 
		return SDL::sdlpl::sdl_rect_w($self->{-rect},$d);
	} else {
		return SDL::sdlpl::sdl_rect_w($self->{-rect});
	}
}

sub height {
	my $self = shift;
	
	if (@_) { 
	        my $d = shift; 
		return SDL::sdlpl::sdl_rect_h($self->{-rect},$d);
	} else {
		return SDL::sdlpl::sdl_rect_h($self->{-rect});
	}
}

1;

__END__;

=head1 NAME

SDL::Rect - a SDL perl extension

=head1 SYNOPSIS

  $rect = new SDL::Rect ( -height => 4, -width => 40 );

=head1 DESCRIPTION


	SDL::Rect->new(...); creates a SDL_Rect structure which is
used for specifying regions for filling, blitting, and updating.
These objects make it easy to cut and backfill.

By default, x, y = 0, and h, w default to 0. (the default
scratch sizes);

=head2 Rect fields

	The four fields of a rectangle can be set simply
by passing a value to the applicable method.  These are:

	$rect->x(4);		# sets x to 4
	$rect->y();		# reads y
	$rect->width(49);	# sets width to 49
	$rect->height();	# reads height

=head1 AUTHOR

David J. Goehrig

=head1 SEE ALSO

perl(1) SDL::Surface(3)

=cut

