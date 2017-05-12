
# example subclass of SDL::App::FPS

package SDL::App::FPS::MyEvent;

# (C) 2002, 2006 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  /;
use SDL;
use SDL::App::FPS::EventHandler; 

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
  
  $self->{black} = new SDL::Color (-r => 0, -g => 0, -b => 0);
  $self->{PI} = 3.141592654;

  # state 0 => wait for rectangle to appear
  # state 1 => move them automatically around
  # state 2 => let user move one around

  $self->{state} = 0;

  # when the first one is added, go to state 1
  $self->add_timer(1800, 1, 0, 0, sub {
    my $self = shift;
    $self->_demo_add_rect();
    $self->_demo_state(1);
    } );
  
  # from time to time add a rectangle until we have 8+1
  $self->add_timer(3000, 8, 3000, 500, \&_demo_add_rect );
  
  # set up the event handlers

  # create a group for events that are active in state 1, one for state 2
  # and one for event handlers that are always active (like QUIT)
  for my $state (1..2)
    {
    $self->{group}->{$state} = $self->add_group();
    }
  $self->{group_all} = $self->add_group();

  # setup the event handlers that are always active
  $self->watch_event (
    quit => SDLK_q, freeze => SDLK_SPACE,
   );

  # this just for demo purposes
  my $group = $self->{group_all};
  $group->add(
    $self->add_event_handler (SDL_KEYDOWN, SDLK_f, 
     sub { my $self = shift; $self->fullscreen(); }),
    );
  
  # setup the event handlers that are active in state 2
  $group = $self->{group}->{2};
  
  $group->add(
    $self->add_event_handler (SDL_KEYDOWN, SDLK_LEFT, 
     sub { my $self = shift; $self->_demo_move_left(); }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_RIGHT, 
     sub { my $self = shift; $self->_demo_move_right(); }),
    
    $self->add_event_handler (SDL_KEYDOWN, SDLK_DOWN, 
     sub { my $self = shift; $self->_demo_move_down(); }),
  
    $self->add_event_handler (SDL_KEYDOWN, SDLK_UP, 
     sub { my $self = shift; $self->_demo_move_up(); }),
    
    $self->add_event_handler (SDL_KEYDOWN, SDLK_RETURN, 
     sub { my $self = shift; $self->_demo_state(1); }),
    $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT, 
     sub { my $self = shift; $self->_demo_state(1); }),
    );
    
  # setup the event handlers that are active in state 1
  $group = $self->{group}->{1};

  $group->add(
    $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT, 
     sub { my $self = shift; $self->_demo_state(2); }),
    $self->add_event_handler (SDL_KEYDOWN, SDLK_RETURN, 
     sub { my $self = shift; $self->_demo_state(2); }),
    );

  }

sub _demo_move_up
  {
  # move the first rectangle up
  my $self = shift;
  my $rect = $self->{rectangles}->[0];

  if ($rect->{y_s} > 0)
    {
    $rect->{y_s}--; $rect->{now} = $self->current_time();
    }
  }

sub _demo_move_down
  {
  # move the first rectangle down
  my $self = shift;
  my $rect = $self->{rectangles}->[0];

  if ($rect->{y_s} + $rect->{h} < $self->height())
    {
    $rect->{y_s}++; $rect->{now} = $self->current_time();
    }
  }

sub _demo_move_left
  {
  # move the first rectangle left
  my $self = shift;
  my $rect = $self->{rectangles}->[0];

  if ($rect->{x_s} > 0)
    {
    $rect->{x_s}--; $rect->{now} = $self->current_time();
    }
  }

sub _demo_move_right
  {
  # move the first rectangle right
  my $self = shift;
  my $rect = $self->{rectangles}->[0];

  if ($rect->{x_s} + $rect->{w} < $self->width())
    {
    $rect->{x_s}++; $rect->{now} = $self->current_time();
    }
  }

sub _demo_state
  {
  # switch to the desired state
  my $self = shift;
  my $state = shift;

  # state 0 => wait for rectangle to appear
  # state 1 => move them automatically around
  # state 2 => let user move one around

  print "At ", $self->current_time()," going from $self->{state} to " 
        ."state $state\n";

  # disable all events in all states, except the one we switch to, in this
  # case enable them
  my $group = $self->{group};		# shortcut
  for my $state_id (keys %$group)
    {
    if ($state == $state_id)
      {
      $group->{$state_id}->activate();
      }
    else
      {
      $group->{$state_id}->deactivate();
      # or use this: $group->{$state_id}->for_each ('deactivate');
      }
    }
  my $rect = $self->{rectangles}->[0];
  if ($state == 1)
    {
    $rect->{speed} = rand(100)+50;
    $rect->{now} = $self->current_time();
    $rect->{x_s} = $rect->{x};
    $rect->{y_s} = $rect->{y};
    }
  if ($state == 2)
    {
    $rect->{speed} = 00;
    $rect->{now} = $self->current_time();
    $rect->{x_s} = $rect->{x};
    $rect->{y_s} = $rect->{y};
    }
  $self->{state} = $state;
  # that's all, really!
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
    w => 32 + rand(16),
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

