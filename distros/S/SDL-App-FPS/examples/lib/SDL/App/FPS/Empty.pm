
# example subclass of SDL::App::FPS - benchmark overhead of empty draw_frame

package SDL::App::FPS::Empty;

# (C) 2002 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL::Event;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

#  if ($current_time - $self->{last} > 1000)
#    {
#    print "fps ",$self->current_fps(),
#          " min ",$self->min_fps()," max ", $self->max_fps(),"\n";
#    $self->{last} = $current_time;
#    }
  }

sub post_init_handler
  {
  my $self = shift;

  # set up the event handlers
  $self->watch_event (
    quit => 'SDLK_q', fullscreen => 'SDLK_f', freeze => 'SDLK_SPACE',
   ); 
  $self->{last} = $self->current_time();
  }

1;

__END__

