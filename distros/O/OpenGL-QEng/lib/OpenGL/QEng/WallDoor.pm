###  $Id: WallDoor.pm 315 2008-07-18 15:23:03Z duncan $
####------------------------------------------
###
## @file
# Define WallDoor Class

## @class WallDoor
# Doors in game - wall style
#

package OpenGL::QEng::WallDoor;

use strict;
use warnings;

use base qw/OpenGL::QEng::Part/;

#-----------------------------------------------------------------
## @cmethod WallDoor new()
# Create a WallDoor
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  $props->{color}   ||= 'slate gray';
  $props->{texture} ||= 'wall-grey';
  $props->{stretchi}||= 0;
  $props->{face}    ||= [1,1,1,1,1,1];
  $props->{xsize}   ||= 4;
  $props->{ysize}   ||= 7;
  $props->{zsize}   ||= .5;
  $props->{model}   ||= {minx => 0,                 maxx => $props->{xsize},
			 miny => 0,                 maxy => $props->{ysize},
			 minz => -$props->{zsize}/2,maxz => $props->{zsize}/2};

  my $self = OpenGL::QEng::Part->new($props);
  bless($self,$class);

  $self->{i_am_a_walldoor_chunk} = 1;
  #$self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#==================================================================
1;

__END__

=head1 NAME

WallDoor -- a Door that seems to be part of the wall--hard to see

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

