###  $Id: Chest.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
###
## @file
# Define Chest Class

## @class Chest
# Chests in game

package OpenGL::QEng::Chest;

use strict;
use warnings;
use OpenGL qw/:all/;
use OpenGL::QEng::Part;

use base qw/OpenGL::QEng::Hinged/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

#-----------------------------------------------------------------
## @cmethod Chest new()
# Create a chest at given location
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  $props->{swing} ||= 70;       # how much to open the hinge

  my $self = OpenGL::QEng::Hinged->new(swing => $props->{swing},);
  bless($self,$class);

  $props->{eye_magnet}||= 1,
  $props->{color} ||= 'gold';
  $props->{xsize} ||= 3;
  $props->{ysize} ||= 2.5;
  $props->{zsize} ||= 2;
  $props->{model} ||= {minx => -$props->{xsize}/2,maxx => $props->{xsize}/2,
		       miny => 0.01,              maxy => $props->{ysize}+0.01,
		       minz => -$props->{zsize}/2,maxz => $props->{zsize}/2};
  $props->{cover} ||= OpenGL::QEng::Part->new(x         => 0,
				y         => $props->{model}{miny}+2,
				z         => $props->{model}{maxz},
				xsize     => 3, ysize => 0.5, zsize => 2,
				face      => 1, #[1,1,1,1,1,0],
				texture   => ['chestlid','chestfront','side',
					      'side','side','chest_liner',],
				stretchi  => 1,
				color     => $props->{color},
				eye_magnet=> 1,
				holder    => 1,
				model     => {miny=> 0,   maxy=> 0.5,
					      minx=>-1.5, maxx=>+1.5,
					      minz=>-2,   maxz=> 0,  },   );
  $props->{fixed} ||= OpenGL::QEng::Part->new(x         => 0,
				y         => $props->{model}{miny},
				z         => 0,
				xsize     => 3, ysize => 2, zsize => 2,
				face      => [0,1,1,1,1,1],
				texture   => ['',    'side','side',
					      'side','side','wood',],
				stretchi  => 1,
				color     => $props->{color},
				eye_magnet=> 1,
				holder    => 1,
				store_at  => {x     => 0,
					      y     => 0.01,
					      z     => 0,
					      roll  => 0,
					      pitch => 0,
					      yaw   => 0    },
			          );
  $self->{color} = undef;
  $self->passedArgs($props);
  $self->assimilate($self->{cover});
  $self->assimilate($self->{fixed});
  $self->create_accessors;
  $self->register_events;

  $self;
}

#####
##### Object Methods
#####

#-----------------------------------------------------------------
## @method move()
# Step the animation -- move to open the top
sub move {
  my $self = shift;

  my $saved_hinge = $self->hinge;
  $self->SUPER::move;

  if ($self->hinge > $saved_hinge) {
    # if there is stuff on top of the lid, slide it off when we open
    if ($self->{hinge} > 10 && $self->holds) {
      foreach my $o (@{$self->holds}) {
	next if ($o == $self->cover || $o == $self->fixed);
	if ($o->y >= ($self->y+($self->{model}{maxy}-$self->{model}{miny}))) {
	  $self->is_at->put_thing($self->take_thing($o));
	  $o->{x} = $self->x;
	  $o->{z} = $self->z;
	  $o->{y} = $self->y+2.52;
	  $o->{yaw} = $self->yaw;
	  $o->{target}{x} = $self->x+(sin($self->yaw*RADIANS)*2);
	  $o->{target}{z} = $self->z+(cos($self->yaw*RADIANS)*2);
	  $o->{target}{y} = $self->y;
	}
      }
    }
  }
}

#--------------------------------------------------
sub can_hold {
  my ($self, $thing) = @_;
  1;
}

#==================================================================
1;

__END__

=head1 NAME

Chest -- a container for SimpleThings

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

