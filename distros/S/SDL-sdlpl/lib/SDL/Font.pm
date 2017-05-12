#!/usr/bin/perl -w
#	Font.pm
#
#	a SDL perl extension for SFont support
#
#

package SDL::Font;
use strict;
use SDL::sdlpl;

use vars qw(@ISA);
	    

@ISA = qw(SDL::Surface);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{-fontname} = shift;
	$self->{-surface} = SDL::sdlpl::sdl_sfont_new_font($self->{-fontname});
	bless $self,$class;
	return $self;	
}

sub DESTROY {
	my $self = shift;
	SDL::sdlpl::sdl_free_surface($self->{-surface});
}

sub use {
	my $self = shift;
	SDL::sdlpl::sdl_sfont_use_font($self->{-surface});
}


sub text_width 
  { 
   return SDL::sdlpl::sdl_sfont_text_width(join('',@_));
  }

1;

__END__;

=head1 NAME

SDL::Font - a SDL perl extension

=head1 SYNOPSIS

  $font = new Font "Font.png";
  $font->use();

=head1 DESCRIPTION

	SDL::Font provides a mechanism for loading and using SFont style
fonts.  To create a new font, simply create a new instance of the class
Font, passing it the name of the image file that contains the SFont.

	To use the font, call the use method of the font instance as
shown above.  Perl will automagically deallocate all of the buffers.
You must create and use a font prior to printing on any surface.
For further details see the file SFont-README in this distribution.

=head1 AUTHOR

David J. Goehrig

=head1 SEE ALSO

perl(1) SDL::Surface(3)

=cut
