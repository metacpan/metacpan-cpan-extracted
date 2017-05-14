###  $Id: Beam.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file Beam.pm
# Define Beam Class

## @class Beam
#  Create a wooden beam
#

package OpenGL::QEng::Beam;

use strict;
use warnings;

use base qw/OpenGL::QEng::Box/;

#------------------------------------------------------------
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Box->new;
  $self->{texture}   = 'beam';       # Texture image for this beam
  $self->{color}     = 'brown';
  $self->{face}      = 1;
  $self->{stretchi}  = 1;
  $self->{xsize}     = $props->{xsize} || 3/12;
  $self->{ysize}     = $props->{ysize} || 8;
  $self->{zsize}     = $props->{zsize} || 3/12;
  $self->{model}     = {miny => 0,
			maxy => $self->{ysize},
			minx => -$self->{xsize}/2,
			maxx => +$self->{xsize}/2,
			minz => -$self->{zsize}/2,
			maxz => +$self->{zsize}/2,
		       };
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#==============================================================================
1;

__END__

=head1 NAME

Beam -- a simple wooden beam

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

