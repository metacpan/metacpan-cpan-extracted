
# example of SDL::App::FPS demonstrating clickable areas (aka buttons)

package SDL::App::FPS::MyButt;

# (C) 2002,2006 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL;
use SDL::App::FPS::Button qw/
  BUTTON_DOWN
  BUTTON_RECTANGULAR
  /;

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
  $rect->{button}->move_to(
    $rect->{x} + $rect->{w} / 2,$rect->{y} + $rect->{h} / 2);
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

  my $rect = $self->{rectangles};

  # check for loosing
  if (keys %$rect >= 20)
    {
    $self->{score} -= 100;
    $self->quit();
    }

  # undraw the rectangle(s) at the current location
  foreach my $id (keys %$rect)
    {
    $self->_demo_draw_rectangle($rect->{$id},$self->{black});
    }

  # move them
  foreach my $id (keys %$rect)
    {
    my $rc = $self->_demo_animate_rectangle($rect->{$id});
    # keep it ?
    delete $rect->{$id} unless $rc == 0;
    }

  # redraw the rectangles at their current location
  foreach my $id (keys %$rect)
    {
    $self->_demo_draw_rectangle($rect->{$id},$rect->{$id}->{color});
    }
  
  # update the screen with the changes
  my $r = SDL::Rect->new(
   -width => $self->width(), -height => $self->height());
  $self->update($r);

  }

sub post_init_handler
  {
  my $self = shift;
 
  $self->{rectangles} = {};
  $self->{id} = 0;
  $self->{max} = 0;
  
  $self->{black} = new SDL::Color (-r => 0, -g => 0, -b => 0);
  $self->{white} = new SDL::Color (-r => 0xff, -g => 0xff, -b => 0xff);
  $self->{PI} = 3.141592654;

  $self->_demo_add_rect();
  # add some at the start
  $self->add_timer(20, 4, 100, 10, \&_demo_add_rect);
  # from time to time add a rectangle
  $self->add_timer(500, -1, 2000, 400, \&_demo_add_rect);
  
  # set up the event handlers
  $self->watch_event ( 
    quit => 'q', fullscreen => 'f', freeze => 'SDLK_SPACE',
   );

  $self->{won} = 0;
  $self->{score} = 1000;	# if killed all instantly => max score
  }

sub _demo_add_rect
  {
  # add a rectangle to our list
  my $self = shift;
    
  $self->{score} -= 100;		# if you kill it, score will remain

  my $w = $self->width();
  my $h = $self->height();

  my $k = { 
    x => ($w / 2) + rand($w / 5),
    y => ($h / 2) + rand($h / 5),
    w => int(32 + rand(16)),
    h => 16,
    angle => rand(360),
    speed => rand(100)+120,			# in pixel/second
    now => $self->current_time(),
    col => 0,					# bounce
    id => $self->{id}++,
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
  
  $self->{rectangles}->{$k->{id}} = $k;
  $k->{button} = 
   $self->add_button(
     int($k->{x} + ($k->{w} / 2)), int($k->{y} + ($k->{h} / 2)),
     $k->{w}, $k->{h},
    BUTTON_DOWN, BUTTON_RECTANGULAR, BUTTON_MOUSE_LEFT,
    sub { 
     my ($self,$button,$id) = @_;
     $self->del_button($button);
     print "1: Oh no, $id is down.\n";
     # flash it
     $self->{rectangles}->{$id}->{color} = $self->{white};
     # and add timer to remove it a bit later
     $self->add_timer(200, 1, 0, 0, 
      sub { 
       my ($self,$timer,$overshot,$id) = @_;
       my $rect = $self->{rectangles};
       $self->_demo_draw_rectangle ($rect->{$id},$self->{black});
       #$rect->{$id}->{col} = 2;
       delete $rect->{$id};
       # check for win situation
       if (keys %$rect == 0)
         {
         $self->{won}++;
         $self->{score} += 100;
         $self->quit();
         }

       $self->{score} += 50;
       }, $id );
    
     },
    $k->{id},
    );

  $self->{max} = scalar keys %{$self->{rectangles}} if
   $self->{max} < scalar keys %{$self->{rectangles}};

  }

1;

__END__

