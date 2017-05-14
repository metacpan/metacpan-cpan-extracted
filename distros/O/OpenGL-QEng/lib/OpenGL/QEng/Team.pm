###  $Id: Team.pm 424 2008-08-19 16:27:43Z duncan $
####------------------------------------------
## @file
# Define Team Class

## @class Team
# Information about the team of adventurers
#
# Team location and look direction and Inventory.
#
# Contains: inventory

package OpenGL::QEng::Team;

use strict;
use warnings;
use OpenGL qw/:all/;

use base qw/OpenGL::QEng::Thing/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;
use constant DEGREES => 180.0/PI;

#####
##### Class Methods - called as Class->function($a,$b,$c)
#####

#--------------------------------------------------
## @cmethod Team new()
# Create the only Team object
sub new {
  my ($class,@props) = @_;

  @props = %{$props[0]} if (scalar(@props) == 1);
  my $self;
  if (ref $class) {
    $self = $class;
    $class = ref $self;
    for my $attr qw(holds using is_at ability) {
      undef $self->{$attr};
    }
    $self->{target} = {};
    $self->{no_events} = 1;
  }
  else {
    $self = OpenGL::QEng::Thing->new;
    $self->{holds}       = [];	# the current inventory array
    $self->{max_contains}= 16;	# inventory capacity, fixed right now
    $self->{x}           = 0;	# current team x location
    $self->{y}           = 5.5;	# current team y location
    $self->{z}           = 0;	# current team z location,
    $self->{yaw}         = 90;	# current team facing angle
    $self->{pitch}       = 0;	# current team nodding angle
    $self->{using}       = undef; # what are we using now?
    $self->{is_at}       = undef;
    $self->{ability}     = undef;
    $self->{goggles}     = {red=>0, green=>0, blue=>0,
			    active     => 0,
			    type       => undef,
			    trans      => 0,
			    trans_inc  => 0.1,
			    trans_idx  => 0,
			    trans_step => 0.05,
			    max_trans  => 10,
			    tran_steps => [1.0, 0.99, 0.95, 0.89, 0.81, 0.71,
					   0.59, 0.45, 0.31, 0.16, 0],
			    model      => {miny => -5,   maxy => 5,
					   minz => -0.1, maxz => 0,
					   minx => -4,   maxx => 4},
			   };
    bless($self,$class);
  }
  $self->passedArgs({@props});
  $self->register_events;
  $self->create_accessors;

  $self->{ability}{birdseye_view} = 1 if $ENV{WIZARD} or $ENV{BAD_VISUAL};
  $self->{max_contains} = $ENV{INVSIZE} if defined $ENV{INVSIZE};
  $self;
}

#####
##### Object Methods
#####

#--------------------------------------------------
sub boring_stuff {
  my ($self) = @_;
  my $boring_stuff = $self->SUPER::boring_stuff;
  $boring_stuff->{goggles} = 1;
  $boring_stuff;
}

#--------------------------------------------------
sub register_events {
  my ($self) = @_;

  return if $self->no_events;
  for my $event (['turn'         => \&handle_turn,   ],
		 ['pivot'        => \&handle_pivot,  ],
		 ['step'         => \&handle_step,   ],
		 ['go'           => \&handle_go,     ],
		 ['slide'        => \&handle_slide,  ],
		 ['dropit'       => \&handle_drop,   ],
		 ['away'         => \&handle_away,   ],
		 ['team_use'     => \&set_using_item,],
		 ['tell_using'   => \&describe_using,],
		 ['effect'       => \&show_effect,   ],
		) {
    $self->{event}->callback($self,$event->[0],$event->[1]);
  }
}

#--------------------------------------------------
## @method move()
# Step the animation -- move to raise or lower view
sub move {
  my $self = shift;

  $self->SUPER::move;
  # test for turning away from nodding cause
  #print STDERR "calling step_team from Team::move\n";
  #$self->send_event('step_team',0,0,0);

  if ($self->{goggles}{active}) {
    my $goggles = $self->{goggles};
    $goggles->{trans} = $goggles->{tran_steps}[$goggles->{trans_idx}];
    if ($goggles->{type} eq 'fadein' || $goggles->{type} eq 'stars') {
      $goggles->{trans_idx} += 1;
    }
    if ($goggles->{type} eq 'fadeout') {
      $goggles->{trans_idx} -= 1;
    }
    if ($goggles->{trans} > 1.0 ||
	$goggles->{trans} < 0.0 ||
	$goggles->{trans_idx} >= $goggles->{max_trans} ||
	$goggles->{trans_idx} < 0 ) {

      $goggles->{trans_inc} = -$goggles->{trans_inc};
      if ($goggles->{type} eq 'stars') {
	$self->send_event('effect','fadein','black');
      }
      else { ## adjustment for testing
	$goggles->{active} = 0;
      }
    }
    $self->send_event('need_redraw');
  }
}

#--------------------------------------------------
sub show_effect {
  my ($self,$stash,$team,$cmd,$effectType,$effectColor,@effectArgs) = @_;
  $self->adjust_picture($effectType,$effectColor,@effectArgs);
}

#--------------------------------------------------
sub adjust_picture {
  my ($self,$effectType,$effectColor,@effectArgs) = @_;

  my $goggles = $self->goggles;
  ($goggles->{red}, $goggles->{green}, $goggles->{blue}) =
    $self->getColor($effectColor) if defined $effectColor;
  $goggles->{type} = $effectType;
  if ($effectType eq 'fadein' || $effectType eq 'stars' ) {
    $goggles->{trans_inc} = -$goggles->{trans_step};
    $goggles->{trans} = 1.0;
    $goggles->{trans_idx} = 0;
  }
  elsif ($effectType eq 'fadeout') {
    $goggles->{trans_inc} = $goggles->{trans_step};
    $goggles->{trans} = 0.0;
    $goggles->{trans_idx} = 10;
  }
  $goggles->{active} = 1;
}

#------------------------------------------
sub see {
  my ($self,$mode) = @_;

  return if ($mode == OpenGL::GL_SELECT);

  my $goggles = $self->goggles;
  return unless $goggles->{active};

  my $step = 2.0;	  # Distance effect is in front of the team
  my $tyaw = -$self->yaw+90; # adjust for coordinate systems

  # find point $step in front of the team
  my $ex = $self->x+$step*sin($tyaw*RADIANS);
  my $ez = $self->z+$step*cos($tyaw*RADIANS);

  ### Effect Shape parameters
  # Extremes of the Effect footprint dimensions
  my $model = $goggles->{model};
  my ($minx,$maxx) = ($model->{minx},$model->{maxx});
  my ($miny,$maxy) = ($model->{miny},$model->{maxy});
  my ($minz,$maxz) = ($model->{minz},$model->{maxz});
  my $stMinY = -0.25;
  my $stMaxY = 0.25;
  my $stMinX = -0.25;
  my $stMaxX =  0.25;

  glTranslatef($ex,$self->y,$ez);
  glRotatef($tyaw,0,1,0);
  if ($goggles->{type} eq 'stars') {
    my $fact = 3.0;
    my $f    = 1.0;
    my $f1 = rand $fact;
    my $f2 = rand $fact;
    my $f3 = rand $fact;
    my $f4 = rand $fact;
    my $f5 = rand $fact;
    my $f6 = rand $fact;
    my $f7 = rand $fact;
    my $f8 = rand $fact;

    glColor3f(1.0,rand,0);

    #build the figure from Quads
    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMaxX,    $stMinY/2.0,$maxz);
    glVertex3f($stMaxX*0.1, $stMinY*0.1, $minz);
    glVertex3f($stMaxX/2.0,  $stMinY,    $minz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMaxX,    $stMinY/2.0,$maxz);
    glVertex3f($stMaxX*$f1, $stMinY*$f1, $minz);
    glVertex3f($stMaxX/2.0,  $stMinY,    $minz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMinX,    $stMaxY/2.0,$maxz);
    glVertex3f($stMinX*$f2, $stMaxY*$f2, $minz);
    glVertex3f($stMinX/2.0,  $stMaxY,    $minz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMaxX/2.0, $stMinY,    $minz);
    glVertex3f(0.0,       $stMinY*$f3, $minz);
    glVertex3f($stMinX/2.0, $stMinY,    $maxz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMinX/2.0, $stMaxY,    $minz);
    glVertex3f(0.0,       $stMaxY*$f4, $minz);
    glVertex3f($stMaxX/2.0, $stMaxY,    $maxz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMinX/2.0, $stMinY,    $maxz);
    glVertex3f($stMinX*$f5, $stMinY*$f5, $minz);
    glVertex3f($stMinX,    $stMinY/2.0,$minz);
    glVertex3f(0.0,      0.0,      $maxz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMaxX/2.0, $stMaxY,    $maxz);
    glVertex3f($stMaxX*$f6, $stMaxY*$f6, $minz);
    glVertex3f($stMaxX,    $stMaxY/2.0,$minz);
    glVertex3f(0.0,      0.0,      $maxz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMaxX,    $stMaxY/2.0,$minz);
    glVertex3f($stMaxX*$f7,  0.0,      $minz);
    glVertex3f($stMaxX,    $stMinY/2.0,   $maxz);
    glEnd();

    glBegin(OpenGL::GL_QUADS);
    glVertex3f(0.0,      0.0,      $maxz);
    glVertex3f($stMinX,    $stMinY/2.0,$maxz);
    glVertex3f($stMinX*$f8,  0.0,      $minz);
    glVertex3f($stMinX,    $stMaxY/2.0,   $minz);
    glEnd();
  }
  else {
    glColor4f($goggles->{red}, $goggles->{green}, $goggles->{blue},
	      $goggles->{trans});

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glBegin(OpenGL::GL_QUADS);
    glVertex3f($minx,$miny,$minz);
    glVertex3f($minx,$maxy,$minz);
    glVertex3f($maxx,$maxy,$maxz);
    glVertex3f($maxx,$miny,$maxz);
    glEnd();
    glDisable(GL_BLEND);
  }
  glRotatef(-$tyaw,0,1,0);
  glTranslatef(-$ex,-$self->y,-$ez);

  #$self->tErr('draw Effect');
}

#-----------------------------------------------------------
## @method $ start
#set team starting location and orientation
sub start {
  my ($self,$x,$z,$yaw,$map) = @_;

  $self->x($x);
  $self->z($z);
  $self->yaw($yaw);
  $self->is_at($map);
  $self->send_event('team_at',$self->x,$self->z,$self->is_at);
}

#------------------------------------------
## @method $ draw($self, $mode)
#
sub draw {
  my ($self,$mode) = @_;

  my $viewX = $self->x+cos($self->yaw*RADIANS);
  my $viewY = $self->y+sin($self->pitch*RADIANS)*2;
  my $viewZ = $self->z+sin($self->yaw*RADIANS);
  gluLookAt($self->x,$self->y,$self->z,
	    $viewX, $viewY, $viewZ, 0, 1.0, 0);
}

#-----------------------------------------------------------
## @method put_thing($thing)
#put arg (a thing instance) into the current thing
sub put_thing {
  my ($self,$thing,$store) = @_;

  return unless defined($thing);

  # Do we already have one of these?
  my $match = ref($thing);
  foreach my $t (@{$self->holds || []}) {
    if ($match eq ref($t)) {
      if ($t->combine($thing)) {
	$self->send_event('inventory_change');
	return;
      }
    }
  }
  push(@{$self->{holds}},$thing);
  $thing->is_at($self);

  # does this thing give us new abilities?
  $self->{ability}{$thing->power} += 1 if defined $thing->power;

  # test for picking up last nodding cause
#  $self->send_event('step_team',0,0,0);
  $self->send_event('inventory_change');
}

#-----------------------------------------------------------
## @method $ take_thing($desired_thing)
#remove (a thing instance) from the inventory and return it
sub take_thing {
  my ($self,$desired_thing) = @_;

  $desired_thing = '(undef)' unless defined $desired_thing;
  unless (@{$self->holds}) {
    warn 'empty backpack, desired_thing=',$desired_thing;
    warn join(':',caller);
    return undef;
  }
  my $r_thing;
  my @things;         # Temporary inventory list for item removal
  while (my $thing = shift(@{$self->holds})) {
    if ($thing eq $desired_thing) {
      $r_thing = $thing;
    } else {
      push(@things, $thing);
    }
  }
  $self->holds(\@things);

  # did this thing give us new abilities?
  $self->{ability}{$r_thing->power} -= 1 if defined $r_thing->power;
  $self->send_event('need_redraw');   #show the scene change

  $r_thing;
}

#-----------------------------------------------------------
## @method handle_turn()
# Turn the team
sub handle_turn {
  my ($self,$stash,$obj,$ev,$amount) = @_;

  $self->{target}{yaw} = $self->yaw+$amount;
}

#-----------------------------------------------------------
## @method handle_pivot()
# Turn the team
sub handle_pivot {
  my ($self,$stash,$obj,$ev,$amount) = @_;

  $self->{yaw} = $self->yaw+$amount;
  $self->send_event('team_at',$self->x,$self->z,$self->is_at);
  $self->send_event('need_redraw');
}

#-----------------------------------------------------------
## @method handle_step()
# Move the team
#
sub handle_step {
  my ($self,$stash,$obj,$ev,$speed,$dir) = @_;

  $dir ||= 0;
  #my $absSpeed = abs($speed);
  my $steps = 1;
  #if (::getRate() > $absSpeed) {
  #  $steps = int((2*::getRate()/$absSpeed)+0.5);
  #  if ($steps > 6) {
  #    $steps = 6;
  #  }
  #}
  $self->send_event('step_team',$steps,$speed,$dir);
}

#-----------------------------------------------------------
## @method handle_slide()
# slide the Team into a new position
sub handle_slide {
  my ($self,$stash,$obj,$ev,$x,$y,$z,$roll,$pitch,$yaw) = @_;

  $self->{target}{x}     = $x;
  $self->{target}{y}     = $y if defined $y;
  $self->{target}{z}     = $z;
  $self->{target}{roll}  = $roll if defined $roll;
  $self->{target}{pitch} = $pitch if defined $pitch;
  $self->{target}{yaw}   = $yaw if defined $yaw;
}

#-----------------------------------------------------------
## @method handle_go()
# Move the team instantly - event
sub handle_go {
  my ($self,$stash,$obj,$ev,$x,$z,$yaw) = @_;

  $self->x($x);
  $self->z($z);
  $self->yaw($yaw) if defined $yaw;
  $self->send_event('team_at',$self->x,$self->z,$self->is_at);
  $self->send_event('need_redraw');
}

#-----------------------------------------------------------
## @method handle_drop()
# Drop an item
sub handle_drop {
  my ($self) = @_;

  return unless (defined $self->using);
  my $obj = $self->take_thing($self->holds->[$self->using]);
  return unless defined($obj);
  $obj->send_event('dropped');
  undef $self->{using};
  $self->send_event('inventory_change');
  $self->send_event('need_redraw');
}

#-----------------------------------------------------------
## @method set_using_item()
# Have the team use this item (by item number)
sub set_using_item {
  my ($self,$stash,$obj,$ev,$item) = @_;

  if (defined $self->holds->[$item-1]) {
    $self->using($item-1);
  } else {
    undef $self->{using};
  }
  $self->send_event('inventory_change');
}

#-----------------------------------------------------------
## @method describe_using()
# Have the team use this item (by item number)
sub describe_using {
  my ($self,$stash,$obj,$ev,@args) = @_;

  if (my $thing=(defined $self->using) ? $self->holds->[$self->using]:undef) {
    print $thing->desc,"\n";
    $self->send_event('msg',$thing->desc."\n");
  }
}

#==================================================================
###
### Test Driver
###
#
if (!defined(caller())) {
  package main;

  require Wall;
  use constant RADIANS => 4*atan2(1,1)/180.0;

  my $team = OpenGL::QEng::Team->new(x=>4,z=>4);
  my $wall = OpenGL::QEng::Wall->new;
  my $tx   = $team->x;
  my $tz   = $team->z;
  my $tyaw = $team->yaw;

  warn "$tx,$tz $tyaw";

}

#------------------------------------------------------------------------------

1;

__END__

=head1 NAME

Team -- Team location and look direction and Inventory.

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

