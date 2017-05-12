
# example subclass of SDL::App::FPS - check keypresses

package SDL::App::FPS::MyKeyCheck;

# (C) 2003,2006 by Tels <http://bloodgate.com/>

use strict;

use SDL::App::FPS qw/
  BUTTON_MOUSE_LEFT
  BUTTON_MOUSE_MIDDLE
  BUTTON_MOUSE_RIGHT
  /;
use SDL;
use SDL::App::FPS::EventHandler qw/char2key/;

use base qw/SDL::App::FPS/;

##############################################################################
# routines that are usually overriden in a subclass

sub draw_frame
  {
  # draw one frame, usually overrriden in a subclass.
  my ($self,$current_time,$lastframe_time,$current_fps) = @_;

  }

sub post_init_handler
  {
  my $self = shift;

  # set up the event handlers
    
  my $handler = $self->add_event_handler (SDL_KEYDOWN,
   [ SDLK_q ,SDLK_LCTRL , SDLK_LSHIFT ], 
   sub { my $self = shift; $self->quit(); } ); 
  $handler->require_all_modifiers(1);
  $handler->ignore_additional_modifiers(0);

  foreach my $char ('a' .. 'z', '0' ..  '9')
    {
    my $handler = $self->add_event_handler (SDL_KEYDOWN, char2key($char),
     sub {
       my $self = shift;
       print "You pressed '$char'\n";
       $self->{pressed}->{$char}++;
       } );
    $handler->ignore_additional_modifiers(0);
    }

  foreach my $char ('A' .. 'Z')
    {
    my $handler = $self->add_event_handler (SDL_KEYDOWN, 
      # SLDK_LSHIFT will be silently remapped to KMOD_LSHIFT :)
      # due to bug in SDL_perl up to v1.20.0, we can't use KMOD_foo
      [ char2key(lc($char)), SDLK_LSHIFT, SDLK_RSHIFT ],
     sub {
       my $self = shift;
       print "You pressed '$char'\n";
       $self->{pressed}->{$char}++;
       } );
    $handler->ignore_additional_modifiers(1);
    }

  foreach my $char ('a' .. 'z')
    {
    my $handler = $self->add_event_handler (SDL_KEYDOWN,
      # due to bug in SDL_perl up to v1.20.0, we can't use KMOD_foo, so
      # use SDL::
      [ char2key(lc($char)), SDL::KMOD_LCTRL, SDL::KMOD_RCTRL ],
     sub {
       my $self = shift;
       print "You pressed '^$char'\n";
       $self->{pressed}->{"^$char"}++;
       } );
    $handler->ignore_additional_modifiers(1);
    }

  }

1;

__END__

