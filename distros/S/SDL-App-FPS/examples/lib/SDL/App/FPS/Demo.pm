
# example subclass of SDL::App::FPS

package SDL::App::FPS::Demo;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL::Event;
use SDL::Constants;
use SDL::App::FPS::Color qw/BLACK WHITE/;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub _demo_animate_rectangle
  {
  # this animates the moving ractangle
  my ($self,$rect) = @_;

  # how much time elapsed since we started at start point
  my $time_elapsed = $self->current_time() - $rect->{now};
  # calculate how many pixels we must have moved in that time
  my $distance = $rect->{speed} * $time_elapsed / 1000; 

  # calculate the point were we land when we go $distance from the startpoint
  # in the current direction
  my $x_dist = $distance * cos($rect->{angle} * $self->{PI} / 180);
  my $y_dist = $distance * sin($rect->{angle} * $self->{PI} / 180);
 
  $rect->{x} = $rect->{x_s} + $x_dist; 
  $rect->{y} = $rect->{y_s} + $y_dist; 

  my $col = 0;	# collison with borders?
  # check whether the rectangle is still in the bounds of the screen
  if ($rect->{x} < 0)
    {
    $col++;
    # we hit the left border
    $rect->{x} = 0;
    # angle is between 90 and 270 degrees)
    $rect->{angle} = 180 - $rect->{angle};
    $rect->{angle} += 360 if $rect->{angle} < 0;
    }
  if ($rect->{x} + $rect->{w} >= $self->width())
    {
    $col++;
    # we hit the right border
    $rect->{x} = $self->width() - $rect->{w};
    # angle is between 270..360 and 0..90 degrees)
    $rect->{angle} = 180 - $rect->{angle};
    $rect->{angle} += 360 if $rect->{angle} < 0;
    }
  if ($rect->{y} < 0)
    {
    $col++;
    # we hit the upper border
    $rect->{y} = 0;
    # angle is between 180 and 360
    $rect->{angle} = 360 - $rect->{angle};
    }
  if ($rect->{y} + $rect->{h} >= $self->height())
    {
    $col++;
    # we hit the lower border
    $rect->{y} = $self->height() - $rect->{h};
    # angle is between 180..360
    $rect->{angle} = 360 - $rect->{angle};
    }
  # hit a wall?
  if ($col > 0)
    {
    if ($rect->{col} != 0)
      {
      # destroy us
      return 1;
      }
    # scatter the new angle a bit (avoids endless loops)
    $rect->{angle} += rand(12) - 4;		# skew the scatter to one side
    $rect->{angle} += 360 if $rect->{angle} < 0;
    $rect->{angle} -= 360 if $rect->{angle} >= 360;
    # reset start point and time 
    $rect->{x_s} = $rect->{x};
    $rect->{y_s} = $rect->{y};
    $rect->{now} = $self->current_time();
    }
  0;
  }

sub _demo_draw_rectangle
  {
  # draw the rectangle on the screen
  my ($self,$rect,$color) = @_;

  my $r = $rect->{rect};

  $r->width($rect->{w});
  $r->height($rect->{h});
  $r->x($rect->{x});
  $r->y($rect->{y});

  $self->app()->fill($r,$color);
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();

  # undraw the rectangle(s) at the current location
  foreach my $rect (@{$self->{rectangles}})
    {
    $self->_demo_draw_rectangle($rect,$self->{black});
    }

  # move them
  my @keep = ();
  foreach my $rect (@{$self->{rectangles}})
    {
    my $rc = $self->_demo_animate_rectangle($rect);
    # keep it ?
    push @keep, $rect if ($rc == 0);
    }
  $self->{rectangles} = [ @keep ];

  # redraw the rectangles at their current location
  foreach my $rect (@{$self->{rectangles}})
    {
    $self->_demo_draw_rectangle($rect,$rect->{color});
    }
  
  # update the screen with the changes
  my $rect = SDL::Rect->new(
   -width => $self->width(), -height => $self->height());
  $self->update($rect);

  }

sub post_init_handler
  {
  my $self = shift;
 
  $self->{rectangles} = [];
  
  $self->{black} = BLACK();
  $self->{PI} = 3.141592654;

  # from time to time add a rectangle
  $self->add_timer(800, -1, 3000, 0, \&_demo_add_rect);
  # from time to time start a timer which will "fire" rectangles 
  $self->add_timer(1200, -1, 4000, 0, \&_demo_add_fire);
  
  # set up the event handlers
  $self->watch_event ( 
    quit => 'SDLK_q', fullscreen => 'SDLK_f', freeze => 'SDLK_SPACE',
   );

  $self->add_event_handler (SDL_KEYDOWN, SDLK_b, 
   sub {
     my $self = shift;
     # run clock if it is currently halted
     $self->thaw_time() if $self->time_is_frozen();
     # let clock go backwards for a time
     $self->ramp_time_warp (-1, 2000);
     # and add a timer to set it automatically going forward again
     # Note that the clock goes backward, so we must set a negative target
     # time :)
     $self->add_timer ( -3000, 1, 0, 0, 
       sub {
         my $self = shift; 
         $self->ramp_time_warp (1, 2000); 
       } );
    });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT, 
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('2',1500);		# ramp up
     });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_RIGHT, 
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('0.3',1500);		# ramp down
     });
  $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_MIDDLE, 
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('1',1500);		# ramp to normal
     });
  }

sub _demo_add_fire
  {
  my $self = shift;

  $self->add_timer(100, 12, 80, 0, \&_demo_add_shot);
  }

sub _demo_add_shot
  {
  # add a shot to the screen going from right to left
  my ($self,$timer,$overshot) = @_;
    
  # comment in this line to see how the row of shots is no longer
  # uniform due to timer firing at start of frame, not when it is due
  #$overshot = 0;

  my $w = $self->width();
  my $h = $self->height();

  my $k = { 
    x => $w - 8,
    y => $h - 16,
    w => 4,
    h => 4,
    angle => 180,
    speed => 250,			# in pixel/second
    now => $self->current_time() - $overshot,
    col => 1,				# destroy
  };
  
  $k->{x_s} = $k->{x};		 # start x
  $k->{y_s} = $k->{y};		 # start y
  $k->{color} = WHITE;
  $k->{rect} = SDL::Rect->new();
  push @{$self->{rectangles}}, $k;
  }

sub _demo_add_rect
  {
  # add a rectangle to our list
  my $self = shift;
    
  my $w = $self->width();
  my $h = $self->height();

  my $k = { 
    x => ($w / 2) + rand($w / 10),
    y => ($h / 2) + rand($h / 10),
    w => int(32 + rand(16)),
    h => 16,
    angle => rand(360),
    speed => rand(100)+150,			# in pixel/second
    now => $self->current_time(),
    col => 0,					# bounce
  };
  
  # make it a perfect square, independ from screen resolution (works only
  # in fullscreen mode, of course)
  $k->{h} = int($k->{w} * $self->height()/ $self->width());

  $k->{x_s} = $k->{x};		 # start x
  $k->{y_s} = $k->{y};		 # start y
  $k->{color} = new SDL::Color (
   -r => int(rand(8)+1) * 0x20 - 1,		# 1f,3f,5f,7f,9f,bf,df,ff
   -g => int(rand(8)+1) * 0x20 - 1,
   -b => int(rand(8)+1) * 0x20 - 1);
  $k->{rect} = SDL::Rect->new();
  push @{$self->{rectangles}}, $k;
  }

1;

__END__

