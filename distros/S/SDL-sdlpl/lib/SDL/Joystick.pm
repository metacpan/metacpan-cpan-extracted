#!/usr/bin/perl -w 
# (o)2000  Wayne Keenan 

package SDL::Joystick;

use strict;
use Carp;
use Exporter();
use vars qw(@EXPORT @ISA);


@ISA = qw(Exporter);

my %constant_lookup=();
my @constants=qw(
		 SDL_HAT_CENTERED
		 SDL_HAT_UP
		 SDL_HAT_RIGHT
		 SDL_HAT_DOWN
		 SDL_HAT_LEFT
		 SDL_HAT_RIGHTUP
		 SDL_HAT_RIGHTDOWN
		 SDL_HAT_LEFTUP
		 SDL_HAT_LEFTDOWN
		);

@EXPORT = map { "&$_" }  @constants;

#this only deals with constants defined as functions;
foreach my $constant (@constants)
  {
   my $func = $constant;
   
   #create the constant function
   my $sdl_func_call ="SDL::sdlpl::".lc($func);
   eval "sub $constant { $sdl_func_call; }";
   
   #this allows reverse engineering the values from ints to
   #symbolic names, it should only be used internally for any
   #human friendly debug dumps.
   
   $constant_lookup{eval "&$sdl_func_call"}=$constant;
  }


sub new 
  {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   
   my $self={};
   bless $self, $class;
   
   
  }


sub joysticks
  {
   my $self = shift;
   
   SDL::sdlpl::sdl_num_joysticks(  );
  }


sub name
  {
   my $self = shift;
   my $index=shift;
   
   SDL::sdlpl::sdl_joystick_name( $index );
  }


sub open
  {
   my $self = shift;
   my $index=shift;
   
   SDL::sdlpl::sdl_joystick_open( $index );
  }


sub opened
  {
   my $self = shift;
   my $index=shift;
   
   SDL::sdlpl::sdl_joystick_opened( $index );
  }


sub index
  {
   my $self = shift;
   my $joystick=shift;
   
   SDL::sdlpl::sdl_joystick_index( $joystick );
  }


sub num_axes
  {
   my $self = shift;
   my $joystick=shift;
   
   SDL::sdlpl::sdl_joystick_num_axes( $joystick );
  }


sub num_balls
  {
   my $self = shift;
   my $joystick=shift;
   
   SDL::sdlpl::sdl_joystick_num_balls( $joystick );
  }


sub num_hats
  {
   my $self = shift;
   my $joystick=shift;
   
   SDL::sdlpl::sdl_joystick_num_hats( $joystick );
  }


sub num_buttons
  {
   my $self = shift;
   my $joystick=shift;
   
   SDL::sdlpl::sdl_joystick_num_buttons( $joystick );
  }


sub update
  {
   my $self = shift;
   
   SDL::sdlpl::sdl_joystick_update(  );
  }


sub event_state
  {
   my $self = shift;
   my $state=shift;
   
   SDL::sdlpl::sdl_joystick_event_state( $state );
  }


sub get_axis
  {
   my $self = shift;
   my $joystick=shift;
   my $axis=shift;
   
   SDL::sdlpl::sdl_joystick_get_axis( $joystick,$axis );
  }


sub get_hat
  {
   my $self = shift;
   my $joystick=shift;
   my $hat=shift;
   
   SDL::sdlpl::sdl_joystick_get_hat( $joystick,$hat );
  }


sub get_ball
  {
   my $self = shift;
   my $joystick=shift;
   my $ball=shift;
   my $dx=shift;
   my $dy=shift;
   
   SDL::sdlpl::sdl_joystick_get_ball( $joystick,$ball,$dx,$dy );
  }


sub get_button
  {
   my $self = shift;
   my $joystick=shift;
   my $button=shift;
   
   SDL::sdlpl::sdl_joystick_get_button( $joystick,$button );
  }


sub close
  {
   my $self = shift;
   my $joystick=shift;
   
   SDL::sdlpl::sdl_joystick_close( $joystick );
}


1;
