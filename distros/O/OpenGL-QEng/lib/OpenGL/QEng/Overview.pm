###  $Id:  $
####------------------------------------------
## @file
# Define Overview Class
# Display map and current position
#

## @class Overview
#    Display portions of the map that have been seen and
#    the team's current position
#

package OpenGL::QEng::Overview;

use strict;
use warnings;
use OpenGL::QEng::GUICanvas;

use base qw/OpenGL::QEng::GUIThing/;

use constant PI => 4*atan2(1,1); # 3.14159;
use constant RADIANS => PI/180.0;

#--------------------------------------------------
## @cmethod % new()
# Create an Overview
#
sub new {
  my ($class,@props) = @_;

  my $props = (scalar(@props) == 1) ? $props[0] : {@props};

  my $self = OpenGL::QEng::GUIThing->new(x      => $props->{x}   ||5,
				 y      => $props->{y}   ||5,
				 width  => $props->{size}||100,
				 height => $props->{size}||100,);
  $self->{scale}      = 4;
  $self->{biasX}      = 2;
  $self->{biasY}      = 2;
  $self->{canvas}     = undef;
  $self->{lines}      = undef;
  $self->{root}       = undef;
  $self->{size}       = 100;
  $self->{onclick}    = undef;
  $self->{showUnseen} = $ENV{WIZARD};
  bless($self,$class);

  $self->passedArgs($props);
  $self->create_accessors;
  $self->register_events;
  $self->register_events;
  $self->{canvas} ||=
    OpenGL::QEng::GUICanvas->new(height => $self->{size},
			 width  => $self->{size},
			 color  => 'gray75',
			 x      => 5,
			 y      => 5,);
  if (defined($self->{onclick})) {
    $self->{clickCallback} = sub{
      my ($x,$y) = ($self->{mouse}{x},$self->{mouse}{y});
      $x -= $self->{biasX};
      $y -= $self->{biasY};
      $x = $x/$self->{scale};
      $y = $y/$self->{scale};
      $self->{onclick}->($x,$y);
    }
  }
  $self->{canvas}->create('Image',texture=>'splash', tag=>'m',
			  x=>3+($self->{width}-6)/2, y=>3+($self->{height}-6)/2,
			  width=>$self->{width}-6, height=>$self->{height}-6);
  $self;
}

#-----------------------------------------------------------
sub register_events {
  my ($self) = @_;

  for my $event (['new_map' => \&handle_new_map],
		) {
    $self->{event}->callback($self,$event->[0],$event->[1]);
  }
}

######
###### Public Instance Methods
######

#-----------------------------------------------------------
sub draw {
  my ($self) = @_;
  die "draw($self) from ",join(':',caller), unless ref $self;
  $self->canvas->draw;
}

#------------------------------------------
## @method @ setupMapView()
# Query all objects to create the list of map locations
# Called from quest (main driver program)
sub setupMapView {
  my ($self,$map) = @_;

  return unless $map;
  $self->lines([$map->get_map_view]);
}

#----------------------------------------------------
### @method drawMap($map)
##
sub drawMap { die 'deprecated? drawMap() called from ',join ':',caller;
  my ($self,$map) = @_;

  return unless defined $self->canvas;
  $self->canvas->delete('t');
  return unless $map;
  my $max = ($map->zsize >= $map->xsize) ? $map->zsize : $map->xsize;
  # add some for wall width extending beyond nominal max
  $self->scale((($self->{size}-$self->{biasX})/($max+1.0)));
}

#-----------------------------------------------------------------
### @method drawMapView
## draw the map from @{$self->lines}
sub drawMapView {
  my ($self) = @_;

  return unless defined $self->canvas;
  my ($scale, $biasX, $biasY) = ($self->scale, $self->biasX, $self->biasY);
  $self->canvas->delete('m');
  my %obj_color;
  foreach my $line (@{$self->lines}) {
    if (defined($line->[0])) {
      unless (exists $obj_color{$line->[6]}) {
	my $obj = $line->[6];
	$obj_color{$obj} = ($obj->seen) ? $obj->color || 'pink' : undef;
	$obj_color{$obj} = $obj_color{$obj}->[0] if ref $obj_color{$obj} eq 'ARRAY';
      }
      $line->[4] = $obj_color{$line->[6]};
      if (! $line->[4] && $self->{showUnseen}) {
	$line->[4] = 'lightblue';
      }
      if ($line->[4]) {		# don't draw for empty string as color
	$self->canvas->create('Line',
			      x =>$biasX+$scale*$line->[0],
			      y =>$biasY+$scale*$line->[1],
			      x2=>$biasX+$scale*$line->[2],
			      y2=>$biasY+$scale*$line->[3],
			      color=>$line->[4],tag=>'m');
      }
    }
  }
}

#-----------------------------------------------------------------
## @method update($map,$team,$other)
# update the position of the team on the overhead map
sub update {
  my ($self,$map,$team,$other) = @_;

  return unless defined $self->canvas;

  my ($scale, $biasX, $biasY) = ($self->scale, $self->biasX, $self->biasY);
  my $rad = 4;

  $self->canvas->delete('team');
  if (defined($other)) {
    $self->canvas->create('Circle',
			  $biasX+$other->x*$scale-$rad,
			  $biasY+$other->z*$scale-$rad,
			  $biasX+$other->x*$scale+$rad,
			  $biasY+$other->z*$scale+$rad,
			  fill=>'red', tag=>'teamx');
  }
  my ($yaw,@sin,@cos);
  $yaw = ($team->yaw+ 90)*RADIANS;
  $sin[0] = sin($yaw)*14;
  $cos[0] = cos($yaw)*14;
  $yaw = ($team->yaw+210)*RADIANS;
  $sin[1] = sin($yaw)*10;
  $cos[1] = cos($yaw)*10;
  $yaw = ($team->yaw+330)*RADIANS;
  $sin[2] = sin($yaw)*10;
  $cos[2] = cos($yaw)*10;
  $self->canvas->create('Poly',
			$biasX+$team->x*$scale+$sin[0],
			$biasY+$team->z*$scale-$cos[0],
			$biasX+$team->x*$scale+$sin[1],
			$biasY+$team->z*$scale-$cos[1],
			$biasX+$team->x*$scale+$sin[2],
			$biasY+$team->z*$scale-$cos[2],
			$biasX+$team->x*$scale+$sin[0],
			$biasY+$team->z*$scale-$cos[0],
			color=>'brown', tag=>'team');
  if (0) {
    $self->canvas->create('Circle',
			  $biasX+$team->x*$scale-$rad,
			  $biasY+$team->z*$scale-$rad,
			  $biasX+$team->x*$scale+$rad,
			  $biasY+$team->z*$scale+$rad,
			  color=>'blue', tag=>'team');
  }
  $self->send_event('need_ov_draw');
}

#--------------------------------
## @method showSpot($x,$z,$color)
# show a location on the overview in the requested color for
# diagnostic purposes
sub showSpot {
  my ($self,$x,$z,$color) = @_;

  $self->canvas->delete('teamz');
  my ($scale, $biasX, $biasY) = ($self->scale, $self->biasX, $self->biasY);
  my $rad = 4;
  $self->canvas->create('Circle',
			x=>$biasX+$x*$scale,
			y=>$biasY+$z*$scale,
			radius=>$rad,
			color=>$color,
			tag=>'teamz');
}

#--------------------------------------------
# Handle a new_map event
sub handle_new_map {
  my ($self,$stash,$obj,$ev,$map,@arg) = @_;

  my @min = (0,0);
  my @max = ($map->xsize,$map->zsize);

  $self->setupMapView($map);
  foreach my $line (@{$self->lines}) {

    my $i = 0;  # Extract the max and min for x and y
                # by checking the first 4 entries in @$line
    for my $p (@{$line}) {
      if ($p > $max[$i%2]) {
	$max[$i%2] = $p;
      }
      if ($p < $min[$i%2]) {
	$min[$i%2] = $p;
      }
      last if ++$i>3;
    }
  }
  $max[0] = $max[0] - $min[0];
  $max[1] = $max[1] - $min[1];
  my $i   = ($max[0] >= $max[1]) ? 0 : 1;

  # add some for wall width extending beyond nominal max
  $self->scale( ($self->{size}-$self->{biasX})/($max[$i]+1.0) );
}

#==================================================================
###
### Test Driver
###
if (not defined caller()) {
  package main;

  require OpenGL;
  require GUIMaster;
  require GUICanvas;
  require Map;

  my $ovSize = 600;
  my $winw = 200;
  my $winh = $ovSize;
  my $GUIRoot;

  OpenGL::glutInit;
  OpenGL::glutInitDisplayMode(OpenGL::GLUT_RGB   |
			      OpenGL::GLUT_DEPTH |
			      OpenGL::GLUT_DOUBLE);
  OpenGL::glutInitWindowSize($ovSize+200,$ovSize);
  OpenGL::glutInitWindowPosition(200,100);
  my $win1 = OpenGL::glutCreateWindow("OpenGL Control Test");
  glViewport(0,0,$winw,$winh);

  $GUIRoot = OpenGL::QEng::GUIMaster->new(wid=>$win1, x=>$ovSize, y=>0,
			    width=>200, height=>$ovSize);

  glutDisplayFunc(sub{ $GUIRoot->GUIDraw(@_) });
  glutMouseFunc(  sub{ $GUIRoot->mouseButton(@_) });
  glutMotionFunc( sub{ $GUIRoot->mouseMotion(@_) });

  # Create an overview object
  my $v = OpenGL::QEng::Overview->new(root=>$GUIRoot,size=>200);
  $GUIRoot->adopt($v);

#glutMainLoop;  # early completion????
  $v->{canvas}->erase();
  my $map1 = OpenGL::QEng::Map->new(zsize=>100,xsize=>100);
  $v->drawMap($map1, $GUIRoot);

  $v->showSpot(10,10,'blue');
  $v->showSpot(20,20,'orange');
  # only this spot will show becaue showSpot erases prior locations
  $v->showSpot(80,20,'red');

  glutMainLoop;
}
#------------------------------------------------------------------------------
1;

__END__

=head1 NAME

Inventory -- 2D GL GUIThing: drawing canvas

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

