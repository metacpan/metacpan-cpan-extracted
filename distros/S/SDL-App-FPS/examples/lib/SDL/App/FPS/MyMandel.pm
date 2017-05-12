
# example subclass of SDL::App::FPS

package SDL::App::FPS::MyMandel;

# (C) 2002, 2006 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT 
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT 
  /;
use SDL;
use SDL::App::FPS::Color qw/BLACK/;

use vars qw/$use_perl/;
use base qw/SDL::App::FPS/;

sub use_perl
  {
  $use_perl;
  }

BEGIN
  {
  $use_perl = 0;
  eval "require Math::Fractal::Mandelbrot;";
  if (defined $Math::Fractal::Mandelbrot::VERSION)
    {
    if ($Math::Fractal::Mandelbrot::VERSION < 0.02)
      {
      warn ("Need at least Math::Fractal::Mandelbrot v0.02");
      }
    else
      {
      $use_perl = 1;
      }
    }
  }

##############################################################################

sub _mandel_recursive
  {
  # this routine takes a given rectangle and divides it into two halves
  # if any of the two halves has the same color
  my $self = shift;

  return if ($self->{state} == 3);

  my $cache = $self->{cache};
  if ($self->{state} == 1)
    {
    # in stage 1, we must setup a rectangle around the screen
    # once we are done, we enter stage 2
    if ($self->{done} == 0)
      {
      print "\nDoing $self->{x1} , $self->{y1} ...\n",
            " $self->{x2} , $self->{y2}\n";
      print "\nMax iter = $self->{max_iter}\n";
      # calculate the upper line
      for my $x (0 .. $self->{width}-1)
        {
        $self->_mandel_draw_point($x,0,
          $cache->[$x]->[0] = $self->_mandel_point($x,0) );
        }
      $self->{done} = 1;
      return;
      }
    if ($self->{done} == 1)
      {
      # calculate the lower line
      for my $x (0 .. $self->{width}-1)
        {
        $self->_mandel_draw_point($x,$self->{height}-1,
         $cache->[$x]->[$self->{height}-1] =
           $self->_mandel_point($x,$self->{height}-1) );
        }
      $self->{done} = 2;
      return;
      }
    if ($self->{done} == 2)
      {
      # calculate the left line
      for my $y (0 .. $self->{height}-1)
        {
        $self->_mandel_draw_point(0,$y,
         $cache->[0]->[$y] = $self->_mandel_point(0,$y) );
        }
      $self->{done} = 3;
      return;
      }
    if ($self->{done} == 3)
      {
      # calculate the right line
      for my $y (0 .. $self->{height}-1)
        {
        $self->_mandel_draw_point($self->{width}-1,$y,
         $cache->[$self->{width}-1]->[$y] =
          $self->_mandel_point($self->{width}-1,$y) ); 
        }
      #$self->{done} = 0;	# divide next
      $self->{state} = 2;
      push @{$self->{stack}}, [ 0, 0, $self->{width}-1, $self->{height}-1, 0 ];
      return;
      }
    }

  my $now = $self->app()->ticks();
  my $rect = SDL::Rect->new( -x => 0, -y => 0, -width => 1, -height => 1);
  # our stack contains the rectangles we must still do
  RECTANGLE:
   while (@{$self->{stack}} > 0)
    {
    if ($self->app()->ticks() - $now > 150)
      {
      # calculate how many % we already did. By summing up all the rectangles
      # on the stack (not taking their borders into account due to overlap) we
      # find out much we must still do
      my $sum = 0;
      foreach my $r (@{$self->{stack}})
        {
        $sum += ($r->[2]-$r->[0]-2) * ($r->[3]-$r->[1]-2);
        }
      $sum = $self->width() * $self->height() - $sum;
      print "\rRectangles still todo: ",scalar @{$self->{stack}}," ";
      my $percent = int($sum * 10000 / ($self->width() * $self->height()))/100 . "%";
      print "$percent done    ";
      $self->app()->title("Mandel $percent done");
      return;
      }

    # access current rectangle and take it from stack 
    my ($xl,$yl,$xr,$yr,$level) = @{ shift @{$self->{stack}} };
    #print "Now at level $level, $xl, $yl => $xr, $yr\n";
    my $w = ($xr-$xl);
    my $h = ($yr-$yl);
   
    # check that the rectangle has all the same border color around
    # if yes, fill it and be done with it
    my $border = $cache->[$xl]->[$yl];
    my $same = 0;
    for my $x ($xl .. $xr)
      {
      $same++, last if $cache->[$x]->[$yl] != $border;
      $same++, last if $cache->[$x]->[$yr] != $border;
      }
    if ($same == 0)
      {
      # hm, upper/lower borders were the same, so check left/right
      for my $y ($yl+1 .. $yr-1)
        {
        $same++, last if $cache->[$xl]->[$y] != $border;
        $same++, last if $cache->[$xr]->[$y] != $border;
        }
      # all the same
      if ($same == 0)
        {
        # skip blacks
        if ($border != 0)
          {
          # color it and stop dividing it
          $rect->x($xl+1);
          $rect->y($yl+1);
          $rect->width($w-1);
          $rect->height($h-1);

	  # re-use SDL::Color object for speed
          my $c = $self->{color};
          $c->r(($self->{color_bias_red} + $border) & 0xff);
          $c->g(($self->{color_bias_green} + $border) & 0xff);
          $c->b(($self->{color_bias_blue} + $border) & 0xff);
        
          $self->app()->fill($rect,$c);
          }
        next RECTANGLE;			# done with that
        }
      }
    # nope, border did not have the same colors, so "do" rectangle 
    # if to small, compute it iteratively
    if (($w < 6) || ($h < 6))
      {
      for (my $x = $xl+1; $x < $xr; $x++)
        {
        for (my $y = $yl+1; $y < $yr; $y++)
          {
          $self->_mandel_draw_point($x,$y, 
           $cache->[$x]->[$y] = $self->_mandel_point($x,$y) );
          }
        }
      next RECTANGLE;			# done with that
      }
      
    # according to level (odd/even) divide it horizontal or vertically
    if (($level & 1) == 0)
      {
      # store the current line we do
      $self->{sx} = int($xl+$w/2);
      # divide vertically, and put both up the stack
      push @{$self->{stack}}, [$xl,$yl,$self->{sx},$yr,$level+1];
      push @{$self->{stack}}, [$self->{sx},$yl,$xr,$yr,$level+1];
        
      # we divided, and have still to do the line between the halves
      my $x = $self->{sx};
      my $y = $yl+1;
      do 
        {
        $self->_mandel_draw_point($x,$y, $cache->[$x]->[$y] =
           $self->_mandel_point($x,$y) );
        } while (++$y < $yr);
      }
    else
      {
      # store the current line we do
      $self->{sy} = int($yl+$h/2);
      # divide hoizontal, and put both up the stack
      push @{$self->{stack}}, [$xl,$yl,$xr,$self->{sy},$level+1];
      push @{$self->{stack}}, [$xl,$self->{sy},$xr,$yr,$level+1];

      # we divided, and have still to do the line between the halves
      my $y = $self->{sy};
      my $x = $xl+1;
      do 
        {
        $self->_mandel_draw_point($x, $y, $cache->[$x]->[$y] =
          $self->_mandel_point($x,$y) );
        } while (++$x < $xr);
      }
    }
  print "\r Done. Calculated $self->{points} of ",
   $self->width()*$self->height(), " points.       \n";
  print "Took ",int(($self->app()->ticks - $self->{start}) / 10)/100,
   " seconds\n";
  $self->app()->title("SDL::FPS::App Mandel demo");
  $self->{points} = 0;
  $self->{state} = 3;		# all done
  }

sub _mandel_recolor
  {
  # redraw the screen with a different color scheme based on the cache
  my $self = shift;

  my $cache = $self->{cache};
  for (my $x = 0; $x < $self->{width}; $x++)
    {
    for (my $y = 0; $y < $self->{height}; $y++)
      {
      my $color = $cache->[$x]->[$y] || 0;
      next if $color == 0;		# black
      my $c = $self->{color};
  
      $c->r(($self->{color_bias_red} + $color) & 0xff);	
      $c->g(($self->{color_bias_green} + $color) & 0xff);	
      $c->b(($self->{color_bias_blue} + $color) & 0xff);	

      $self->{app}->pixel($x,$y,$c);
      }
    }

  }

sub _mandel_draw_point
  {
  my ($self,$x,$y,$color) = @_;

  $self->{points}++;
  return if $color == 0;		# black

  # by reusing a SDL::Color object we gain speed
  my $c = $self->{color};
  
  $c->r(($self->{color_bias_red} + $color) & 0xff);	
  $c->g(($self->{color_bias_green} + $color) & 0xff);	
  $c->b(($self->{color_bias_blue} + $color) & 0xff);	

  $self->{app}->pixel($x,$y,$c);
  }

sub _mandel_iterative
  {
  # this routine calculates the all points in the mandelbrot fractal in a step
  # by step manner. It stops after atleast 150 ms
  my $self = shift;

  return if $self->{state} != 1;

  my $r = $self->{rect}; 

  my $now = $self->app()->ticks();
  my $w = $self->{width};
  my $h = $self->{height};
  my $app = $self->{app};

  my $lastcolor = 0; my $c = $self->{black};
  do
    {
    my $y = $self->{y};
    do
      {
      my $x = $self->{x};
      my $color = $self->_mandel_point($x,$y);
      if ($color != 0)
        {
        if ($lastcolor != $color)
	  {
	  # re-use SDL::Color object
          $c = $self->{color};
          $c->r( ($self->{color_bias_red} + $color) & 0xff );
          $c->g( ($self->{color_bias_green} + $color) & 0xff );
          $c->b( ($self->{color_bias_blue} + $color) & 0xff );
          }
	# XXX TODO
        # If there are more than 1 point with the same color, we
        # could fill a 1-pixel rectangle or draw a line for speed:
        $self->{app}->pixel($x,$y,$c);
        $lastcolor = $color;
        }
      return if ($self->app()->ticks() - $now > 150);
      } while (++$self->{x} < $w);
    $self->{x} = 0;
    } while (++$self->{y} < $h);
  print "Took ",int(($self->app()->ticks - $self->{start}) / 10)/100,
   " seconds\n" if $self->{state} != 2;
  $self->{state} = 2;		# all done
  }

sub _mandel_point
  {
  # calculate the mandelbrot fractal at one point
  my ($self,$x,$y) = @_;

  if ($use_perl != 0)
    {
    return Math::Fractal::Mandelbrot->point($x,$y);
    }

  my $x1 = $self->{x1}; 
  my $x2 = $self->{x2};
  my $y1 = $self->{y1};
  my $y2 = $self->{y2};

  # setup start parameters
  my $ca = $x1 + $x * ($x2 - $x1) / $self->{width};
  my $cb = $y1 + $y * ($y2 - $y1) / $self->{height};
  my $za = 0;
  my $zb = 0;
  my $za2 = 0;
  my $zb2 = 0;

  my $iter = 0; my ($za1,$zb1);
  my $max_iter = $self->{max_iter};
  while ($iter++ < $max_iter)
    {
    $za1 = $za2 - $zb2 + $ca;
    $zb = 2 * $za * $zb + $cb;
    $za = $za1;
    $za2 = $za * $za;
    $zb2 = $zb * $zb;
    return $iter if $za2 + $zb2 > 5;
    }
  0;
  }

sub _mandel_setup
  {
  # setup the calculation to start all over
  my $self = shift;

  $self->{width} = $self->width();
  $self->{height} = $self->height();
  $self->{x1} = -2.2; 
  $self->{x2} = +1;
  $self->{y1} = -1.1;
  $self->{y2} = +1.1;
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{state} = 1;
  $self->{start} = $self->now();
  $self->{max_iter} = 600;
  # for recursive:
  $self->{done} = 0;
  $self->{stack} = [];
  $self->{cache} = [ ];
  $self->{points} = 0;
  $self->{rect} = SDL::Rect->new( -x => 0, -y => 0, -width => 1, -height => 1);
  for my $i (0..$self->{width})
    {
    $self->{cache}->[$i] = [];
    }
  if ($use_perl != 0)
    {
    Math::Fractal::Mandelbrot->set_max_iter($self->{max_iter});
    Math::Fractal::Mandelbrot->set_bounds(
     $self->{x1}, $self->{y1}, $self->{x2}, $self->{y2},
     $self->{width}, $self->{height},
     );
    }
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();

  # draw a bit (wit iterative or recursive method)
  &{$self->{method}}($self);

  $self->_update(); 
  }

sub _update
  {
  my $self = shift;
  # update the screen with the changes
  my $rect = SDL::Rect->new(
   -width => $self->{width}, -height => $self->{height});
  $self->app()->update($rect);
  }

sub resize_handler
  {
  my $self = shift;

  $self->{width} = $self->width();
  $self->{height} = $self->height();
  $self->_mandel_reset();
  print "Window resized!";
  }

sub post_init_handler
  {
  my $self = shift;
 
  $self->{black} = BLACK;
  # cache a SDL::Color object for speed
  $self->{color} = SDL::Color->new();

  $SDL::DEBUG = 0;  			# disable debug, it slows us down
  $self->_mandel_setup();
  #$self->{method} = \&_mandel_iterative;
  $self->{method} = \&_mandel_recursive;

  $self->{app} = $self->app();
  
  $self->{color_bias_blue} = 128;
  $self->{color_bias_green} = 0;
  $self->{color_bias_red} = 0;

  # state 0 => start calc
  # state 1 => in calc
  # state 2 => done

  $self->{demo}->{group_all} = $self->add_group();

  # set up the default event handlers
  $self->watch_event (
    quit => 'SDLK_q', fullscreen => 'f', freeze => 'SDLK_SPACE',
   );

  # setup the event handlers that are always active
  my $group = $self->{demo}->{group_all};
  $group->add(
    $self->add_event_handler (SDL_KEYDOWN, SDLK_s, 
     sub { my $self = shift; $self->_mandel_setup(); $self->_mandel_reset(); }),
    
    $self->add_event_handler (SDL_KEYDOWN, SDLK_1, 
     sub {
      my $self = shift; $self->{method} = \&_mandel_iterative;
      $self->_mandel_reset();
      }),
    
    $self->add_event_handler (SDL_KEYDOWN, SDLK_2,
     sub {
       my $self = shift; $self->{method} = \&_mandel_recursive;
       $self->{sub_method} = 1;
       $self->_mandel_reset();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_b,
     sub {
       my $self = shift;
       $self->{color_bias_blue} = 128;
       $self->{color_bias_green} = 0;
       $self->{color_bias_red} = 0;
       $self->_mandel_recolor();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_r,
     sub {
       my $self = shift;
       $self->{color_bias_blue} = 0;
       $self->{color_bias_green} = 0;
       $self->{color_bias_red} = 128;
       $self->_mandel_recolor();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_g,
     sub {
       my $self = shift;
       $self->{color_bias_blue} = 0;
       $self->{color_bias_green} = 128;
       $self->{color_bias_red} = 0;
       $self->_mandel_recolor();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_y,
     sub {
       my $self = shift;
       $self->{color_bias_blue} = 0;
       $self->{color_bias_green} = 128;
       $self->{color_bias_red} = 128;
       $self->_mandel_recolor();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_p,
     sub {
       my $self = shift;
       $self->{color_bias_blue} = 128;
       $self->{color_bias_green} = 0;
       $self->{color_bias_red} = 128;
       $self->_mandel_recolor();
       }),

    $self->add_event_handler (SDL_KEYDOWN, SDLK_3,
     sub {
       my $self = shift; $self->{method} = \&_mandel_recursive;
       $self->{sub_method} = 2;
       $self->_mandel_reset();
       }),

    $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_LEFT, 
     \&_mandel_zoom, 5),
    $self->add_event_handler (SDL_MOUSEBUTTONDOWN, BUTTON_MOUSE_RIGHT, 
     \&_mandel_zoom, 1/2),

    );
  }
       
sub _mandel_reset
  {
  my $self = shift;
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{state} = 1;
  $self->{start} = $self->now();
  $self->{done} = 0;
  $self->{stack} = [];
  $self->{cache} = [ ];
  $self->{points} = 0;
  my $rect = SDL::Rect->new(
   -width => $self->{width}, -height => $self->{height});
  $self->app()->fill($rect,$self->{black});
  for my $i (0..$self->{width})
    {
    $self->{cache}->[$i] = [];
    }
  if ($use_perl != 0)
    {
    Math::Fractal::Mandelbrot->set_bounds(
      $self->{x1}, $self->{y1}, $self->{x2}, $self->{y2},
      $self->{width}, $self->{height},
      );
    }
  }

sub _mandel_zoom
  {
  my ($self,$handler,$event,$factor) = @_;
  $self->_mandel_reset();

  # figure out where mouse has hit
  my $xm = $event->motion_x(); 
  my $ym = $event->motion_y();
  my $xs = ($self->{x2} - $self->{x1}) / $self->{width};
  my $ys = ($self->{y2} - $self->{y1}) / $self->{height};
  my $xc = $self->{x1} + $xs * $xm;
  my $yc = $self->{y1} + $ys * $ym;
  if ($factor > 1)
    {
    # zooming in, so calculate a bit further
    $self->{max_iter} += 500;		# 5/1
    }
  else
    {
    # zooming out, so step back
    $self->{max_iter} -= 200;		# 1/2
    }
  $factor *= 2;
  $xs = ($self->{x2} - $self->{x1});
  $ys = ($self->{y2} - $self->{y1});
  $self->{x1} = $xc - $xs / $factor;
  $self->{x2} = $xc + $xs / $factor;
  $self->{y1} = $yc - $ys / $factor;
  $self->{y2} = $yc + $ys / $factor;
  if ($use_perl != 0)
    {
    Math::Fractal::Mandelbrot->set_max_iter($self->{max_iter});
    Math::Fractal::Mandelbrot->set_bounds(
     $self->{x1}, $self->{y1}, $self->{x2}, $self->{y2},
     $self->{width}, $self->{height},
     );
    }
  }

1;

__END__

