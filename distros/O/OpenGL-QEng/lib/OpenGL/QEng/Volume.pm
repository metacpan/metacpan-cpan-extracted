#  $Id: Volume.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Volume Class

## @class Volume
# Implements a volume of space as a container for things in the game
#

package OpenGL::QEng::Volume;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Thing/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

#--------------------------------------------------
## @cmethod % new()
# Create a volume of space that may contain stuff
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Thing->new;
  $self->{visible} = 0;
  $self->{shrink_fit} = 1;	# 1=we are the size that holds our contents
  $self->{xsize} = $props->{xsize} || 8;
  $self->{ysize} = $props->{ysize} || 8;
  $self->{zsize} = $props->{zsize} || 8;
  $self->{model} = $props->{model} ||
    {miny =>  0,
     maxy =>  $self->{ysize},
     minx => -$self->{xsize}/2,
     maxx => +$self->{xsize}/2,
     minz => -$self->{zsize}/2,
     maxz => +$self->{zsize}/2};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#--------------------------------------------------
## @method put_thing($thing)
#put arg (a thing instance) into the current thing
sub put_thing {
  my ($self,$thing,$store) = @_;
  return unless defined($thing);

  die "put_thing($self,$thing) from ",join(':',caller)," " unless $store;

  #XXX may need to check boundaries
  if ($self->{shrink_fit}) {
    ;
  } else {
    ;
  }
  $self->SUPER::put_thing($thing,$store);
}

#---------------------------------------------------------
sub draw {
  my ($self,$mode) = @_;

  my $chkErr = 1; # flag

  if ($mode == OpenGL::GL_SELECT) {
    glLoadName($self->{GLid});
  }
  glTranslatef($self->x,$self->y,$self->z);
  glRotatef($self->{roll}, 0,0,1) if $self->{roll};
  glRotatef($self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef($self->{pitch},1,0,0) if $self->{pitch};

  if ($self->contains) {
    foreach my $o (@{$self->contains}) {
      $o->draw($mode);
    }
  }
  glRotatef(-$self->{pitch},1,0,0) if $self->{pitch};
  glRotatef(-$self->{yaw},  0,1,0) if $self->{yaw};
  glRotatef(-$self->{roll}, 0,0,1) if $self->{roll};
  glTranslatef(-$self->x,-$self->y,-$self->z);

  $chkErr && $self->tErr('draw Volume');
}

#------------------------------------------
sub tractable { # tractability - 'solid', 'seethru', 'passable'
  'passable';
}

#==============================================================================
1;

__END__

=head1 NAME

Volume -- a 3D volume of space in/on a Map

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

