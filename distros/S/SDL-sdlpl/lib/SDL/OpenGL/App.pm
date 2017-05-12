#!/usr/bin/perl -w
#(c)2000 Wayne Keenan


package SDL::OpenGL::App;

use strict;
use Carp;
use Getopt::Long;
use IO::File;
use Data::Dumper;

#export some constants
use Exporter;
use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);

@EXPORT = qw(&SDL_GL_APP_QUIT
	     &SDL_GL_APP_CONTINUE
	     &SDL_GL_APP_SKIP_BUILTIN_EVENTS
	     &SDL_GL_APP_SKIP_USER_EVENTS
	     );


sub SDL_GL_APP_QUIT { 0 };
sub SDL_GL_APP_CONTINUE { 1 };
sub SDL_GL_APP_SKIP_BUILTIN_EVENTS { 2 };
sub SDL_GL_APP_SKIP_USER_EVENTS { 3 };



use OpenGL;# qw(:all); #having some 'fun' with this one!

use SDL::App;
use SDL::Event;
use SDL::Cursor;     
use SDL::OpenGL;







my $frames=1;
my $previous_ticks=1;  
my $spin=1;
my $sdl_gl_attr_defaults = {
			    RED_SIZE     => 5,
			    GREEN_SIZE   => 5,
			    BLUE_SIZE    => 5,			       
			    DEPTH_SIZE   => 16,
			    DOUBLEBUFFER => 1
			   };

my $sdl_gl_app_defaults = {
			   app_name       => "SDL_OpenGL_App",
			   screen_width   => 256,
			   screen_height  => 256,
			   fullscreen     => 0,
			   glinfo         => 0,
			   fps            => 1,
			   bpp            => 16,
			   video_flags    => SDL_RESIZABLE | SDL_OPENGL,
			   };

####################################################################

sub new
  {
   my $class=shift;   
   my $self=bless {}, $class;

   $self->init();   

   return $self;
  }



sub init
  {
   my $self=shift;

   $self->{HANDLER}= {
		      init    => \&default_init,    #set-up default handlers
		      draw    => \&default_draw,
		      events  => \&default_events,
		      idle    => \&default_idle,
		      reshape => \&default_reshape,
		      keyboard=> sub {},
		      mouse   => sub {},
		      motion  => sub {},

		     };

   $self->{SDL_GL_APP}  = $sdl_gl_app_defaults,
   $self->{SDL_GL_ATTR} = $sdl_gl_attr_defaults,
   $self->{sdl_mouse_x}    = 0;
   $self->{sdl_mouse_y}    = 0;
   $self->{sdl_mouse_show} = 1;


   #I still think these know 'too' much ( about $self->{SDL_GL_APP} ), hmm, could tie.
   #actually, it's kinbd-a broken, but it works!
   $self->add_startup_parameter(
				NAME => "glinfo",
				HELP => "Display GL implementation information",
				TYPE => "!", 
				VAR  => \$self->{SDL_GL_APP}{glinfo},
			       );

   $self->add_startup_parameter(
				NAME => "width",
				HELP => "Screen width",
				TYPE => ":i", 
				VAR  => \$self->{SDL_GL_APP}{screen_width}
			       );

   $self->add_startup_parameter(
				NAME => "height",
				HELP => "Screen height",
				TYPE => ":i", 
				VAR  => \$self->{SDL_GL_APP}{screen_height}
			       );

   $self->add_startup_parameter(
				NAME => "fps",
				HELP => "Display Frames Per Second",
				TYPE => "!", 
				VAR  => \$self->{SDL_GL_APP}{fps}
			       );

   $self->add_startup_parameter(
				NAME => "fullscreen",
				HELP => "Fullscreen mode",
				TYPE => "!", 
				VAR  => \$self->{SDL_GL_APP}{fullscreen}
			       );

   #however, this doesn't know/do a lot!
   $self->add_runtime_help(
			   KEY  => "ESC",
			   HELP => "Quit app",
			  );

  }



DESTROY
  {
   my $self=shift;
   #print Dumper $self;
  }




sub add_startup_parameter
  {
   my $self=shift;
   my %param_info=@_;

   my $name    =$param_info{NAME};
   my $type    =$param_info{TYPE};
   my $var_ref =$param_info{VAR};
   my $help_str=$param_info{HELP};

   $self->{START_UP_PARAMS}{"$name$type"}=$var_ref;
   $self->{START_UP_HELP}{$name}=$help_str;

  }



sub add_runtime_help
  {
   my $self=shift;
   my %param_info=@_;

   my $key     =$param_info{KEY};
   my $help_str=$param_info{HELP};

   $self->{RUNTIME_HELP}{$key}=$help_str;

  }




sub register_handler
  {
   my $self=shift;
   my %handlers = @_;

   foreach my $handler (keys %handlers)
     {
      my $sub_ref=$handlers{$handler};
      my $ref_type=ref($sub_ref) || "NOT_A_REF";

      if ($ref_type eq "CODE")
	{
	 $self->{HANDLER}{$handler}=$sub_ref;	 
	}
      else
	{
	 croak "register_handler was not passed a valid subroutine ref (passed a '$ref_type' for '$handler')";
	}
     }   
  }



sub run
  {        
   my $self=shift;
   my $once=shift || 0;
   my $done_once=$self->{DONE_ONCE};

   $self->_get_startup_options() unless $done_once;   

   my $app  =$self->{SDL_APP};
   my $gl   =$self->{SDL_GL};
   my $event=$self->{SDL_EVENT};

   $self->_init() unless $done_once;
   
   $self->_reshape($app, $gl) unless $done_once;
   
   my $continue = SDL_GL_APP_CONTINUE;
   while ( ($continue=$self->_events($event)) != SDL_GL_APP_QUIT ) 
     {
      $self->_draw($app, $gl);
      $self->_idle($app, $gl);
      last if $once;
    }
   
   return $continue;
  }


sub pump
  {
   my $self=shift;
   my $continue=$self->run(1);
   $self->{DONE_ONCE}=1;
   return $continue;
  }

sub pointer_show
  {
   my $self=shift;
   my $val=shift || 0;
   print "mouse $val\n";
   $self->{sdl_mouse_show}=$val;
  }

#ignore these, they need to be package/object method aware:
sub ___mouse_off
  {
   my $self=shift;
   if (exists($self->{DONE_ONCE}))
     {
      SDL::Cursor::show(0);         
     } 
   else
     {
      carp "SDL as not been initialised";
     }
  }

sub ___mouse_on
  {
   my $self=shift;
   if (exists($self->{DONE_ONCE}))
     {      
      SDL::Cursor::show(1);   
     } 
   else
     {
      carp "SDL as not been initialised";
     }
  }

#build some App attribute accessors

foreach my $app_attr (keys %$sdl_gl_app_defaults)
  {
   my $code= '
   sub '.lc($app_attr).'
     {
      my $self=shift;      
      @_ ? $self->{SDL_GL_APP}{'.$app_attr.'}=shift     
      : $self->{SDL_GL_APP}{'.$app_attr.'};                  
     }';#'
   eval $code;  
  }


#build some GL attribute accessors

foreach my $gl_attr (keys %$sdl_gl_attr_defaults)
  {
   my $code= '
  sub gl_attr_'.lc($gl_attr).'
    {
   my $self=shift;   
   @_ ? $self->{SDL_GL_ATTR}{'.$gl_attr.'}=shift     
     : $self->{SDL_GL_ATTR}{'.$gl_attr.'};            
  }';#'   
    eval $code;
 }
 



# Private members club, dont you know.:
 
sub _get_startup_options
  {
   my $self=shift;
   
   GetOptions(
	      %{$self->{START_UP_PARAMS}},
	      #"help|info|usage" => blarg....
	     ) or $self->_usage() ;
  }
 
 
###########################################
# parent dispatch handlers


sub _init
  {
   my $self=shift;

   $self->video_flags(SDL_RESIZABLE | SDL_OPENGL | ($self->fullscreen?SDL_FULLSCREEN:0));
   
   #SDL Main surface prep   
   my $app = new SDL::App ( -title  => $self->app_name,
			    -flags  => $self->video_flags,
			    -width  => $self->screen_width,
			    -height => $self->screen_height, 
			    -bpp    => $self->bpp,
			    -postpone_init_mode => 1  #for OPENGL init
			  );    

   # SDL OpenGL prep
   my $gl    = new SDL::OpenGL;
   
   $gl->set_attribute( SDL_GL_RED_SIZE,     $self->gl_attr_red_size);
   $gl->set_attribute( SDL_GL_GREEN_SIZE,   $self->gl_attr_green_size);
   $gl->set_attribute( SDL_GL_BLUE_SIZE,    $self->gl_attr_blue_size);
   
   $gl->set_attribute( SDL_GL_DEPTH_SIZE,   $self->gl_attr_depth_size);
   $gl->set_attribute( SDL_GL_DOUBLEBUFFER, $self->gl_attr_doublebuffer);

   $app->init_mode();

   #my $cursor= new SDL::Cursor;
   #$cursor->warp($self->{sdl_mouse_x},$self->{sdl_mouse_y});    

   #hmm, somethings wrong...
   if ($self->{sdl_mouse_show} ==1)
     {
      #SDL::Cursor::show(1);    
     }
   else
     {
      SDL::Cursor::show(0);    
     }
   
  # SDL Event init
   my $event = new SDL::Event;
   $event->set(SDL_SYSWMEVENT,SDL_IGNORE);
   
   #$event->set_key_repeat(1,1);
   
   
   
   if ($self->glinfo)
     {
      my $exts=" ".OpenGL::glGetString(GL_EXTENSIONS);
      $exts =~ s!\s!\n\t!g;
      print "Vendor     : ". OpenGL::glGetString( GL_VENDOR)   ."\n";
      print "Renderer   : ". OpenGL::glGetString( GL_RENDERER) ."\n";
      print "Version    : ". OpenGL::glGetString( GL_VERSION)  ."\n";
      print "Extensions : ". $exts ."\n";      

      print Dumper $gl->get_attributes();
     }
   
   $self->{SDL_APP}=$app;
   $self->{SDL_GL}=$gl;
   $self->{SDL_EVENT}=$event;

   &{$self->{HANDLER}{init}};  #call user init func
   
  }


sub _reshape
  {
   my $self=shift;

   my $h=$self->{HANDLER}{reshape};
   &$h($self->screen_width, $self->screen_height);
  }


sub _idle
  {
   my $self=shift;

   my $app=$self->{SDL_APP};
   
   if ($self->fps)
     {
      my $present_ticks = $app->ticks(); 
      $frames++;

      if ($present_ticks - $previous_ticks >= 5000) 
	{
	 my $seconds = ($present_ticks - $previous_ticks) / 1000;
	 my $fps     = $frames / $seconds;
	 print "$frames frames in $seconds seconds = $fps FPS\n";
	 ($frames, $previous_ticks) = (0, $present_ticks);
	}
      
     }
   
   
   &{$self->{HANDLER}{idle}};  #call user idle func
  }


sub _draw
  {
   my $self=shift;

   my $gl=$self->{SDL_GL};
   my $h=$self->{HANDLER}{draw};

   &$h(); #call user draw func

   $gl->swap_buffers();   
  }


sub _events
  {
   my $self=shift;
   my $event=$self->{SDL_EVENT};
   $event->pump;

   #if ($event->poll )  # any events pending? 
   #(NOTE: skippped the check beacuse we seem to take a performace hit, not too sure why)

   $event->poll;
     {
      my $type=$event->type;      
      return SDL_GL_APP_QUIT if ($type == SDL_QUIT );  #we 'have (???)' to quit

      my $user_reshape_handler   =$self->{HANDLER}{reshape};
      if ($type == SDL_VIDEORESIZE)
	{
	 my ($w, $h)= ($event->resize_width,
		       $event->resize_height);
	 $self->screen_width($w);
	 $self->screen_height($h);
	 $self->{SDL_APP}->video_mode($self->screen_width,
				     $self->screen_height, 
				     $self->bpp,
				     $self->video_flags
				    );

	 &$user_reshape_handler($w,$h);
	}
      my $user_event_handler   =$self->{HANDLER}{events};
      my $user_rc=&$user_event_handler($event); #call user event func

      
      #override ALL SDL::OpenGL:;App parent events (namely ESC)
      #when someone moans you can't skip the built in and still execute user callbacks
      #I'll change this to use a bit mask, or blessed reg-ex's, depending on how I'm feeling.
      #or if you want it, add it, "I double dare you muddy fumpster..."
      return SDL_GL_APP_CONTINUE if ($user_rc==SDL_GL_APP_SKIP_BUILTIN_EVENTS);          

      my $keysym=$event->key_sym;
      my $keymod=$event->key_mod;

      # ALT-Enter: toggle fullscreen 
      if( $type       == SDL_KEYDOWN 
	  and $keysym == SDLK_RETURN 
	  and $keymod &  KMOD_ALT ) 
	{
	 $self->{SDL_APP}->toggle_fullscreen() 
	}

      #user quit?
      return SDL_GL_APP_QUIT if ( $keysym == SDLK_ESCAPE );      
      
      #override key,mouse,motion SDL::OpenGL:;App parent events
      return SDL_GL_APP_CONTINUE if ($user_rc==SDL_GL_APP_SKIP_USER_EVENTS);          

      #process key,mouse,motion events as normal;
      my $user_keyboard_handler=$self->{HANDLER}{keyboard};
      my $user_mouse_handler   =$self->{HANDLER}{mouse};
      my $user_motion_handler  =$self->{HANDLER}{motion};

      #key presses
      if ( $type == SDL_KEYDOWN ) 
	{      
	 
	 &$user_keyboard_handler ({
				   KEY_NAME => $event->key_name,
				   MOUSE_X => $self->{sdl_mouse_x},
				   MOUSE_Y => $self->{sdl_mouse_y},
				   
				  });
	 return SDL_GL_APP_CONTINUE;	 	 
	}
      
      #mouse presses
      if ($type == SDL_MOUSEBUTTONDOWN or  $type == SDL_MOUSEBUTTONUP ) 
	{
	 &$user_motion_handler(
			       {
				MOUSE_X      => $event->button_x,
				MOUSE_Y      => $event->button_y,
				MOUSE_BUTTON => $event->button,
				MOUSE_STATE  => $event->button_state,
			       });
	 return SDL_GL_APP_CONTINUE;
	}

      #mouse motion
      if ($type == SDL_MOUSEMOTION ) 
	{
	 my $mx=$self->{sdl_mouse_x}=$event->motion_x;
	 my $my=$self->{sdl_mouse_y}=$event->motion_y;
	 &$user_motion_handler(
			       {
				MOUSE_X => $mx,
				MOUSE_Y => $my,
				MOUSE_X_REL => $event->motion_xrel,
				MOUSE_Y_REL => $event->motion_yrel,
			       });
	 return SDL_GL_APP_CONTINUE;
	 
	 #now that should keep the glut people (almost happy), now I've done it,
	 #I could just have created 1 hash to pass to all three callbacks...
	 #..but I'm not 120% sure on the equivalence of button_X|Y and motion_X|Y.
	}
     }
   return SDL_GL_APP_CONTINUE;
  }



sub _usage
  {
   my $self=shift;

   my $format="%-20s%-60s\n";
   my $hr="=" x 60 ."\n";
   print $hr;

   print "Start-up options:\n\n";
   
   my $startup_help=$self->{START_UP_HELP};

   foreach my $name (sort keys %$startup_help)
    {
      my $help = $startup_help->{$name};
      print sprintf($format,$name,$help);
    }


   print "\nRuntime keys:\n\n";

   my $runtime_help=$self->{RUNTIME_HELP};

   foreach my $name (sort keys %$runtime_help)
     {
      my $help = $runtime_help->{$name};
      print sprintf($format,$name,$help);
     }

   print "\n$hr\n";
  }


############################################################
# just some frilly bits to check stoof works

sub  default_init
  {
   my $logo= rle_dec(_get_logo());
   my $logo_tex = read_texture(FILE_DATA=> $logo);
   
   my (       
       $w,$h,$image,
       $gl_internal_format,
       $gl_format,
       $gl_type,
       $level, $border,) = (
			    $logo_tex->{WIDTH},
			    $logo_tex->{HEIGHT},
			    $logo_tex->{DATA},
			    $logo_tex->{FORMAT},
			    $logo_tex->{INTERNAL_FORMAT},
			    $logo_tex->{TYPE},
			    0, 0,
		     );

   glClearColor(0,0,0,1);
   glColor3f (1.0, 1.0, 1.0);
   
   glShadeModel (GL_FLAT);
   glEnable(GL_DEPTH_TEST);
   glDepthFunc(GL_LESS);

   glTexImage2D(GL_TEXTURE_2D, 
		$level, $gl_format, $w,$h, $border, 
		$gl_internal_format, $gl_type, $image);

   glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
   glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
   glEnable(GL_TEXTURE_2D);

   #glEnable(GL_BLEND);
  }




# new window size or exposure 
sub  default_reshape
  {
   my ($width, $height)=@_;   
   my $h = $height / $width;
   glViewport(0, 0, $width, $height);
   
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   gluPerspective(60.0, 1.0 , 1.0, 30.0);   
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();

  }


# draw a frame
sub  default_draw
  {
   my $rad=3.14159/180;

   glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
   glLoadIdentity ();
   glTranslatef(0.0, 0.0, -2 *sin ($rad*$spin) -5);
   glPushMatrix();
   glRotatef(360*sin($rad*$spin   ),1,0,0);
   glRotatef(360*cos($rad*$spin*.5),0,1,0);
   glRotatef(360*sin($rad*$spin*.25),0,0,1);
   {
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 1.0); glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f(1.0, -1.0, 0.0);
    glEnd();
   }
   glPopMatrix();
   glFlush();
   $spin++
  }

sub  default_idle
  {
  }

sub default_events
  {
   return SDL_GL_APP_CONTINUE;
  }


####################################################
# utility funcs


sub screendump
   {
    my $self=shift;
    my %args= (
	       FILE_NAME    => undef,
	       FORMAT       => "PPM",    #'hardcoded' to this, for now
	       SUB_FORMAT   => "RAW",    #e.g. PPM format (RAW for now)
	       GL_FORMAT    => GL_RGB,
	       GL_TYPE      => GL_UNSIGNED_BYTE,
	       @_,
	      );
    my ($x, $y, $width,$height)= ( 0,0,
				   $self->screen_width,  $self->screen_height,
				 );
    my $size=$width*$height*3;
    my $pixels=chr(0) x $size;  #MUST prealloc scalar to right size

    OpenGL::glReadPixels_s($x,$y, 
			   $width, $height,
			   $args{GL_FORMAT},
			   $args{GL_TYPE},
			   $pixels,
			  );
    my $fh= new IO::File $args{FILE_NAME} ,"w" or croak "opening for write, $!";
    binmode $fh;  
    
    print $fh "P6\n";
    print $fh "# Generated by 'SDL::OpenGL::App' for '".$self->app_name."', ".scalar(localtime)."\n";
    print $fh "$width $height\n";
    print $fh "255\n";
    print $fh $pixels;

    undef $fh;
   }

sub read_texture
   {
    my %args= (
	       FILE_HANDLE  => undef,
	       FILE_NAME    => undef,
	       FILE_DATA    => undef,
	       FORMAT       => "PPM",    #'hardcoded' to this, for now
	       SUB_FORMAT   => "RAW",    #e.g. PPM format (RAW or ASCII)
	       PIXEL_FORMAT => "RGB",    #fixed to this
	       
	       @_,
	      );
    my ($width, $height, $data) = (0,0,"");
    
    my $file_name=$args{FILE_NAME};
    my $file_handle=$args{FILE_HANDLE};
    my $file_data=$args{FILE_DATA};
    

  SWITCH:
    {
     $file_name
     && $args{SUB_FORMAT} eq "ASCII"
       && do 
	 {
	  ($width, $height, $data)= _read_ascii_ppm($file_name);
	  last SWITCH;
	 };

     $args{SUB_FORMAT} eq "RAW"
       && do 
	 {
	  ($width, $height, $data)= _decode_ppm_raw($file_data);
	  last SWITCH;
	 }

    }

    #return meta info and raw data
    return {
	    WIDTH  => $width,
	    HEIGHT => $height,
	    DATA   => $data,           #TODO properly 
	    INTERNAL_FORMAT =>  3,      # GL internal format (1-4, or one of 38 symbolic consts)
	    FORMAT => GL_RGB,           # GL format 
	    TYPE   => GL_UNSIGNED_BYTE, # GL type
	    #could also make use of image magick to create mip maps! (but that goes elsewhere)
	   };
   }



sub _decode_ppm_raw
   {
    my $file_data=shift;
    my (
     $width, 
     $height,
     $depth,
     $data) = $file_data =~  
       /^
	 [^\n]*\n                      #skip  format id
	 [^\n]*\n                      #skip coment
	 (\d+)\s+(\d+)\n         #width, height
	 (\d+)\n                 #depth
	 (.*)$                   #data
       /xmgs;     
    
    my $size=$width*$height*3;
    print length $data;
    print "\n$size\n\n";
    ($width>=64 && $height>=64 && $width<10000 && $height<10000) || croak "strange sizes $width,$height";
    ($depth =~ /255/) or croak "Depth should be 255";
    
    #($size == $#image +1) || die "array length $#image +1  differs from expected size $size" ; 
    
    return ($width,$height,$data);
   }

#taken from an example in Perl-OpenGL 0.5 by Kenneth Albanowski.
sub _read_ascii_ppm
  {
   # reads in an ascii ppm format image file
   # returns the list (width,height,packed rgb image data)
   #
   # I'm not to familiar with the ppm file format 
   # this subroutine may not work for all valid ppm files
   #
   my($file) = @_;
   my($w,$h,$image);
   my @image=();
   open(PPM,"<$file") || croak "cant open $file";
   binmode PPM;
   (<PPM>);							# the first line is just a header: "P3"
   (<PPM>);							# The second line is a comment 
   ($_=<PPM>);							# the 3rd line gives width and height
   m/(\d+)\s+(\d+)/; 
   $w=$1 ; $h=$2 ;
   ($w>=64 && $h>=64 && $w<10000 && $h<10000) || croak "strange sizes $w,$h";
   ($_=<PPM>);							# 4th line is depth (should be 255)
   (/255/) || croak " improper depth $_";
   
   $image="";

   while(<PPM>) 
     {
      chop;
      $image .= $_ . " ";
     }

   @image=split(/\s+/,$image);
   my $size=$w*$h*3;
   ($size == $#image +1) || croak "array length $#image +1  differs from expected size $size" ; 
   $image=pack("C$size",@image);
   close(PPM);
   return ($w,$h,$image);
}


#some pretty basic compression, not suitable for detailed textures AT ALL.
sub rle_enc_file
   {
    my $file=shift;
    my $fh= new IO::File $file, "r" or croak "open, $!";
    local $/;
    undef $/;
    my $data=<$fh>;
    return rle_enc($data);
   }


sub rle_dec
   {
    my $squished=shift;
    my $unsquished=$squished;
    
    $unsquished =~ s/\G(..)(..)/
      chr(hex($1)) x hex($2)
      /gex;

    return $unsquished;
   }


sub rle_enc
   {
    my $data=shift;
    my $squished="";

    my $pos=0;
    while ($pos < length $data)
      {
       my $rep=1;
       my $char=substr ($data, $pos, 1);

       $squished.= sprintf ("%02x", ord $char);
       
       for (
	    ;
	    (substr($data, $pos+$rep, 1) eq $char) 
	    && ($rep < 255)
	    && ($pos+$rep < length $data)
	    ; 
	    $rep++
	   )
	 {
	 }
       $squished.=sprintf ("%02x", $rep);
       
       $pos+=$rep;
      }
    return $squished;
   
   }



sub _get_logo
   {
#The (RLE encoded PPM) OpenGL logo:
return
"500136010a0123012001430152014501410154014f0152013a0120015401680165012001470149014d01500127017301200150014e014d012001460169016c017401650172012001560165017201730169016f016e01200131012e0130010a01360134012001360134010a01320135020a0100ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00c302012801ce015301ff2005016901ff01008a010117018401ff4200020101006f010112015301ff5402012801a50100601201ff3e8401ff024101ff023301ff022801ff02ce01ff1a005504011201ff2d2801ff02000107011e01002b0101040105018401ff0d004bce01ff29000105011701004304011201a501ff050045ff2403013301ce010096ff2100010a012801005802010a013301ff0204015301ff0100392801ff2600514101ff14000d01010501ff06001eff1bce01ff023301ff0b0001010107010048ff1b000103010a01000601012801a501ff06001bff1b000d01010401ff0600451201ff0b000901011e018401ff09000601012801a501ff06001bff1800020201001001010701ff060042ff0900110201ff09000301012801a501ff06001a0301ff180015ff0600410201ff060015ce01ff08000301012801a501ff060018010112015301ff150001040112010015ff1800080101ff0c000304015301ff100002010100010a012801ff0600190501170101010a013301000301012801a501ff06001804015301ff160018ff0f000402010701ff060003ff0600050201ff0607018401ff070006ff0607018401ff07000c05018401ff0105018401ff0105018401ff0105018401ff0105018401ff010a01ce01ff01000301012801a501ff06001904011201ff15a501ff020015ff0c000b0101ff031701ff05000cff09000cff0c00091201ff14000301012801a501ff06001bff180015ff0c000cff1e000cff0c5301ff0200070a012801ff12000301012801a501ff06001bff1b000fff06000107011e01ff06000cff09000c5301ff08000cff0f000103010d01000fff09000301012801a501ff06001b03014101ff1c000702010a01ff090003ff0603013301ce010006ff06000101010501ff031e01ff0200064101ff054101ff05000cff060003ff0f3301ff11000301012801a501ff18000cff271701ff020006ff1200010301120100035301ff0e03013301ff0105015301ff04000cff0600050101ff1502013301ce01ff06000301012801a501ff1b000b0101ff21000cff060001010103012801ff0203015301ff01000e01011701ff020a01ce01ff01000701010701ff03000c8401ff021701ff02000905018401ff0a1e01ff020006ff06000405011e01ff18000103010d01000c010117015301ff211e01ff020006ff0600910a012801ff2d0096ff2d01010d0141010037040112010a01ce01ff011e01ff0503013301ff01004e05018401ff373301ff02010112014101000103010a01000e01010001010107010a01a501ff16005a05018401ff5b0a01ff02006801014101ff4a0a01a501ff01007c05011e02ff2f4101ff0201011201530100ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00e7";
}
 1;


=head1 NAME

SDL::OpenGL::App  - Glut like wrapper for SDL OpenGL apps

=cut


=head1 SYNOPSIS

   
 use SDL::OpenGL::App;
 
 my $app=new SDL::OpenGL::App;

 $app->app_name("Gears");

 $app->register_handler(init    => \&init,
			draw    => \&draw,
			events  => \&events,
			idle    => \&idle,
			reshape => \&reshape,
		       );
 
 
 $app->run();


=head1 DESCRIPTION
   

=head1 METHODS

   new
   add_startup_parameter
   add_runtime_help
   register_handler
   pointer_show
   run
   pump
   screendump
   
   app_name
   screen_width
   screen_height
   fullscreen
   fps
   glinfo

   red_size
   green_size
   blue_size
   depth_size
   doublebufer

   Package utility methods:

   read_texture
   rle_enc
   rle_dec
=head1 EXAMPLES


=head2 QUICK DEMO/TEST

Running the in-built demo/test:

run perl with the 'e' flag to execute these one liners: 

'use SDL::OpenGL::App; new SDL::OpenGL::App->run'

same, but in fullscreen mode:

'use SDL::OpenGL::App; $g=new SDL::OpenGL::App; $g->fullscreen(1); $g->run'

=head2 PUMPING

'Pumping' the SDL::OpenGL::App processing loop, step by step:

Make use of the 'pump' function, say, when called from
a Gtk Idle loop for instance:

my $gl_app=new SDL::OpenGL::App ;

#register handlers/help as normal

my $stay_alive=1;
while ($stay_alive)
  {   
   my $gl_rc=$gl_app->pump();  #returns FALSE when 'reasons to leave' detected

   $stay_alive=0 unless $gl_rc;
  }


=head2 MAKE A MOVIE!

   NOTE:: currently (as from V1.06) only RAW PPM files are generated, but
   then SDL::OpenGL::App can only read ASCII/RAW PPM file anyway, for now.

   To create a series of screenshots to build a movie, e.g. to build
   OpenGL looking graphics for a 'flatter' application(s) (game/web/etc..):


 #do things as usual, then

 my $frame=0;
 my $frame_ext_format="%d"; #you may want leading 8 zeros hex, e.g, : "%08x"
 sub idle 
   {
    
    #..do your 'Idle' stuff..
    
    $gl_app->screendump(FILE_NAME=>"movie/gear.".sprintf($frame_ext_format,$frame++));
   }

to playback the movie, one quick way is to use the 'animate' program from ImageMagick:

$ animate movie/gear.*

Furthermore, you could then use 'read_texture' to read them all/it back in, to be used
as a (possibly animated) bill board, or drop OpenGL mode and then use them in 2D SDL Surfaces,
you choose.


For more examples please have a look inside the directory:
'examples/openGL/Glut'

=head1 TODO



=head1 BUGS

=head1 AUTHOR

   Wayne Keenan               wayne@metaverse.fsnet.co.uk

   Copyright (c) 2000 Wayne Keenan. All rights reserved.
   This program is free software; you can redistribute it
   and/or modify it under the same terms as Perl itself.



=head1 VERSION

   Version 0.02     (05 Aug 2000)

=head1 SEE ALSO

   perl(1) SDL::App SDL::OpenGL

=cut

