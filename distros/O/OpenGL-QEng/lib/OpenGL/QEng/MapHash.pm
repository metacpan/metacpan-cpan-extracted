###  $Id: MapHash.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
## @file
# Define MapHash Class
#

## @class MapHash
# Hashtable to hold the map information efficiently
#

package OpenGL::QEng::MapHash;

use strict;
use warnings;

use base qw/OpenGL::QEng::Thing/;

#--------------------------------------------------------
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Thing->new;
  bless($self,$class);

  $self->passedArgs($props);	# from OUtil
  $self->register_events;	# from Thing
  $self->create_accessors;	# from OUtil

  return $self;
}

#--------------------------
## @method assimilate($thing)
# make $thing a part of $self
#
sub assimilate {
  my ($self,$thing) = @_;

  return unless defined($thing);
  $self->SUPER::assimilate($thing);
  if ($thing->isa('OpenGL::QEng::Map')) {
    $self->{$thing->{textMap}} = $thing;
  }
}

#------------------------------------------
sub printMe { #XXX merge into Thing
  my ($self,$depth) = @_;

  $depth ||= 0;
  my %boring = (x         => 1,	z         => 1,
		yaw       => 1,GLid      => 1,
		event     => 1, chunk     => 1,
		holds     => 1, parts     => 1,
		is_at     => 1, tlines    => 1,
		gaplist   => 1, goggles   => 1,
		map_view  => 1, range_2   => 1,
		near_code => 1, event_code=> 1,
		maps      => 1, team      => 1,
		cover     => 1, fixed     => 1,
		wrap_class=> 1, objects   => 1,
	       );
  (my $map_ref = ref $self) =~ s/OpenGL::QEng:://;
  print STDOUT '  'x$depth,"$map_ref $self->{x} $self->{z} $self->{yaw};\n";
  my $spec = $self->not_default;
  my $started = 0;
  for my $key (keys %{$spec}) {
    next unless defined $spec->{$key};
    next if defined $boring{$key};
    unless ($started) {
      print STDOUT '  'x$depth,"partof_last;\n";
      $started = 1;
    }
    $self->{$key}->printMe($depth+1);
  }
  print STDOUT '  'x$depth,"done;\n" if $started;
}

#==================================================================

1;

=head1 NAME

MapHash -- storage for the Maps in a game, keyed by filename

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

