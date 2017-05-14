#  $Id: Level.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Level Class

## @class Level
# Floor or Ceiling of game
#

package OpenGL::QEng::Level;

use strict;
use warnings;

use base qw/OpenGL::QEng::Box/;

#------------------------------------------
# @cmethod Plane new()
# Create a Plane (floor/ceiling)
sub new {
  my ($class,@prop) = @_;

  my $props = (scalar(@prop) == 1) ? $prop[0] : {@prop};

  my $self = OpenGL::QEng::Box->new;
  $self->{texture} = 'terracotta';
  $self->{tex_fs}  = 2;
  $self->{face}    = [1,0,0,0,0,1];
  $self->{color}   = 'beige';
  $self->{xsize}   = $props->{xsize} ||32;    # extent in x dir
  $self->{ysize}   = $props->{ysize} ||0.005; # extent in y dir
  $self->{zsize}   = $props->{zsize} ||32;    # extent in z dir
  $self->{model}   = {minx => 0,
		      maxx => $self->{xsize},
		      miny =>-$self->{ysize},
		      maxy => 0,
		      minz => 0,
		      maxz => $self->{zsize}};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;
  return $self;
}

#==================================================================
1;

__END__

=head1 NAME

Level -- horizontal plane like a floor or ceiling

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

