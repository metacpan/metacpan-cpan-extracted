
# sample subclass of SDL::App::FPS for testing timers

package SDL::App::MyFPS2;

# (C) by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass. If necc., this might
  # call $self->handle_event().
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  SDL::Delay(120);  
  }
  
1;

__END__

