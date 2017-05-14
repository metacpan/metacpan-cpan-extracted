#  $Id: Hinged.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Hinged Class

## @class Hinged
# Hinged thing in the game such as a chest
#

package OpenGL::QEng::Hinged;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Volume/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

my %axis_name = (x=>'pitch', y=>'yaw', z=>'roll');

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

## @cmethod % new()
# Create a hinged composite Thing made of 2 Things connected at a hinge
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::Volume->new;
  $self->{key}            = undef;     # Key that can unlock this thing
  $self->{opener}         = undef;     # other thing that can open this thing
  $self->{cover}          = undef;
  $self->{fixed}          = undef;
  $self->{repository}     = undef;
  $self->{axis}           = 'x';      # x=pitch, y=yaw, z=roll
  $self->{swing}          = 90;       # how much to open the hinge
  $self->{state}          = 'closed'; # state of the thing: 'open',
                                      # 'closed' or 'locked'
  $self->{hinge}          = 0;        # current angle of cover
  $self->{closed_hinge}   = 0;
  $self->{open_hinge}     = 90;
  bless($self,$class);

  $props->{swing}          = 90 unless defined $props->{swing};
  $props->{hinge}        ||= 0;
  $props->{closed_hinge} ||= 0;
  $props->{open_hinge}     = $props->{closed_hinge} + $props->{swing}
    unless defined $props->{open_hinge};

  $self->passedArgs($props);
  if ($self->{state} eq 'open') { # XXX perhaps we want to allow 'ajar'
    $self->{hinge} = $self->{open_hinge};
  } else {
    $self->{hinge} = $self->{closed_hinge};
  }
  $self->create_accessors;
  $self->register_events;

  $self;
}

#--------------------------------------------------
sub boring_stuff {
  my ($self) = @_;
  my $boring_stuff = $self->SUPER::boring_stuff;
  $boring_stuff->{cover} = 1;
  $boring_stuff->{fixed} = 1;
  $boring_stuff;
}

#-----------------------------------------------------------------
sub move {
  my $self = shift;

  return unless defined $self->{target}{hinge};

  my $saved_hinge = $self->hinge;
  my $saved_target = delete $self->{target}{hinge};

  $self->cover->{target}{$axis_name{$self->{axis}}} = $saved_target;

  $self->SUPER::move;

  $self->{hinge} = $self->cover->{$axis_name{$self->{axis}}} || 0;

  $self->{target}{hinge} = $saved_target
    unless $self->hinge == $saved_target;
  if (abs($self->open_hinge - $self->hinge) < abs(2/3*$self->swing)) {
    $self->state('open');
  } else {
    $self->state('closed');
  }
}

#-----------------------------------------------------------
## @method $ handle_touch()
# touch handler method for ?
sub handle_touch {
  my ($self,$team) = @_;

  if ($self->state eq 'locked') {                 # try to unlock
    $self->send_event('try_unlock');
  }
  elsif ($self->state eq 'closed') {              # open if closed
    $self->{target}{hinge} = $self->{open_hinge};
  }
  else {			                  # close if open
    $self->{target}{hinge} = $self->{closed_hinge};
  }
}

#------------------------------------------
sub special_parts {
  qw(cover fixed);
}

#==============================================================================
1;

__END__

=head1 NAME

Hinged -- Combination class that has two parts joined at a "hinge" line

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

