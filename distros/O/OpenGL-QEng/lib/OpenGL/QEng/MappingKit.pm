#---------------------------------------------------------------------------
## @file
# Implements MappingKit class

## @class MappingKit
# Avoids confusion
package OpenGL::QEng::MappingKit;

use strict;
use warnings;
use base qw/OpenGL::QEng::SimpleThing/;

sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};
  my $self;
  $self = OpenGL::QEng::Box->new;
  $self->{power}    = 'birdseye_view';
  $self->{y}        = 0;
  $self->{texture}  = ['mapkit0','mapkit1','mapkit2',
		       'mapkit2','mapkit2','mapkit5'];
  $self->{stretchi} = 1;
  $self->{face}     = 1;
  $self->{xsize}    = $props->{xsize} || 1;
  $self->{ysize}    = $props->{ysize} || 0.5;
  $self->{zsize}    = $props->{zsize} || 1;
  $self->{model}    = {miny =>  0,
		       maxy => +$self->{ysize},
		       minx => -$self->{xsize}/2,
		       maxx => +$self->{xsize}/2,
		       minz => -$self->{zsize}/2,
		       maxz => +$self->{zsize}/2,};
  bless($self,$class);

  $self->passedArgs($props) unless 0;
  $self->create_accessors;
  $self->register_events;

  $self;
}

#---------------------------------------------------------------------------
## @method $ textName
# Displayable name of this thing
sub textName { 'Box of stuff' }

#---------------------------------------------------------------------------
## @method $ desc($self)
# Return a text description of this object
sub desc { 'Creates a map of what you have seen -- maybe it uses satellites'}

#---------------------------------------------------------------------------
1;

=head1 NAME

MappingKit -- SimpleThing that gives the power of 'birdseye_view'

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

