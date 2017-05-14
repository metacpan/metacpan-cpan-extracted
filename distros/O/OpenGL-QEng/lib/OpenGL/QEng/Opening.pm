###  $Id:  $
####------------------------------------------
###
## @file
# Define Opening Class

## @class Opening
# Wall Openings (doorways, windows?) in game
#

package OpenGL::QEng::Opening;

use strict;
use warnings;

use base qw/OpenGL::QEng::Hinged/;

#-----------------------------------------------------------------
## @cmethod Opening new()
# Create a doorway (or window) at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  $props->{axis}    ||= 'y';
  $props->{xsize}   ||= 4;
  $props->{ysize}   ||= 7;
  $props->{zsize}   ||= .5;
  $props->{model}   ||= {minx => 0,                 maxx => $props->{xsize},
			 miny => 0,                 maxy => $props->{ysize},
			 minz => -$props->{zsize}/2,maxz => $props->{zsize}/2};
  my $self = OpenGL::QEng::Hinged->new($props);
  bless($self,$class);

  $self->assimilate($self->{fixed}) if (defined $self->{fixed});
  $self->assimilate($self->{cover}) if (defined $self->{cover});
  $self->create_accessors;
  $self->register_events;

  $self;
}

#--------------------------------------------------
sub assimilate {
  my ($self,$thing) = @_;

  return unless defined($thing);
  if (defined $self->{cover} && $thing != $self->{cover}) {
    $self->cover->assimilate($thing);
  } else {
    $self->SUPER::assimilate($thing);
  }
}

#==================================================================
1;

__END__

=head1 NAME

Opening -- Wall Openings (doorways, windows?) in game

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

