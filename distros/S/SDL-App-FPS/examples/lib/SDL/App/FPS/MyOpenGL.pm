
# example of SDL::App::FPS demonstrating usage of OpenGL. Based on code from
# SDL_perl test/OpenGL/test2.pl

package SDL::App::FPS::MyOpenGL;

# (C) 2002-2003 by Tels <http://bloodgate.com/>

use strict;

use SDL::OpenGL;
use SDL::OpenGL::Cube;
use SDL::App::FPS qw/ FPS_EVENT /;
use SDL::Event;

use vars qw/@ISA/;
@ISA = qw/SDL::App::FPS/;

##############################################################################

sub _gl_draw_cube
  {
  my $self = shift;

  glDepthMask(GL_TRUE);			# enable writing to depth buffer

  glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glTranslate(0,0,-6.0);

  # compute the current angle based on elapsed time

  my $angle = ($self->current_time() / 5) % 360;
  my $other = ($self->current_time() / 7) % 360;

  glRotate($angle,1,1,0);
  glRotate($other,0,1,1);
 
  glDisable(GL_TEXTURE_2D);
  glColor(1,1,1);
  $self->{cube}->draw();
  }

sub _gl_init_view
  {
  my $self = shift;

  glViewport(0,0,$self->width(),$self->height());

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  if ( @_ )
    {
    glPerspective(45.0,4/3,0.1,100.0);
    }
  else
    {
    glFrustum(-0.1,0.1,-0.075,0.075,0.3,100.0);
    }

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
  glEnable(GL_CULL_FACE);
  glFrontFace(GL_CCW);
  glCullFace(GL_BACK);

  }

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  # using pause() would be a bit more efficient, though 
  return if $self->time_is_frozen();
       
  $self->_gl_draw_cube();

  }

sub resize_handler
  {
  my $self = shift;

  $self->_gl_init_view();
  }

sub post_init_handler
  {
  my $self = shift;

  $self->_gl_init_view();

  $self->{cube} = SDL::OpenGL::Cube->new();

  my @colors =  (
        1.0,1.0,0.0,    1.0,0.0,0.0,    0.0,1.0,0.0, 0.0,0.0,1.0,       #back
        0.4,0.4,0.4,    0.3,0.3,0.3,    0.2,0.2,0.2, 0.1,0.1,0.1 );     #front

  $self->{cube}->color(@colors);

  $self->add_event_handler (FPS_EVENT, 'speed_up',
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('2',1500);           # ramp up
     });
  $self->add_event_handler (FPS_EVENT, 'slow_down',
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('0.3',1500);         # ramp down
     });
  $self->add_event_handler (FPS_EVENT, 'normal_speed',
   sub {
     my $self = shift;
     return if $self->time_is_ramping() || $self->time_is_frozen();
     $self->ramp_time_warp('1',1500);           # ramp to normal
    });

  }

1;

__END__

