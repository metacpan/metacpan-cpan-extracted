eval 'exec perl -S $0 ${1+"$@"}' # -*-Perl-*-
  if $running_under_some_shell;

###  $Id:  $
####------------------------------------------
###
## @file
# Define WoodDoor Class

## @class WoodDoor
# Doors in game - wooden style
#

package OpenGL::QEng::WoodDoor;

use strict;
use warnings;

use base qw/OpenGL::QEng::Part/;

#-----------------------------------------------------------------
## @cmethod WoodDoor new()
# Create a WoodDoor at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  $props->{color}   ||= 'brown';
  $props->{texture} ||= 'door';
  $props->{stretchi}||= 1;
  $props->{face}    ||= [1,1,1,1,1,1];
  $props->{xsize}   ||= 4;
  $props->{ysize}   ||= 7;
  $props->{zsize}   ||= .1;
  $props->{model}   ||= {minx => 0,                 maxx => $props->{xsize},
			 miny => 0,                 maxy => $props->{ysize},
			 minz => -$props->{zsize}/2,maxz => $props->{zsize}/2};

  my $self = OpenGL::QEng::Part->new($props);
  bless($self,$class);

  #$self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;

  $self;
}

#==================================================================
1;

__END__

=head1 NAME

WoodDoor -- a Door that is made of boards with an iron handle

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

