###  $Id: Character.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Character Class
## @class Character
# Object shows a picture and will start an interaction
#

package OpenGL::QEng::Character;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Box/;

#-----------  class methods  ---------------

#--------------------------------------------------
## @cmethod Simple new($class, @arg)
# Create a simpleThing of given type at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Box->new;
  $self->{state}   = 'unseen';  # State of the character
  $self->{face} = [0,1,0,0,0,0];# show only front face
  $self->{texture} = 'child';   # Texture image for this ...
  $self->{frames}  = 0;         # frames of texture values
  $self->{step}    = 1;         # step texture increment
  $self->{rate}    = undef;     # timing var for animation
  $self->{clock}   = undef;     # timing var for animation
  $self->{color}   = 'peach puff';
  $self->{stretchi}= 1;
  $self->{xsize} = $props->{xsize} || 8;
  $self->{ysize} = $props->{ysize} || 8;
  $self->{zsize} = $props->{zsize} || .1;
  $self->{model} = $props->{model} || {miny =>  0,
				       maxy =>  $self->{ysize},
				       minx => -$self->{xsize}/2,
				       maxx => +$self->{xsize}/2,
				       minz => -$self->{zsize}/2,
				       maxz => +$self->{zsize}/2,};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#-------------   Instance Methods    -------------------------------

#------------------------------------------
## @method move()
# Step the animation -- move to change the texture
sub move {
  my $self = shift;

  $self->SUPER::move;
  return if $self->frames == 0;
  return unless $self->seen;

  $self->{rate} = $self->{clock} = 1; # XXX temp until GL/TK sorted
  unless (defined($self->{rate})) {
    ## Adjust char changes to system speed
    my $r = int(0.2/main::getRate());
    if ($r<1) {$r = 1}
    $self->{rate} = $r;
    $self->{clock} = $r;
  }
  my $tex = $self->texture;
  my $l = length($tex);
  my $last = substr($tex,$l-1);
  my $first = substr($tex,0,$l-1);

  # allow for displaying the same image on multiple cycles on fast systems
  if (--$self->{clock}<=0) {
    $last +=$self->step;
    $self->{clock} = $self->{rate};
  }
  ## run through the images forward and backward
  if ($last>=$self->frames) {
    $self->step(-1);
  }
  if ($last<=1) {
    $self->step(1);
  }
  $self->texture($first.$last);
  $self->send_event('need_redraw','frame animation');
}

#==================================================================
1;

__END__

=head1 NAME

Character -- (possibly animated) N.P.C.

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

