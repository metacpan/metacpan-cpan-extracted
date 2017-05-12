#!/usr/bin/perl
use strict;
use warnings;
use SDL;
use SDL::OpenGL;
use SDL::Event;
use SDL::OpenGL::Cg qw/:all/;

# Initialise everything.
$|++;
print "A shader will be run which will set the colour of all OpenGL graphics\n";
print "The shader will simply be controlled to change the colour of shapes\n";
print "  and then the demonstration will terminate\n";

init_sdl();
open_screen();
init_gl();
init_cg();

# Now keep redrawing the screen.
for (my $scale = 0.0; $scale<1.5; $scale +=0.005) {
  draw_scene($scale);
  swap_buffers();
  SDL::Delay(20);
}

# Tidy up after ourselves.
tidy_cg();
print "Shutting down\n";

sub init_sdl {
  # Initialise the video part of SDL
  if (SDL::Init(SDL_INIT_VIDEO())) {
    die ("Error: ".SDL::GetError());
  }
}

sub open_screen {
  # Create a window.
  my $depth = 32;
  unless (SDL::SetVideoMode(800, 600, $depth, SDL_OPENGL)) {
    die ("Error: ".SDL::GetError());
  }
}

sub init_gl {
  # Set up an OpenGL context for us.
  SDL::GLSetAttribute (SDL_GL_DOUBLEBUFFER, 1);
  SDL::GLSetAttribute (SDL_GL_RED_SIZE, 6);
  SDL::GLSetAttribute (SDL_GL_GREEN_SIZE, 6);
  SDL::GLSetAttribute (SDL_GL_BLUE_SIZE, 6);
  glClearColor (0,0,0,0);

  glViewport(0,0,800,600);
  glMatrixMode(GL_PROJECTION);
  glFrustum(-0.1,0.1,-0.075,0.075,0.175,100.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  # Swap buffers so we have a clear screen.
  swap_buffers();
}

{
  my $context;
  my $vertex_program;
  my $profile;
  my $color_param;
  my $modelview_param;

  sub init_cg {
    # Since this is being developed partly on Radeon9000 the
    #  ARBVP1 profile is the only one supported.  Use it for
    #  this demo.
    $profile = CG_PROFILE_ARBVP1();
    unless (cgIsProfileSupported($profile)) { 
      die ("ARBVP1 is not available");
    }
    unless (cgEnableProfile($profile)) {
      die ("Cannot enable ARBVP1: ".SDL::OpenGL::GetErrorString());
    }

    # Create the CG Context object we'll be attaching programs
    #  to.
    $context = cgCreateContext();
    # Compile the vertex shader program from a file.
    my $file = '../shaders/vertex/anycolor.cg';
    $vertex_program = cgCreateProgramFromFile(
      $context,CG_SOURCE(),$file,CG_PROFILE_ARBVP1,'main',undef);
    unless ($vertex_program) {
      die ("Error: ".cgGetErrorString());
    }

    # Now load the program onto the GPU, and make it the active
    #  shader.
    unless (cgLoadProgram($vertex_program)) {
      die ("Error: ".cgGetErrorString());
    }
    unless (cgBindProgram($vertex_program)) {
      die ("Error: ".cgGetErrorString());
    }

    # The shader has a parameter, 'constantColor' which is a
    #  float4 which indicates which colour to shade everything.
    $color_param = cgGetNamedParameter($vertex_program,'constantColor');
    unless ($color_param) {
      die ("Error: ".cgGetErrorString());
    }

    # The shader has a parameter 'modelViewProj' which is a float4x4
    #  indicating the current modelview.
    $modelview_param = cgGetNamedParameter($vertex_program, 'modelViewProj');
    unless ($modelview_param) {
      die ("Error: ".cgGetErrorString());
    }
  }

  sub set_color {
    my ($r,$g,$b,$a) = @_;
    cgSetParameter($color_param,$r,$g,$b,$a);
  }
 
  sub update_modelview {
    cgSetStateMatrixParameter($modelview_param,
      CG_MODELVIEW_PROJECTION_MATRIX(),
      CG_MATRIX_IDENTITY()) or die ("Error: ",cgGetErrorString(),"\n");
  }

  sub tidy_cg {
    cgDestroyContext($context);
    cgDisableProfile($profile);
  }
}

sub draw_scene {
  my $scale = shift || 1.0;
  set_color($scale,1-$scale,($scale*2)%1,1);
  glLoadIdentity();
  glTranslate(-1.5,0,-6);
  update_modelview();
  glBegin(GL_TRIANGLES());
    glVertex(0,1,0);
    glVertex(-1,-1,0);
    glVertex(1,-1,0);
  glEnd();
  glTranslate(3,0,0);
  update_modelview();
  glBegin(GL_QUADS());
    glVertex(-1,1,0);
    glVertex(1,1,0);
    glVertex(1,-1,0);
    glVertex(-1,-1,0);
  glEnd();
  glFlush();
}

sub swap_buffers {
  SDL::GLSwapBuffers();
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}
