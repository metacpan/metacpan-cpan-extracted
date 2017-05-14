###  $Id: Map.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
## @file
# Define Map Class
#
# Collection of items that make up a game location

## @class Map
# Location of all game items
#
# Coordinates - 0,0 is the northwest or upper left corner.  Positive Z is
#  down or south.  Positive X is right or east.  Dimensions are in feet.
#

package OpenGL::QEng::Map;

use strict;
use warnings;

use base qw/OpenGL::QEng::Volume/;

#--------------------------------------------------------
#Create a new Map instance
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Volume->new;
  $self->{xsize}    = 8;
  $self->{zsize}    = 8;
  $self->{start}    = [4,4,0];
  $self->{textMap}  = undef;
  $self->{store_at} = undef;
  bless($self,$class);

  $self->passedArgs($props);	# from OUtil
  $self->register_events;	# from Thing
  $self->create_accessors;	# from OUtil

  return $self;
}

#==================================================================
1;

__END__

=head1 NAME

Map - Collection of items that make up a game location

=head3 Testing

Setting the environment variable 'WIZARD' will allow walking through walls

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

