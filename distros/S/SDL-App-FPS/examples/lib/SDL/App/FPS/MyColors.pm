
# example of SDL::App::FPS demonstrating colors

package SDL::App::FPS::MyColors;

# (C) 2002, 2006 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS;
use SDL;
use SDL::App::FPS::Color qw/BLACK WHITE GRAY darken lighten blend/;

use base qw/SDL::App::FPS/;

##############################################################################

sub _draw_hor_line
  {
  my ($self,$x,$y,$l,$thick,$color) = @_;

  my $r = $self->{rect};
  $r->x($x);
  $r->y($y);
  $r->width($l);
  $r->height($thick);
  $self->app()->fill($r,$color);
  }

sub _draw_ver_line
  {
  my ($self,$x,$y,$l,$thick,$color) = @_;

  my $r = $self->{rect};
  $r->x($x);
  $r->y($y);
  $r->width($thick);
  $r->height($l);
  $self->app()->fill($r,$color);
  }

sub _draw_button
  {
  # draw the button "released" or "pressed" on the screen, depending on
  # what $hightlight and $shadow are, lines will be $thick thick
  my ($self,$b,$f) = @_;

  my $r = $self->{rect};
  $r->width($b->{w});
  $r->height($b->{h});
  $r->x($b->{x});
  $r->y($b->{y});
  $self->app()->fill($r,$f);

  my $thick = $b->{thick};
  my $deep = BLACK();
  my $high = WHITE();
  $self->_draw_hor_line($b->{x}        ,$b->{y}        ,$b->{w},$thick,$high);
  $self->_draw_ver_line($b->{x}        ,$b->{y}        ,$b->{h},$thick,$high);
  $self->_draw_hor_line($b->{x}        ,$b->{y}+$b->{h},$b->{w},$thick,$deep);
  $self->_draw_ver_line($b->{x}+$b->{w},$b->{y}        ,$b->{h},$thick,$deep);
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  #$self->pause(SDL_KEYDOWN);	# we don't draw anything

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  }

sub resize_handler
  {
  my $self = shift;

  $self->_draw_colors();
  }

sub _draw_colors
  {
  my $self = shift;

  # show off some color boxes

  $self->{rect} = SDL::Rect->new( -w => $self->width(), -h => $self->height());
  $self->app()->fill($self->{rect},GRAY);
  my $x = 20;
  for my $color (qw/RED GREEN BLUE GRAY/)
    {
    my $b = $self->_add_shape ($x,40,40,15,1);
    $self->_draw_button($b,SDL::App::FPS::Color->$color());
    my $c = 'LIGHT' . $color;
    $b = $self->_add_shape ($x,20,40,15,1);
    $self->_draw_button($b,SDL::App::FPS::Color->$c());
    $c = 'DARK' . $color;
    $b = $self->_add_shape ($x,60,40,15,1);
    $self->_draw_button($b,SDL::App::FPS::Color->$c());
    $x += 45;
    } 
  $x = 20;
  for my $color (qw/
    RED GREEN BLUE GRAY YELLOW ORANGE BROWN CYAN MAGENTA PURPLE/)
    {
    my $c = SDL::App::FPS::Color->$color();
    $b = $self->_add_shape ($x,200,40,35,1);
    $self->_draw_button($b,$c);

    $b = $self->_add_shape ($x,160,40,35,1);
    $self->_draw_button($b,lighten($c,0.3));
    
    $b = $self->_add_shape ($x,120,40,35,1);
    $self->_draw_button($b,lighten($c,0.6));
    
    $b = $self->_add_shape ($x,240,40,35,1);
    $self->_draw_button($b,darken($c,0.6));
    
    $b = $self->_add_shape ($x,280,40,35,1);
    $self->_draw_button($b,darken($c,0.3));

    $x += 45;
    }
  # white => color => black
  my $y = 120;
  for my $col (qw/DARKRED DARKBLUE/)
    {
    my $c = SDL::App::FPS::Color->$col();
    for (my $i = -100; $i < 100; $i++)
      {
      my $r;
      if ($i < 0)
        {
        $r = darken($c,-$i / 100); 
        }
      else
        {
        $r = lighten($c,$i / 100); 
        }
      $self->_draw_hor_line (485,$i+$y,130,1, $r);
      }
    $y += 220;
    }
  # color A => color B => color C
  $x = 20;
  my $start = BLACK;
  for my $col (qw/RED BLUE GREEN WHITE/)
    {
    my $c = SDL::App::FPS::Color->$col();
    for (my $i = 0; $i < 100; $i++)
      {
      my $r;
      $r = blend($start,$c,$i / 100); 
      $self->_draw_ver_line ($x++,380,32,1, $r);
      }
    $start = $c;
    }
  # color A => color B (sinus)
  $x = 20;
  $start = BLACK;
  for my $col (qw/RED BLUE GREEN WHITE/)
    {
    my $c = SDL::App::FPS::Color->$col();
    for (my $i = 0; $i < 100; $i++)
      {
      my $r;
      $r = blend($start,$c, sin(1.57 * $i / 100)); 
      $self->_draw_ver_line ($x++,420,32,1, $r);
      }
    $start = $c;
    }
  
  my $r = SDL::Rect->new(
   -width => $self->width(), -height => $self->height());
  $self->update($r);
  }

sub post_init_handler
  {
  my $self = shift;
 
  $self->_draw_colors();
  
  # set up some event handlers
  $self->watch_event ( 
    quit => SDLK_q, fullscreen => SDLK_f, freeze => SDLK_SPACE,
   );

  }

sub _add_shape
  {
  my ($self,$x,$y,$w,$h,$t) = @_;

  my $b = { 
    id => $self->{id}++,
    x => $x, y => $y, w => $w, h => $h,
    thick => $t || 1,
   };
  $b;
  }
  
1;

__END__

