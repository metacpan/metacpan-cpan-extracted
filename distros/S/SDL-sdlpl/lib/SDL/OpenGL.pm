#!/usr/bin/perl -w
# 
#	OpenGL.pm
#
#	Wayne Keenan Copyright (O) 2000

package SDL::OpenGL;


@ISA = qw(Exporter);
use strict;
use SDL::sdlpl;

use Exporter();
use vars qw(@EXPORT);

#
# Constants
#

my @constants=qw(
		 SDL_GL_RED_SIZE
		 SDL_GL_GREEN_SIZE
		 SDL_GL_BLUE_SIZE
		 SDL_GL_ALPHA_SIZE
		 SDL_GL_ACCUM_RED_SIZE
		 SDL_GL_ACCUM_GREEN_SIZE
		 SDL_GL_ACCUM_BLUE_SIZE
		 SDL_GL_ACCUM_ALPHA_SIZE
		 SDL_GL_BUFFER_SIZE
		 SDL_GL_DEPTH_SIZE
		 SDL_GL_STENCIL_SIZE
		 SDL_GL_DOUBLEBUFFER
		);


@EXPORT = map { "&$_" }  @constants;


my %constant_lookup =();

foreach my $constant (@constants)
{
 my $func = $constant;

 #create the Packaged scoped constant function
 my $sdl_func_call ="SDL::sdlpl::".lc($func);
 eval "sub $constant { $sdl_func_call(); }";
 $constant_lookup{eval "$sdl_func_call()"}=$constant;
}






#
# App Constructor / Destructor
#

sub new 
  {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my %options = @_;
   
   my $self={};
   bless $self,$class;
   return $self;
  }	


#OpenGL

sub set_attribute
  {
   my $self=shift;
   my $attr=shift;
   my $value=shift;
   
   $self->{GL_ATTRIBUTES}{$attr}=$value; #helper: record vars (to keep 'track' of them)
   return SDL::sdlpl::sdl_gl_set_attribute($attr, $value);
  }

sub get_attribute
  {
   my $self=shift;
   my $attr=shift;
   
   return SDL::sdlpl::sdl_gl_get_attribute($attr);
  }



sub swap_buffers
  {
   my $self=shift;
   
   return SDL::sdlpl::sdl_gl_swap_buffers();
  }



#helper functions

sub get_attributes
  {
   my $self=shift;
   my %copy=%{$self->{GL_ATTRIBUTES}};

   my %new=();
   foreach my $key (keys %copy)
     {
      my $constant_name=$constant_lookup{$key};
      my ($new_name)=$constant_name =~ /SDL_GL_(.*)$/;    #rename so we dont get CONSTANT confusion

      $new{$new_name} = $copy{$key};   #make Human readable;
      $new{$key}      = $copy{$key};   #ensure we could use the original CONSTATNS if we want too.
     }
   return \%new;
  }



1;



__END__;

=head1 NAME

SDL::OpenGL - a SDL perl extension

=head1 SYNOPSIS

Provides OpenGL bits to SDL-Perl, please look at the examples.

=head1 DESCRIPTION


=head2 Additional Methods


=head1 AUTHOR

Wayne Keenan

=head1 SEE ALSO

perl(1) SDL::Surface(3) SDL::Mixer(3) SDL::Event(3) SDL::Cdrom(3).

=cut	

