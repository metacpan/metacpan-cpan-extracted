###  $Id: Door.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Door "Class"

## @class Door
# Doors in game - any style
#

package OpenGL::QEng::Door;

use strict;
use warnings;
#no base class: just a convienience function
use OpenGL::QEng::Opening;

#-----------------------------------------------------------------
sub new {
  my ($fakeclass,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $type = ucfirst(delete($props->{type}) || 'wood') . 'Door';

  my $texture  = delete($props->{texture})  || 'door';
  my $color    = delete($props->{color})    || 'brown';
  my $tex_fs   = delete($props->{tex_fs})   || 7;
  my $stretchi = delete($props->{stretchi});
  $stretchi =  1 unless defined $stretchi;

  # sanity check door type using eval as a 'try/catch'
  eval {
    require "OpenGL/QEng/$type.pm";
    $props->{cover} ||= "OpenGL::QEng::$type"->new(texture  => $texture,
					   tex_fs   => $tex_fs,
					   stretchi => $stretchi,
					   color    => $color,
					  ); #XXX props?
  };
  die "\nOops: there doen't seem to be a $type class in the game.\n",
    "Check your map. (door ... type=>'?')\n\n" if $@;
  my $self = OpenGL::QEng::Opening->new($props);

  $self->create_accessors;
  $self->register_events;

  $self;
}

#==================================================================
1;

__END__

=head1 NAME

Door -- conveniece function to add an Opening with a Door of some
type; defaults to WoodDoor

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

