#!/usr/bin/perl -w 
#	App.pm
#
#	The application object, sort of like a surface
#
#	David J. Goehrig Copyright (C) 2000
#
#       Tweaks and Additions by Wayne Keenan

package SDL::App;
use strict;
use Carp;
use Exporter();
use vars qw(@ISA @EXPORT);

use SDL::sdlpl;
use SDL::Surface;

@ISA = qw(SDL::Surface Exporter);

#
# Constants
#

my %constant_lookup =(); #internal
my @constants=qw(
		 SDL_INIT_TIMER          
		 SDL_INIT_AUDIO          
		 SDL_INIT_VIDEO          
		 SDL_INIT_CDROM          
		 SDL_INIT_JOYSTICK       
		 SDL_INIT_NOPARACHUTE
		 SDL_INIT_EVENTTHREAD	
		 SDL_INIT_EVERYTHING  		 
		 SDL_SWSURFACE 
		 SDL_HWSURFACE 
		 SDL_ANYFORMAT 
		 SDL_HWPALETTE 
		 SDL_HWACCEL	
		 SDL_SRCCOLORKEY	
		 SDL_RLEACCELOK	
		 SDL_RLEACCEL	
		 SDL_SRCALPHA	
		 SDL_SRCCLIPPING	 		     
		 SDL_ASYNCBLIT		 
		 SDL_RESIZABLE	
		 SDL_DOUBLEBUF 
		 SDL_FULLSCREEN
		 SDL_OPENGL
		 SDL_OPENGLBLIT		 
		);

@EXPORT = map { "&$_" }  @constants;



#tis only deals with constants defined as functions;
foreach my $constant (@constants)
  {
   my $func = $constant;
   
   #create the constant function
   my $sdl_func_call ="SDL::sdlpl::".lc($func);
   eval "sub $constant { $sdl_func_call; }";
   
   #this allows 'reverse' engineering the values from ints to
   #symbolic names, it should only be used internally for any
   #human friendly debug dumps.

   $constant_lookup{eval "&$sdl_func_call"}=$constant;
  }





#
# App Constructor / Destructor
#


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my %options = @_;

	my $self={};
	bless $self,$class;
	
	if (@_) # user has supplied some details in the constrctor 
	  {
	   my $if = $options{-init}   || 0;
	   my $t  = $options{-title}      || "";
	   my $it = $options{-icon_title} || $t;
	   my $ic = $options{-icon}   || "";
	   my $w  = $options{-width}  || 0;
	   my $h  = $options{-height} || 0;
	   my $d  = $options{-depth}  || 0;
	   my $f  = $options{-flags}  || &SDL_ANYFORMAT;
	   
	   #these were the original (pre v1.08) flags, lets be back compat:
	   my $init_flags = $if ||  (SDL::sdlpl::sdl_init_audio()
				     | SDL::sdlpl::sdl_init_video()
				     | SDL::sdlpl::sdl_init_cdrom()
				    );
	   
	   $self->init_subsys($init_flags);
	   
	   $self->{width}=$w;
	   $self->{height}=$h;
	   $self->{depth}=$d;
	   $self->{flags}=$f;
	   
	   $self->title($t, $it) ;
	   $self->title($ic);	   

	   $self->init_mode() unless exists($options{-postpone_init_mode});	   
	  }
	else
	  {	   
	   $self->init_sys(0); #do minimal SDL init;
	  }

	return $self;
}	

sub init_subsys
  {
   my $self=shift;
   my $sys_flags=shift || 0;
   croak SDL::sdlpl::sdl_get_error() unless not SDL::sdlpl::sdl_init($sys_flags);
  }


DESTROY
  {
   my $self=shift;
   SDL::sdlpl::sdl_fini();
  }

sub init_mode
  {
   my $self=shift;
   $self->video_mode($self->{width},
		     $self->{height},
		     $self->{depth},
		     $self->{flags},
		    );
  }

#
# Set title bar & icon title
#



sub title 
  {
   my $self = shift;
   my $title = shift;
   my $icon_title  = shift || $title;
   
   SDL::sdlpl::sdl_wm_set_caption($title,$icon_title) if $title;
   return SDL::sdlpl::sdl_wm_get_caption();
}

sub icon
  {
   my $self=shift;
   my $icon_file=shift;
   if ($icon_file and -e $icon_file)
     {
      my $icon = new SDL::Surface( -name => $icon_file);
      SDL::sdlpl::sdl_wm_set_icon($icon->{-surface});	   
     }    
  }

#
# Set a delay
#

sub delay {
	my $self = shift;
	my $delay = shift;
	SDL::sdlpl::sdl_delay($delay);
}

#
# Get ticks from start
#

sub ticks {
	return SDL::sdlpl::sdl_get_ticks();
}

#
# Get pending error messages if any
#
	
sub error {
	return SDL::sdlpl::sdl_get_error();
}

sub clear_error {
	return SDL::sdlpl::sdl_clear_error();
}

#keyboard handling,  will go in SDL::Keyboard.pm

sub prep_keystate
  {
   SDL::sdlpl::sdl_prep_key_state();
  }

sub keystate
  {
   my $self=shift;
   my $k=shift;
   SDL::sdlpl::sdl_key_state($k);
  }


#
# Pointer warping
#

sub warp {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	SDL::sdlpl::sdl_warp_mouse($x,$y);
}
#
# SDL_TEXTWIDTH Fri May 26 11:13:04 EDT 2000
#
# I added this function so that one can get the width of a string
#

sub SDL_TEXTWIDTH {
 carp "this is deprecated, use 'SDL::Font::text_width' instead ";
 return SDL::sdlpl::sdl_sfont_text_width(join('',@_));
}


sub toggle_fullscreen
  {
   my $self=shift;
   SDL::sdlpl::sdl_wm_toggle_fullscreen($self->{-surface});
  }

sub video_mode_ok
  {
   #Not an object method, but lets be nice...allow both!
   shift @_ if(ref($_[0]) eq  __PACKAGE__); #eat the (possible) self ref;
   my ($width,$height,$bpp,$flags)= @_;

   return SDL::sdlpl::sdl_video_mode_ok($width,$height,$bpp,$flags);
  }

sub video_mode
  {
   my $self=shift;
   my ($width,$height,$bpp,$flags)= @_;

   SDL::sdlpl::sdl_free_surface($self->{-surface}) if exists($self->{-surface});
   $self->{-surface} =SDL::sdlpl::sdl_set_video_mode($width,$height,$bpp,$flags) or die SDL::sdlpl::sdl_get_error();

   return;
  }

sub compile_info
  {
   return (SDL::sdlpl::sdl_compiled_version_minor,
	   SDL::sdlpl::sdl_compiled_version_major,
	   SDL::sdlpl::sdl_compiled_version_patch,
	  )
  }

sub link_info
  {
   return (SDL::sdlpl::sdl_linked_version_minor,
	   SDL::sdlpl::sdl_linked_version_major,
	   SDL::sdlpl::sdl_linked_version_patch,
	  );
  }

sub endianess
  {
   return SDL::sdlpl::sdl_endianess() ? "big": "little";
	   
  }

1;

__END__;

=head1 NAME

SDL::App - a SDL perl extension

=head1 SYNOPSIS

  $app = new SDL::App ( -title => 'FunkMeister 2000', 
			-icon_title => 'FM2000',
			-icon => 'funkmeister.png', 
			-width => 400, 
			-height => 400 );

=head1 DESCRIPTION


This Object is a composite made up of a few surfaces,
and strings.  This object does the setup for the SDL
library, and greates the base application window.  

The options that the constructor takes are:
	
-title =>	the title bar of the window
-icon_title =>	the title bar of the icon
-icon =>	the icon image file
-flags =>	the SDL_* surface flags for the	default window
-width =>	of the app window
-height =>	of the app window
-depth =>	the bit depth of the window

=head2 Additional Methods

	In addition to initilizing the SDL library, the app class
provides access to a couple miscellaneous functions that all programs
may need:

	$app->delay(milliseconds);

Delay will cause a delay of roughly the specified milliseconds. Since
this only runs in multi-tasking environments, the exact number is not
assured.

	$app->ticks();

Ticks returns the number of clock ticks since the program was started.

	$app->error();

Error returns any pending SDL related error messages.  It returns an
empty string if no errors are pending, making it print friendly.

	$app->warp(x,y);

Will move the cursor to the location x,y.

=head1 AUTHOR

David J. Goehrig

=head1 SEE ALSO

perl(1) SDL::Surface(3) SDL::Mixer(3) SDL::Event(3) SDL::Cdrom(3).

=cut	

