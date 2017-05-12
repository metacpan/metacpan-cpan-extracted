
# example of SDL::App::FPS demonstrating clickable areas (aka buttons)

package SDL::App::FPS::MyMouse;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT

  /;
use SDL;
use SDL::App::FPS::Button qw/
  BUTTON_IN
  BUTTON_OUT
  BUTTON_HOVER
  BUTTON_CLICK
  BUTTON_UP
  BUTTON_DOWN
  BUTTON_RECTANGULAR
  /;
use SDL::App::FPS::Color
  qw/BLACK WHITE RED GREEN BLUE YELLOW GRAY DARKGRAY LIGHTGRAY/;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

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
  my ($self,$b,$f,$high,$deep) = @_;

  my $r = $self->{rect};
  $r->width($b->{w});
  $r->height($b->{h});
  $r->x($b->{x});
  $r->y($b->{y});
  $f = $b->{fill} unless defined $f;
  $self->app()->fill($r,$f);

  my $thick = $b->{thick};
  $deep = $b->{deep} unless defined $deep;
  $high = $b->{high} unless defined $high;
  $self->_draw_hor_line($b->{x}        ,$b->{y}        ,$b->{w},$thick,$high);
  $self->_draw_ver_line($b->{x}        ,$b->{y}        ,$b->{h},$thick,$high);
  $self->_draw_hor_line($b->{x}        ,$b->{y}+$b->{h},$b->{w},$thick,$deep);
  $self->_draw_ver_line($b->{x}+$b->{w},$b->{y}        ,$b->{h},$thick,$deep);
  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  $self->_draw_button($self->{hover_rect});
  if ($self->{clicked} == 0)
    {
    $self->_draw_button($self->{clicked_rect},$self->{darkgray});
    }
  else
    {
    $self->_draw_button($self->{clicked_rect});
    }

  if ($self->{hover} != 0)
    {
    $self->_draw_button($self->{hover_rect});
    $self->{hover} = 0;
    }
  else
    {
    $self->_draw_button($self->{hover_rect},$self->{darkgray});
    }

  # update the screen with the changes
  my $r = SDL::Rect->new(
   -width => $self->width(), -height => $self->height());
  $self->update($r);

  }

sub resize_handler
  {
  my $self = shift;

  $self->{rect} = SDL::Rect->new( -w => $self->width(), -h => $self->height());
  $self->app()->fill($self->{rect},$self->{gray});

  $self->_draw_button ($self->{hover_rect},$self->{darkgray});
  $self->_draw_button ($self->{in_out_rect},$self->{darkgray});
  $self->_draw_button ($self->{clicked_rect},$self->{darkgray});
  foreach $b (keys %{$self->{buttons}})
    {
    $self->_draw_button($self->{buttons}->{$b});
    }
  }

sub post_init_handler
  {
  my $self = shift;
 
  $self->{rectangles} = {};
  $self->{id} = 0;
  
  $self->{black} = BLACK;
  $self->{white} = WHITE;
  $self->{lightgray} = LIGHTGRAY;
  $self->{gray} = GRAY;
  $self->{darkgray} = DARKGRAY;
  $self->{red} = RED;
  $self->{blue} = BLUE;
  $self->{green} = GREEN
  $self->{yellow} = YELLOW;

  $self->{rect} = SDL::Rect->new( -w => $self->width(), -h => $self->height());
  $self->app()->fill($self->{rect},$self->{gray});

  $self->{hover_rect} = $self->_add_shape(40,120,20,10,1,
    $self->{red},$self->{black},$self->{white});
  $self->{hover} = 0;
  $self->{clicked} = 0;
  $self->{in_out_rect} = $self->_add_shape(40,140,20,10,1,
    $self->{blue},$self->{black},$self->{white});
  $self->{clicked_rect} = $self->_add_shape(40,160,20,10,1,
    $self->{green},$self->{black},$self->{white});
  $self->{focus_rect} = $self->_add_shape(40,180,20,10,1,
    $self->{yellow},$self->{black},$self->{white});
  
  $self->_draw_button ($self->{hover_rect},$self->{darkgray});
  $self->_draw_button ($self->{in_out_rect},$self->{darkgray});
  $self->_draw_button ($self->{clicked_rect},$self->{darkgray});

  $self->{PI} = 3.141592654;

  my $b = $self->_add_button(40,20,64,32, 1,
    $self->{gray},$self->{lightgray},$self->{darkgray});
  
  $b = $self->_add_button(40,60,64,32, 1,
    $self->{gray},$self->{lightgray},$self->{darkgray});

  # the quit button
  
  $b = $self->_add_button(40,240,64,32, 1,
    $self->{lightgray},$self->{white},$self->{black}, 
    sub { 
      my $self = shift;
      $self->add_timer(300, 1, 0, 0, sub {my $self = shift; $self->quit();} );
    } );
  
  $b = $self->_add_area(1, 120,20,128,256, 2,
    $self->{gray},$self->{darkgray},$self->{lightgray});
  
  $b = $self->_add_area(0, 300,20,128,256, 1,
    $self->{gray},$self->{darkgray},$self->{lightgray});
   
  $b = $self->_add_area(1, 320,40,40,20, 1,
    $self->{gray},$self->{lightgray},$self->{darkgray});

  # set up the event handlers
  $self->watch_event ( 
    quit => SDLK_q, fullscreen => SDLK_f, freeze => SDLK_SPACE,
   );

  }

sub _add_shape
  {
  my ($self,$x,$y,$w,$h,$t,$f,$hi,$de) = @_;

  my $b = { 
    id => $self->{id}++,
    x => $x, y => $y, w => $w, h => $h,
    thick => $t,
    fill => $f, high => $hi, deep => $de,
   };
  $b;
  }
  
sub _add_button
  {
  my ($self,$x,$y,$w,$h,$t,$f,$hi,$de,$callback) = @_;

  my $b = $self->_add_shape($x,$y,$w,$h,$t,$f,$hi,$de);
  $self->_draw_button($b);

  my $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
    BUTTON_DOWN, BUTTON_RECTANGULAR, BUTTON_MOUSE_LEFT, sub {
     my $self = shift;
     my $button = shift;
     $self->_draw_button($b,$f,$de,$hi);
     #print "$button->{id} down!\n" 
    } );
  $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
    BUTTON_UP, BUTTON_RECTANGULAR, BUTTON_MOUSE_LEFT, sub {
     my $self = shift;
     my $button = shift;
     #print "$button->{id} up!\n"; 
     $self->_draw_button($b,$f);
    } );
  $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
    BUTTON_CLICK, BUTTON_RECTANGULAR, BUTTON_MOUSE_LEFT, sub {
     my $self = shift;
     my $button = shift;
     #print "$button->{id} clicked!\n"; 
     $self->{clicked} = 1 - $self->{clicked};
     if (defined $callback)
       {
       &$callback($self);
       }
    } );
  $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
    BUTTON_OUT, BUTTON_RECTANGULAR, 0, sub {
     # if user drags mouse outside, raise the button
     my $self = shift;
     my $button = shift;
     $self->_draw_button($b,$f);
    } );
  $self->{buttons}->{$b->{id}} = $b;
  }

sub _add_area
  {
  my ($self,$react,$x,$y,$w,$h,$t,$f,$hi,$de) = @_;

  my $b = $self->_add_shape($x,$y,$w,$h,$t,$f,$hi,$de);
  $self->_draw_button($b);
  if ($react != 0)
    {
    my $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
      BUTTON_HOVER, BUTTON_RECTANGULAR, 0, sub {
       my $self = shift;
       my $button = shift;
       $self->{hover} = 1;
       #print "$button->{id} hover!\n" 
      } );
    $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
      BUTTON_IN, BUTTON_RECTANGULAR, 0, sub {
       my $self = shift;
       my $button = shift;
       $self->_draw_button($self->{in_out_rect},$self->{blue});
       #print "$button->{id} in!\n" 
      } );
    $button = $self->add_button($x+($w/2),$y+($h/2),$w,$h, 
      BUTTON_OUT, BUTTON_RECTANGULAR, 0, sub {
       my $self = shift;
       my $button = shift;
       $self->_draw_button($self->{in_out_rect},$self->{darkgray});
       #print "$button->{id} in!\n" 
      } );
    }
  $self->{buttons}->{$b->{id}} = $b;
  }

1;

__END__

