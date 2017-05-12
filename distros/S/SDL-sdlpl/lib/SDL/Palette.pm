#
#	Palette.pm
#
#	a module for manipulating SDL_Palette *
#
#	David J. Goehrig Copyright (C) 2000

package SDL::Palette;
use strict;
use SDL::sdlpl;

#
# Palette Constructor 
#
# NB: there is no palette destructor because most of the time the palette will be owned by
# a surface, so any palettes you create with new, won't be destroyed until the program ends!
#

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	my $image;
	if (@_) { 
		$image = shift;
		$self->{-palette} = $image->palette(); 
	} else { $self->{-palette} = SDL::sdlpl::sdl_new_palette(256); }
	bless $self, $class;
	return $self;
}

sub size {
	my $self = shift;
	return SDL::sdlpl::sdl_palette_num_colors ($self->{-palette});
}

sub color {
	my $self = shift;
	my $index = shift;
	my ($r,$g,$b);
	if (@_) { 
		$r = shift; $g = shift; $b = shift; 
		return SDL::sdlpl::sdl_palette_color($self->{-palette},$index,$r,$g,$b);
	} else {
		return SDL::sdlpl::sdl_palette_color($self->{-palette},$index);
	}
}

sub red {
	my $self = shift;
	my $index = shift;
	my $c;
	if (@_) {
		$c = shift;
		return SDL::sdlpl::sdl_color_r(
			SDL::sdlpl::sdl_palette_color($self->{-palette},$index),$c);
	} else {	
		return SDL::sdlpl::sdl_color_r(
			SDL::sdlpl::sdl_palette_color($self->{-palette},$index));
	}
}

sub green {
	my $self = shift;
	my $index = shift;
	my $c;
	if (@_) {
		$c = shift;
		return SDL::sdlpl::sdl_color_g(
			SDL::sdlpl::sdl_palette_color($self->{-palette},$index),$c);
	} else {	
		return SDL::sdlpl::sdl_color_g(
			SDL::sdlpl::sdl_palette_color($self->{-palette},$index));
	}
}

sub blue {
	my $self = shift;
	my $index = shift;
	my $c;
	if (@_) {
		$c = shift;
		return SDL::sdlpl::sdl_color_b(
			SDL::sdlpl::sdl_palette_color($self->{-palette},$index),$c);
	} else {	
		return SDL::sdlpl::sdl_color_b(
			SDL::sdlpl::sdl_palette_color($self->{-palette},$index));
	}
}


1;
