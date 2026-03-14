#!/usr/bin/perl -w
use strict;

our $PERL_VERSION = $^V;
$PERL_VERSION =~ s|^v||;

use OpenGL::Modern qw(glpSetAutoCheckErrors);
use OpenGL qw/
  :glconstants
  glGetString glGetError glpErrorString
  glGenTextures_p glBindTexture glTexParameteri glTexImage2D_c glTexEnvf
    glDeleteTextures_p
  glGenerateMipmapEXT
  glGenFramebuffersEXT_p glBindFramebufferEXT glFramebufferTexture2DEXT
    glCheckFramebufferStatusEXT glDeleteFramebuffersEXT_p
  glGenRenderbuffersEXT_p glBindRenderbufferEXT glRenderbufferStorageEXT
    glDeleteRenderbuffersEXT_p
  glFramebufferRenderbufferEXT
  glGenBuffersARB_p glBindBufferARB
    glMapBufferARB_c glUnmapBufferARB glDeleteBuffersARB_p
  glEnableClientState glDisableClientState
  glEnable glDisable glBlendFunc glDepthFunc glShadeModel
    glMatrixMode glLoadIdentity glLightfv_p glColorMaterial
    glTranslatef glRotatef
    glColor3f glColor4f
    glPushMatrix glPopMatrix glPushAttrib glPopAttrib
    glOrtho glFrustum
  glRasterPos2i glRasterPos2f
  glPixelZoom glReadPixels_c glDrawPixels_c
  glGetDoublev_c glGetIntegerv_c
  glClearColor glClearDepth glClear glViewport glDrawElements_c
/;
use OpenGL qw/
  glpHasGLUT glpCheckExtension glpFullScreen glpRestoreScreen
  glBufferDataARB_o glBufferSubDataARB_o
  glVertexPointer_o glNormalPointer_o glColorPointer_o glTexCoordPointer_o
/;
use OpenGL::GLUT qw/
  :constants :functions
/;
use OpenGL::Config;     # for build information

eval 'use OpenGL::Image 1.03';  # Need to use OpenGL::Image 1.03 or higher!
my $hasImage = !$@;
my $hasIM_635 = $hasImage && OpenGL::Image::HasEngine('Magick','6.3.5');

eval 'use OpenGL::Shader';
my $hasShader = !$@;

eval 'use Image::Magick';
my $hasIM = !$@;

eval 'use Time::HiRes qw( gettimeofday )';
my $hasHires = !$@;
$|++;


# ----------------------
# Based on a cube demo by
# Chris Halsall (chalsall@chalsall.com) for the
# O'Reilly Network on Linux.com (oreilly.linux.com).
# May 2000.
#
# Translated from C to Perl by J-L Morel <jl_morel@bribes.org>
# ( http://www.bribes.org/perl/wopengl.html )
#
# Updated for FBO, VBO, Vertex/Fragment Program extensions
# and ImageMagick support
# by Bob "grafman" Free <grafman@graphcomp.com>
# ( http://graphcomp.com/opengl )
#


# Requires GLUT/FreeGLUT
if (!glpHasGLUT())
{
  print <<'EOF';
    This test requires GLUT:
    If you have X installed, you can try the scripts in ./examples/
    Most of them do not use GLUT.

    It is recommended that you install FreeGLUT for improved Makefile.PL
    configuration, installation and debugging.
EOF
  exit 0;
}


use constant PROGRAM_TITLE => "OpenGL Test App";
use constant DO_TESTS => 0;


# Run in Game Mode
my $gameMode;
if (scalar(@ARGV) and lc($ARGV[0]) eq 'gamemode')
{
  $gameMode = $ARGV[1] || '';
}

# Keyboard modifiers
my $key_mods =
{
  eval(GLUT_ACTIVE_SHIFT) => "SHIFT",
  eval(GLUT_ACTIVE_CTRL) => "CTRL",
  eval(GLUT_ACTIVE_ALT) => "ALT"
};

# Some global variables.
my $hasFBO = 0;
my $hasVBO = 0;
my $idleTime = $hasHires ? gettimeofday() : time();
my $idleSecsMax = 8;
my $er;

# Window and texture IDs, window width and height.
my $Window_ID;
my $Window_Width = 300;
my $Window_Height = 300;
my $Inset_Width = 90;
my $Inset_Height = 90;
my $Window_State;

# Texture dimensions
my $Tex_File = 'test.tga';
my $Tex_Width = 128;
my $Tex_Height = 128;
my $Tex_Format;
my $Tex_Type;
my $Tex_Size;
my $Tex_Image;
my $Tex_Pixels;

# Our display mode settings.
my $Light_On = 0;
my $Blend_On = 1;
my $Texture_On = 1;
my $Alpha_Add = 1;
my $FBO_On = 0;
my $Inset_On = 1;
my $Fullscreen_On = 0;

my $Curr_TexMode = 0;
my @TexModesStr = qw/ GL_DECAL GL_MODULATE GL_BLEND GL_REPLACE /;
my @TexModes = ( GL_DECAL, GL_MODULATE, GL_BLEND, GL_REPLACE );
my($TextureID_image,$TextureID_FBO);
my $FrameBufferID;
my $RenderBufferID;
my $VertexProgID;
my $FragProgID;
my $FBO_rendered = 0;
my $Shader;

# Object and scene global variables.
my $Teapot_Rot = 0.0;

# Cube position and rotation speed variables.
my $X_Rot   = 0.9;
my $Y_Rot   = 0.0;
my $X_Speed = 0.0;
my $Y_Speed = 0.5;
my $Z_Off   =-5.0;

# Settings for our light.  Try playing with these (or add more lights).
my @Light_Ambient  = ( 0.1, 0.1, 0.1, 1.0 );
my @Light_Diffuse  = ( 1.2, 1.2, 1.2, 1.0 );
my @Light_Position = ( 2.0, 2.0, 0.0, 1.0 );

# Model/Projection/Texture/Colour Matrices, Viewport vector
my $mm = OpenGL::Array->new(16,GL_DOUBLE);
my $pm = OpenGL::Array->new(16,GL_DOUBLE);
my $tm = OpenGL::Array->new(16,GL_DOUBLE);
my $cm = OpenGL::Array->new(16,GL_DOUBLE);
my $vp = OpenGL::Array->new(4,GL_INT);

# Vertex Buffer Object data
my ($VertexObjID,$NormalObjID,$ColorObjID,$TexCoordObjID,$IndexObjID,$FpsVertObjID,$FpsNormObjID,$FpsColourObjID,$FpsIndObjID);

my @indices = (
  0,1,2,     2,3,0,
  4,5,6,     6,7,4,
  8,9,10,    10,11,8,
  12,13,14,  14,15,12,
  16,17,18,  18,19,16,
  20,21,22,  22,23,20,
);
my $indices = OpenGL::Array->new_list(GL_UNSIGNED_INT,@indices);

my @verts =
(
  -1.0, -1.3, -1.0, # bottom
  1.0, -1.3, -1.0,
  1.0, -1.3,  1.0,
  -1.0, -1.3,  1.0,

  -1.0,  1.3, -1.0, # top
  -1.0,  1.3,  1.0,
  1.0,  1.3,  1.0,
  1.0,  1.3, -1.0,

  -1.0, -1.0, -1.3, # far
  -1.0,  1.0, -1.3,
  1.0,  1.0, -1.3,
  1.0, -1.0, -1.3,

  1.3, -1.0, -1.0, # right
  1.3,  1.0, -1.0,
  1.3,  1.0,  1.0,
  1.3, -1.0,  1.0,

  -1.0, -1.0,  1.3, # near
  1.0, -1.0,  1.3,
  1.0,  1.0,  1.3,
  -1.0,  1.0,  1.3,

  -1.3, -1.0, -1.0, # left
  -1.3, -1.0,  1.0,
  -1.3,  1.0,  1.0,
  -1.3,  1.0, -1.0,
);
my $verts = OpenGL::Array->new_list(GL_FLOAT,@verts);

# Could calc norms on the fly
my @norms =
(
  0.0, -1.0, 0.0,
  0.0, -1.0, 0.0,
  0.0, 1.0, 0.0,
  0.0, 1.0, 0.0,
  0.0, 0.0,-1.0,
  0.0, 0.0,-1.0,
  1.0, 0.0, 0.0,
  1.0, 0.0, 0.0,
  0.0, 0.0, 1.0,
  0.0, 0.0, 1.0,
  -1.0, 0.0, 0.0,
  -1.0, 0.0, 0.0,
);
my $norms = OpenGL::Array->new_list(GL_FLOAT,@norms);

my @colors =
(
  0.9,0.2,0.2,.75, # red
  0.9,0.2,0.2,.75,
  0.9,0.2,0.2,.75,
  0.9,0.2,0.2,.75,

  0.5,0.5,0.5,.5, # grey
  0.5,0.5,0.5,.5,
  0.5,0.5,0.5,.5,
  0.5,0.5,0.5,.5,

  0.2,0.9,0.2,.5, # green
  0.2,0.9,0.2,.5,
  0.2,0.9,0.2,.5,
  0.2,0.9,0.2,.5,

  0.2,0.2,0.9,.25, # blue
  0.2,0.2,0.9,.25,
  0.2,0.2,0.9,.25,
  0.2,0.2,0.9,.25,

  0.9, 0.2, 0.2, 0.5, # red/green/blue
  0.2, 0.9, 0.2, 0.5,
  0.2, 0.2, 0.9, 0.5,
  0.1, 0.1, 0.1, 0.5,

  0.9,0.9,0.2,0.0, # yellow
  0.9,0.9,0.2,0.66,
  0.9,0.9,0.2,1.0,
  0.9,0.9,0.2,0.33,
);
my $colors = OpenGL::Array->new_list(GL_FLOAT,@colors);

my @rainbow =
(
  0.9, 0.2, 0.2, 0.5,
  0.2, 0.9, 0.2, 0.5,
  0.2, 0.2, 0.9, 0.5,
  0.1, 0.1, 0.1, 0.5,
);
my $rainbow = OpenGL::Array->new_list(GL_FLOAT,@rainbow);
my $rainbow_offset = 64;
my @rainbow_inc;

my @texcoords =
(
  0.800, 0.800,
  0.200, 0.800,
  0.200, 0.200,
  0.800, 0.200,

  0.005, 1.995,
  0.005, 0.005,
  1.995, 0.005,
  1.995, 1.995,

  0.995, 0.005,
  2.995, 2.995,
  0.005, 0.995,
  -1.995, -1.995,

  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,
  0.005, 0.005,

  -0.5, -0.5,
  1.5, -0.5,
  1.5, 1.5,
  -0.5, 1.5,

  0.005, 0.005,
  0.995, 0.005,
  0.995, 0.995,
  0.005, 0.995,
);
my $texcoords = OpenGL::Array->new_list(GL_FLOAT,@texcoords);

my @xform =
(
  1.0, 0.0, 0.0, 0.0,
  0.0, 1.0, 0.0, 0.0,
  0.0, 0.0, 1.0, 0.0,
  0.0, 0.0, 0.0, 1.0,
);
my $xform = OpenGL::Array->new_list(GL_FLOAT,@xform);

my @fpsbox_coords = (
    0.0, -2.0, 0.0,
    0.0, 12.0, 0.0,
  140.0, 12.0, 0.0,
  140.0, -2.0, 0.0,
);
my $fpsbox_coords = OpenGL::Array->new_list(GL_FLOAT,@fpsbox_coords);
my @fpsbox_norms = (
  (0.0,0.0,1.0) x 2,
);
my $fpsbox_norms = OpenGL::Array->new_list(GL_FLOAT,@fpsbox_norms);
my @fpsbox_colours = (
  (0.2,0.2,0.2,0.75) x 2,
);
my $fpsbox_colours = OpenGL::Array->new_list(GL_FLOAT,@fpsbox_colours);
my @fpsbox_indices = (
  0,1,2,     2,3,0,
);
my $fpsbox_indices = OpenGL::Array->new_list(GL_UNSIGNED_INT,@fpsbox_indices);

# ------
# Frames per second (FPS) statistic variables and routine.

use constant CLOCKS_PER_SEC => $hasHires ? 1000 : 1;
use constant FRAME_RATE_SAMPLES => 50;

my $FrameCount = 0;
my $FrameRate = 0;
my $last=0;

sub ourDoFPS
{
  if (++$FrameCount >= FRAME_RATE_SAMPLES)
  {
     my $now = $hasHires ? gettimeofday() : time(); # clock();
     my $delta= ($now - $last);
     $last = $now;

     $FrameRate = FRAME_RATE_SAMPLES / ($delta || 1);
     $FrameCount = 0;
  }
}

# ------
# String rendering routine; leverages on GLUT routine.

sub ourPrintString
{
  my ($font, $str) = @_;
  my @c = split '', $str;

  for(@c)
  {
    glutBitmapCharacter($font, ord $_);
  }
}


# ------
# Does everything needed before losing control to the main
# OpenGL event loop.

sub ourInitVertexBuffers
{
  # Set initial colors for rainbow face
  @rainbow = map [map rand(1.0), 0..3], 0..3;
  @rainbow = map @$_, @rainbow;
  @rainbow_inc = map [map 0.01 - rand(0.02), 0..3], 0..3;
  @rainbow_inc = map @$_, @rainbow_inc;

  # Initialize VBOs if supported
  if ($hasVBO)
  {
    printf("Using VBOs\n");

    ($VertexObjID,$NormalObjID,$ColorObjID,$TexCoordObjID,$IndexObjID,$FpsVertObjID,$FpsNormObjID,$FpsColourObjID,$FpsIndObjID) =
      glGenBuffersARB_p(9);

    $verts->bind($VertexObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $verts, GL_STATIC_DRAW_ARB);

    if (DO_TESTS)
    {
      print "\nTests:\n";

      my $size = glGetBufferParameterivARB_p(GL_ARRAY_BUFFER_ARB,
        GL_BUFFER_SIZE_ARB);
      print "  Vertex Buffer Size (bytes): $size\n";
      my $count = $verts->elements();
      print "  Vertex Buffer Size (elements): $count\n";

      my $test = glGetBufferSubDataARB_o(GL_ARRAY_BUFFER_ARB,12,3,GL_FLOAT);
      my @test = $test->retrieve(0,3);
      my $ords = join('/',@test);
      print "  glGetBufferSubDataARB_o: $ords\n";
    }

    $norms->bind($NormalObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $norms, GL_STATIC_DRAW_ARB);

    $colors->bind($ColorObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $colors, GL_DYNAMIC_DRAW_ARB);
    $rainbow->assign(0,@rainbow);
    glBufferSubDataARB_o(GL_ARRAY_BUFFER_ARB, $rainbow_offset, $rainbow);

    $texcoords->bind($TexCoordObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $texcoords, GL_STATIC_DRAW_ARB);

    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $IndexObjID);
    glBufferDataARB_o(GL_ELEMENT_ARRAY_BUFFER_ARB, $indices, GL_STATIC_DRAW_ARB);

    $fpsbox_coords->bind($FpsVertObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $fpsbox_coords, GL_STATIC_DRAW_ARB);
    $fpsbox_norms->bind($FpsNormObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $fpsbox_norms, GL_STATIC_DRAW_ARB);
    $fpsbox_colours->bind($FpsColourObjID);
    glBufferDataARB_o(GL_ARRAY_BUFFER_ARB, $fpsbox_colours, GL_STATIC_DRAW_ARB);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $FpsIndObjID);
    glBufferDataARB_o(GL_ELEMENT_ARRAY_BUFFER_ARB, $fpsbox_indices, GL_STATIC_DRAW_ARB);
  } else {
    print "Using classic Vertex Buffers\n";
  }
  print "-- done\n";
}

sub ourInit
{
  my ($Width, $Height) = @_;

  printf("\nUsing POGL v$OpenGL::VERSION\n");

  # Build texture.
  ourBuildTextures();
  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);

  # Initialize shaders.
  ourInitShaders();

  # Initialize vertex buffers
  ourInitVertexBuffers();

  # Initialize rendering parameters
  glEnable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);
  glBlendFunc(GL_SRC_ALPHA,GL_ONE);
  #glEnable(GL_BLEND);

  # Color to clear color buffer to.
  glClearColor(0.1, 0.1, 0.1, 0.0);

  # Depth to clear depth buffer to; type of test.
  glClearDepth(1.0);
  glDepthFunc(GL_LESS);

  # Enables Smooth Color Shading; try GL_FLAT for (lack of) fun.
  glShadeModel(GL_SMOOTH);

  # Load up the correct perspective matrix; using a callback directly.
  cbResizeScene($Width, $Height);

  # Set up a light, turn it on.
  glLightfv_p(GL_LIGHT1, GL_POSITION, @Light_Position);
  glLightfv_p(GL_LIGHT1, GL_AMBIENT,  @Light_Ambient);
  glLightfv_p(GL_LIGHT1, GL_DIFFUSE,  @Light_Diffuse);
  glEnable(GL_LIGHT1);

  # A handy trick -- have surface material mirror the color.
  glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
  glEnable(GL_COLOR_MATERIAL);
}


# ------
# Function to build a simple full-color texture with alpha channel,
# and then create mipmaps.
# Also sets up FBO texture and Vertex/Fragment programs.

sub ourBuildTextures
{
  my $gluerr;
  my $tex;

  # Build Image Texture
  ($TextureID_image,$TextureID_FBO) = glGenTextures_p(2);

  # Use OpenGL::Image to load texture
  if ($hasImage && -e $Tex_File)
  {
    my $img = OpenGL::Image->new(source=>$Tex_File);
    die $@ if $@;
    my($eng,$ver) = $img->Get('engine','version');
    print "Using OpenGL::Image - $eng v$ver\n";

    ($Tex_Width,$Tex_Height) = $img->Get('width','height');
    my $alpha = $img->Get('alpha') ? 'has' : 'no';
    print "Loading texture: $Tex_File, $Tex_Width x $Tex_Height, $alpha alpha\n";

    ($Tex_Type,$Tex_Format,$Tex_Size) =
      $img->Get('gl_internalformat','gl_format','gl_type');

    # Use OGA for testing
    $Tex_Image = $img;
    $Tex_Pixels = $img->GetArray();
    print "Using ImageMagick's gaussian blur on inset\n" if ($hasIM_635);
  }
  # Build texture from scratch if OpenGL::Image not available
  else
  {
    my $hole_size = int(($Tex_Width / 2.2) ** 2);
    my $hole_border = int($hole_size/30);
    my $w_2 = $Tex_Width/2;
    my $w_4 = $Tex_Width/4;
    my $w_16 = $Tex_Width/16;
    my $w_32 = $Tex_Width/32;
    # Iterate across the texture array.
    for(my $y=0; $y<$Tex_Height; $y++)
    {
      for(my $x=0; $x<$Tex_Width; $x++)
      {
        # A simple repeating squares pattern.
        # Dark blue on white.
        if ( ( ($x+$w_32)%$w_4 < $w_16 ) && ( ($y+$w_32)%$w_4 < $w_16))
        {
          $tex .= pack "C3", 0,0,120;       # Dark blue
        }
        else
        {
          $tex .= pack "C3", 240, 240, 240; # White
        }

        # Make a round dot in the texture's alpha-channel.
        # Calculate distance to center (squared).
        my $t = ($x-$w_2)*($x-$w_2) + ($y-$w_2)*($y-$w_2);

        if ( $t < $hole_size)
        {
          $tex .= pack "C", 255;  # The dot itself is opaque.
        }
        elsif ($t < $hole_size + $hole_border)
        {
          $tex .= pack "C", 128;  # Give our dot an anti-aliased edge.
        }
        else
        {
          $tex .= pack "C", 0;    # Outside of the dot, it's transparent.
        }
      }
    }

    $Tex_Pixels = OpenGL::Array->new_scalar(GL_UNSIGNED_BYTE,$tex,length($tex));

    $Tex_Type = GL_RGBA8;
    $Tex_Format = GL_RGBA;
    $Tex_Size =  GL_UNSIGNED_BYTE;
  }
  glBindTexture(GL_TEXTURE_2D, $TextureID_image);

  if ($hasFBO) {
    # Use MipMap
    print "Using Mipmap\n";
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
      GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST_MIPMAP_LINEAR);
  } else {
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  }
  glTexImage2D_c(GL_TEXTURE_2D, 0, $Tex_Type,
    $Tex_Width, $Tex_Height,
    0, $Tex_Format, $Tex_Size, $Tex_Pixels->ptr);
  glGenerateMipmapEXT(GL_TEXTURE_2D) if $hasFBO;

  # Benchmarks for Image Loading
  if (DO_TESTS && $hasIM)
  {
    my $loops = 1000;

    my $im = Image::Magick->new();
    $im->Read($Tex_File);
    $im->Set(magick=>'RGBA',depth=>8);
    $im->Negate(channel=>'alpha');


    # Bench ImageToBlob
    my $start = gettimeofday();
    for (my $i=0;$i<$loops;$i++)
    {
      my($blob) = $im->ImageToBlob();

      glTexImage2D_s(GL_TEXTURE_2D, 0, GL_RGBA8, $Tex_Width, $Tex_Height,
        0, GL_RGBA, GL_UNSIGNED_BYTE, $blob);
    }
    my $now = gettimeofday();
    my $fps = $loops / ($now - $start);
    print "ImageToBlob + glTexImage2D_s: $fps\n";


    # Bench GetPixels
    $start = gettimeofday();
    for (my $i=0;$i<$loops;$i++)
    {
      my @pixels = $im->GetPixels(map=>'BGRA',
        width=>$Tex_Width, height=>$Tex_Height, normalize=>'false');

      glTexImage2D_p(GL_TEXTURE_2D, 0, $Tex_Type, $Tex_Width, $Tex_Height,
        0, $Tex_Format, $Tex_Size, @pixels);
    }
    $now = gettimeofday();
    $fps = $loops / ($now - $start);
    print "GetPixels + glTexImage2D_p: $fps\n";


    # Bench OpenGL::Image
    if ($hasIM_635)
    {
      my $start = gettimeofday();
      for (my $i=0;$i<$loops;$i++)
      {
        glTexImage2D_c(GL_TEXTURE_2D, 0, $Tex_Type, $Tex_Width, $Tex_Height,
          0, $Tex_Format, $Tex_Size, $Tex_Pixels->ptr());
      }
      my $now = gettimeofday();
      my $fps = $loops / ($now - $start);
      print "OpenGL::Image + glTexImage2D_c: $fps\n";
    }
  }

  # Build FBO texture
  if ($hasFBO)
  {
    printf("Using FBOs\n");

    ($FrameBufferID) = glGenFramebuffersEXT_p(1);
    ($RenderBufferID) = glGenRenderbuffersEXT_p(1);

    # Initiate texture
    glBindTexture(GL_TEXTURE_2D, $TextureID_FBO);
    glTexImage2D_c(GL_TEXTURE_2D, 0, $Tex_Type, $Tex_Width, $Tex_Height,
      0, $Tex_Format, $Tex_Size, 0);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glGenerateMipmapEXT(GL_TEXTURE_2D);

    # Bind texture/frame/render buffers
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, $FrameBufferID);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
      GL_TEXTURE_2D, $TextureID_FBO, 0);
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, $RenderBufferID);
    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24_ARB,
      $Tex_Width, $Tex_Height);
    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
      GL_RENDERBUFFER_EXT, $RenderBufferID);

    # Test status
    my $stat = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
    die "FBO Status error: " . glpErrorString(glGetError()) if !$stat;
    die sprintf "FBO Status: %04X", $stat if $stat != GL_FRAMEBUFFER_COMPLETE_EXT;
  }

  # Select active texture
  ourSelectTexture();

  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
}

sub ourSelectTexture
{
    glBindTexture(GL_TEXTURE_2D, $FBO_On ? $TextureID_FBO : $TextureID_image);
}

my %ext2shaders = (
  arb => [
<<'EOF',
!!ARBfp1.0
PARAM surfacecolor = program.local[5];
TEMP color;
MUL color, fragment.texcoord[0].y, 2.0;
ADD color, 1.0, -color;
ABS color, color;
ADD color, 1.01, -color;  # Some cards have a rounding error
MOV color.a, 1.0;
MUL color, color, surfacecolor;
MOV result.color, color;
END
EOF
<<'EOF',
!!ARBvp1.0
PARAM center = program.local[0];
PARAM xform[4] = {program.local[1..4]};
TEMP vertexClip;

# ModelView projection
DP4 vertexClip.x, state.matrix.mvp.row[0], vertex.position;
DP4 vertexClip.y, state.matrix.mvp.row[1], vertex.position;
DP4 vertexClip.z, state.matrix.mvp.row[2], vertex.position;
DP4 vertexClip.w, state.matrix.mvp.row[3], vertex.position;

# Additional transform, via matrix variable
DP4 vertexClip.x, vertexClip, xform[0];
DP4 vertexClip.y, vertexClip, xform[1];
DP4 vertexClip.z, vertexClip, xform[2];
DP4 vertexClip.w, vertexClip, xform[3];

#SUB result.position, vertexClip, center;
MOV result.position, vertexClip;

# Pass through color
MOV result.color, vertex.color;

# Pass through texcoords
SUB result.texcoord[0], vertex.texcoord, center;
END
EOF
  ],
  glsl => [
<<'EOF',
uniform vec4 surfacecolor;

void main (void) {
   float v = 2.0 * gl_TexCoord[0].y;
   v = 1.01 - abs(1.0 - v);  // Some cards have a rounding error
   gl_FragColor = vec4(v,v,v, 1.0) * surfacecolor;
}
EOF
<<'EOF',
uniform vec4 center;
uniform mat4 xform;

void main(void) {
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
  gl_Position *= xform;
  // Calc texcoord values
  vec4 pos = gl_Vertex;
  float d = sqrt(pos.x * pos.x + pos.y * pos.y);
  float a = atan(pos.x/pos.y) / 3.1415;
  if (a < 0.0) a += 1.0;
  a *= 2.0;
  a -= float(int(a));
  pos -= center;
  float h = pos.z;
  h = abs(2.0 * atan(h/d) / 3.1415);
  gl_TexCoord[0].x = a;
  gl_TexCoord[0].y = h;
}
EOF
  ],
);
sub ourInitShaders
{
  # Setup Vertex/Fragment Programs to render FBO texture
  if ($hasShader) {
    my $version = $OpenGL::Shader::VERSION;
    printf("Using OpenGL::Shader v$version\n");
    my $types = OpenGL::Shader->GetTypes();
    my @types = keys(%$types);
    printf("This installation supports the following shader types: %s\n", join(',', @types));
    # Use OpenGL::Shader
    $Shader = OpenGL::Shader->new();
    if (!$Shader) {
      printf("Unable to instantiate OpenGL::Shader\n");
      return;
    }
    my $type = $Shader->GetType();
    my $ext = lc($type);
    my $shaders = $ext2shaders{$ext};
    my $stat = !$shaders ? "Shader: unknown extension '$ext'" : $Shader->Load(@$shaders);
    if (!$stat) {
      my $ver = $Shader->GetVersion();
      print "Using OpenGL::Shader('$type') v$ver\n";
      return;
    } else {
      print "$stat\n";
    }
  }
}


# ------
# Routine which actually does the drawing

sub cbRenderScene
{
  # Quit if inactive
  my $time = $hasHires ? gettimeofday() : time();
  my $time_to_exit = $idleSecsMax - ($time-$idleTime);
  if ($time_to_exit <= 0 )
  {
    print "Idle timeout; completing test\n";
    ourCleanup();
    return quit("render callback");
  }

  my $buf; # For our strings.

  # Animated Texture Rendering
  if ($FBO_On && ($FBO_On == 2 || !$FBO_rendered))
  {
    $FBO_rendered = 1;
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, $FrameBufferID);
    glViewport(0, 0, $Tex_Width, $Tex_Height);
    glPushMatrix();
    glTranslatef(0, 0, -1.5);
    glRotatef($Teapot_Rot--, 0.0, 1.0, 0.0);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glPushAttrib(GL_ENABLE_BIT);
    glEnable(GL_DEPTH_TEST);

    # Run shader programs for texture.
    # If installed, use OpenGL::Shader
    if ($Shader) {
      $Shader->Enable();
      $Shader->SetVector('center',0.0,0.0,2.0,0.0);
      $Shader->SetMatrix('xform',$xform);
      $Shader->SetVector('surfacecolor',1.0,0.5,0.0,1.0);
    }

    glColor3f(1.0, 1.0, 1.0);
    glutWireTeapot(0.25);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glBindTexture(GL_TEXTURE_2D, $TextureID_FBO);
    glGenerateMipmapEXT(GL_TEXTURE_2D);

    if ($Shader) {
      $Shader->Disable();
    }

    glPopAttrib();
    glPopMatrix();
  }
  ourSelectTexture();

  # Enables, disables or otherwise adjusts as
  # appropriate for our current settings.

  if ($Texture_On) {
    glEnable(GL_TEXTURE_2D);
  } else {
    glDisable(GL_TEXTURE_2D);
  }
  if ($Light_On) {
    glEnable(GL_LIGHTING);
  } else {
    glDisable(GL_LIGHTING);
  }
  if ($Alpha_Add) {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
  } else {
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
  }
  # If we're blending, we don't want z-buffering.
  if ($Blend_On) {
    glEnable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
  }

  # Need to manipulate the ModelView matrix to move our model around.
  glMatrixMode(GL_MODELVIEW);

  # Reset to 0,0,0; no rotation, no scaling.
  glLoadIdentity();

  # Move the object back from the screen.
  glTranslatef(0.0,0.0,$Z_Off);

  # Rotate the calculated amount.
  glRotatef($X_Rot,1.0,0.0,0.0);
  glRotatef($Y_Rot,0.0,1.0,0.0);

  # Clear the color and depth buffers.
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);


  # Update Rainbow Cube Face
  for (my $i=0; $i<scalar(@rainbow); $i++) {
    $rainbow[$i] += $rainbow_inc[$i];
    if ($rainbow[$i] < 0) {
      $rainbow[$i] = 0.0;
    } elsif ($rainbow[$i] > 1) {
      $rainbow[$i] = 1.0;
    } else {
      next;
    }
    $rainbow_inc[$i] = -$rainbow_inc[$i];
  }

  if ($hasVBO) {
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, $ColorObjID);
    glMapBufferARB_c(GL_ARRAY_BUFFER_ARB, GL_WRITE_ONLY_ARB);
    $colors->assign($rainbow_offset,@rainbow);
    glUnmapBufferARB(GL_ARRAY_BUFFER_ARB);
  } else {
    $colors->assign($rainbow_offset,@rainbow);
  }
  glColorPointer_o(4, $colors);

  # Render cube
  glViewport(0, 0, $Window_Width, $Window_Height);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

  glVertexPointer_o(3, $verts);
  glNormalPointer_o($norms);
  glTexCoordPointer_o(2, $texcoords);
  if ($hasVBO) {
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $IndexObjID);
  }
  glDrawElements_c(GL_TRIANGLES, scalar(@indices), GL_UNSIGNED_INT, $hasVBO ? 0 : $indices->ptr);

  if ($hasVBO) {
    glBindBufferARB(GL_ARRAY_BUFFER, 0);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
  }
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);

  # Move back to the origin (for the text, below).
  glLoadIdentity();

  # We need to change the projection matrix for the text rendering.
  glMatrixMode(GL_PROJECTION);

  # But we like our current view too; so we save it here.
  glPushMatrix();

  # Now we set up a new projection for the text.
  glLoadIdentity();
  glOrtho(0,$Window_Width,0,$Window_Height,-1.0,1.0);

  # Lit or textured text looks awful.
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);

  # We don't want depth-testing either.
  glDisable(GL_DEPTH_TEST);

  # But, for fun, let's make the text partially transparent too.
  glColor4f(0.6,1.0,0.6,.75);

  $buf = sprintf "TIME TO EXIT: %.1fs", $time_to_exit;
  my $bufwidth = 6 * length $buf;
  glRasterPos2i($Window_Width-4-$bufwidth,2); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  # Render our various display mode settings.
  $buf = sprintf "Mode: %s", $TexModesStr[$Curr_TexMode];
  glRasterPos2i(2,2); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Alpha: %d", $Alpha_Add;
  glRasterPos2i(2,14); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Blend: %d", $Blend_On;
  glRasterPos2i(2,26); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Light: %d", $Light_On;
  glRasterPos2i(2,38); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Tex: %d", $Texture_On;
  glRasterPos2i(2,50); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "FBO: %d", $FBO_On;
  glRasterPos2i(2,62); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  $buf = sprintf "Inset: %d", $Inset_On;
  glRasterPos2i(2,74); ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  # Now we want to render the calculated FPS at the top.
  # To ease, simply translate up.  Note we're working in screen
  # pixels in this projection.
  glTranslatef(6.0,$Window_Height - 14,0.0);

  # Make sure we can read the FPS section by first placing a
  # dark, mostly opaque backdrop rectangle.
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glVertexPointer_o(3, $fpsbox_coords);
  glNormalPointer_o($fpsbox_norms);
  glColorPointer_o(4, $fpsbox_colours);
  if ($hasVBO) {
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, $FpsIndObjID);
  }
  glDrawElements_c(GL_TRIANGLES, scalar(@fpsbox_indices), GL_UNSIGNED_INT, $hasVBO ? 0 : $fpsbox_indices->ptr);
  if ($hasVBO) {
    glBindBufferARB(GL_ARRAY_BUFFER, 0);
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
  }
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);

  glColor4f(0.9,0.2,0.2,.75);
  $buf = sprintf "FPS: %f F: %2d", $FrameRate, $FrameCount;
  glRasterPos2i(6,0);
  ourPrintString(GLUT_BITMAP_HELVETICA_12,$buf);

  # Done with this special projection matrix.  Throw it away.
  glPopMatrix();

  # Do Inset View
  Capture(Inset=>1) if ($Inset_On);

  # All done drawing.  Let's show it.
  glutSwapBuffers();

  # Now let's do the motion calculations.
  $X_Rot+=$X_Speed;
  $Y_Rot+=$Y_Speed;

  # And collect our statistics.
  ourDoFPS();
}

# Capture window
sub Capture
{
  my(%params) = @_;

  my($w) = glutGet( GLUT_WINDOW_WIDTH );
  my($h) = glutGet( GLUT_WINDOW_HEIGHT );
	
  glPushAttrib( GL_ENABLE_BIT | GL_VIEWPORT_BIT |
    GL_TRANSFORM_BIT | GL_COLOR_BUFFER_BIT);
  glDisable( GL_LIGHTING );
  glDisable( GL_FOG );
  glDisable( GL_TEXTURE_2D );
  glDisable( GL_DEPTH_TEST );
  glDisable( GL_CULL_FACE );
  glDisable( GL_STENCIL_TEST );

  glViewport( 0, 0, $w, $h );
  glMatrixMode( GL_PROJECTION );
  glPushMatrix();
  glLoadIdentity();
  eval { glOrtho( 0, $w, 0, $h, -1, 1 ); 1 } or $er++ or warn "Catched: $@";
  glMatrixMode( GL_MODELVIEW );
  glPushMatrix();
  glLoadIdentity();

  glPixelZoom( 1, 1 );

  # Save
  if ($params{Save})
  {
    Save($w,$h,$params{Save});
  }
  # Inset
  elsif ($params{Inset})
  {
    Inset($w,$h);
  }

  glMatrixMode( GL_PROJECTION );
  glPopMatrix();
  glMatrixMode( GL_MODELVIEW );
  glPopMatrix();
  glPopAttrib();
}

# Display inset
sub Inset
{
  my($w,$h) = @_;

  my $Capture_X = int(($w - $Inset_Width) / 2);
  my $Capture_Y = int(($h - $Inset_Height) / 2);
  my $Inset_X = $w - ($Inset_Width + 2);
  my $Inset_Y = $h - ($Inset_Height + 2);

  # Using OpenGL::Image and ImageMagick to read/modify/draw pixels
  if ($hasIM_635)
  {
    my $frame = OpenGL::Image->new(engine=>'Magick',
      width=>$Inset_Width, height=>$Inset_Height);
    die $@ if $@;
    my($fmt,$size) = $frame->Get('gl_format','gl_type');

    glReadPixels_c( $Capture_X, $Capture_Y, $Inset_Width, $Inset_Height,
      $fmt, $size, $frame->Ptr() );

    # Do this before making native calls
    $frame->Sync();

    # For grins, use ImageMagick to modify the inset
    $frame->Native->Blur(radius=>2,sigma=>2);

    # Do this when done making native calls
    $frame->SyncOGA();

    glRasterPos2f( $Inset_X, $Inset_Y );
    glDrawPixels_c( $Inset_Width, $Inset_Height, $fmt, $size, $frame->Ptr() );
  }
  # Fastest approach
  else
  {
    my $len = $Inset_Width * $Inset_Height * 4;
    my $oga = OpenGL::Array->new($len,GL_UNSIGNED_BYTE);

    glReadPixels_c( $Capture_X, $Capture_Y, $Inset_Width, $Inset_Height,
      GL_RGBA, GL_UNSIGNED_BYTE, $oga->ptr() );
    glRasterPos2f( $Inset_X, $Inset_Y );
    glDrawPixels_c( $Inset_Width, $Inset_Height, GL_RGBA, GL_UNSIGNED_BYTE, $oga->ptr() );
  }
}

# Capture/save window
sub Save
{
  my($w,$h,$file) = @_;

  if ($hasImage)
  {
    my $frame = OpenGL::Image->new(width=>$w, height=>$h);
    my($fmt,$size) = $frame->Get('gl_format','gl_type');

    glReadPixels_c( 0, 0, $w, $h, $fmt, $size, $frame->Ptr() );
    $frame->Save($file);
  }
  else
  {
    print "Need OpenGL::Image and ImageMagick 6.3.5 or newer for file capture!\n";
  }
}

# Cleanup routine
sub ourCleanup {
  print "Starting cleanup ...\n";
  # Disable app
  glutHideWindow();
  glutKeyboardUpFunc();
  glutKeyboardFunc();
  glutSpecialUpFunc();
  glutSpecialFunc();
  glutIdleFunc();
  glutReshapeFunc();
  glutCloseFunc() if OpenGL::_have_freeglut();

  ReleaseResources();

  # Now you can destroy window
  if (defined($gameMode)) {
    print "Leaving game mode.\n";
    glutLeaveGameMode();
  } else {
    print "Destroying window.\n";
    glutDestroyWindow($Window_ID);
  }
  undef($Window_ID);
  print "Cleanup completed.\n";
}

sub ReleaseResources {
  return if !defined $Window_ID;

  if ($hasFBO) {
    # Release resources
    glBindRenderbufferEXT( GL_RENDERBUFFER_EXT, 0 );
    glBindFramebufferEXT( GL_FRAMEBUFFER_EXT, 0 );
    glDeleteRenderbuffersEXT_p( $RenderBufferID ) if $RenderBufferID;
    glDeleteFramebuffersEXT_p( $FrameBufferID ) if $FrameBufferID;
  }

  if ($Shader) {
    undef($Shader);
  }

  if ($hasVBO) {
    glBindBufferARB(GL_ARRAY_BUFFER_ARB, 0);
    glDeleteBuffersARB_p($VertexObjID) if $VertexObjID;
    glDeleteBuffersARB_p($NormalObjID) if $NormalObjID;
    glDeleteBuffersARB_p($ColorObjID) if $ColorObjID;
    glDeleteBuffersARB_p($TexCoordObjID) if $TexCoordObjID;
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, 0);
    glDeleteBuffersARB_p($IndexObjID) if $IndexObjID;
  }

  glDeleteTextures_p($TextureID_image,$TextureID_FBO);
}

# ------
# Callback function called when a normal $key is pressed.

sub cbKeyPressed
{
  my $key = shift;
  my $c = uc chr $key;
  if ($key == 27 or $c eq 'Q')
  {
    ourCleanup();
    return quit("key press callback");
  }
  elsif ($c eq 'B')
  {
    $Blend_On = !$Blend_On;
  }
  elsif ($c eq 'K')
  {
    # ignore keypress if not FreeGLUT
    glutLeaveMainLoop() if OpenGL::_have_freeglut();
  }
  elsif ($c eq 'L')
  {
    $Light_On = !$Light_On;
  }
  elsif ($c eq 'M')
  {
    if ( ++ $Curr_TexMode > 3 )
    {
      $Curr_TexMode=0;
    }
    glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,$TexModes[$Curr_TexMode]);
  }
  elsif ($c eq 'T')
  {
    $Texture_On = !$Texture_On;
  }
  elsif ($c eq 'A')
  {
    $Alpha_Add = !$Alpha_Add;
  }
  elsif ($c eq 'F' && $hasFBO)
  {
    $FBO_On = ($FBO_On+1) % 3;
    ourSelectTexture();
  }
  elsif ($c eq 'I')
  {
    $Inset_On = !$Inset_On;
  }
  elsif ($c eq 'S' or $key == 32)
  {
    $X_Speed=$Y_Speed=0;
  }
  elsif ($c eq 'R')
  {
    $X_Speed = -$X_Speed;
    $Y_Speed = -$Y_Speed;
  }
  elsif ($c eq 'G')
  {
    $Fullscreen_On = !$Fullscreen_On;
    if ($Fullscreen_On)
    {
      $Window_State = glpFullScreen();
      $Window_Width = $Window_State->{w};
      $Window_Height = $Window_State->{h};
    }
    else
    {
      glpRestoreScreen($Window_State);
    }
  }
  elsif ($c eq 'C' && $hasImage)
  {
    Capture(Save=>'capture.tga');
  }
  elsif ($c eq 'W')
  {
    $Z_Off += 0.5;
  }
  elsif ($c eq 'X')
  {
    $Z_Off -= 0.5;
  }
  else
  {
    printf "KP: No action for %d.\n", $key;
  }

  $idleTime = $hasHires ? gettimeofday() : time();
}

# ------
# Callback Function called when a special $key is pressed.

sub cbSpecialKeyPressed
{
  my $key = shift;

  if ($key == GLUT_KEY_PAGE_UP)
  {
    $Z_Off -= 0.05;
  }
  elsif ($key == GLUT_KEY_PAGE_DOWN)
  {
    $Z_Off += 0.05;
  }
  elsif ($key == GLUT_KEY_UP)
  {
    $X_Speed -= 0.01;
  }
  elsif ($key == GLUT_KEY_DOWN)
  {
    $X_Speed += 0.01;
  }
  elsif ($key == GLUT_KEY_LEFT)
  {
    $Y_Speed -= 0.01;
  }
  elsif ($key == GLUT_KEY_RIGHT)
  {
    $Y_Speed += 0.01;
  }
  else
  {
    printf "SKP: No action for %d.\n", $key;
  }

  $idleTime = $hasHires ? gettimeofday() : time();
}

# ------
# Callback function called for key-up events.

sub cbKeyUp
{
  my($key) = @_;
  my $mod = GetKeyModifier();
  print "Key up: $key w/ $mod\n" if ($mod);
}

# ------
# Callback function called for special key-up events.

sub cbSpecialKeyUp
{
  my($key) = @_;
  my $mod = GetKeyModifier();
  print "Special Key up: $key w/ $mod\n" if ($mod);
}

# ------
# Callback function called for handling mouse clicks.

sub cbMouseClick
{
  my($button,$state,$x,$y) = @_;

  if ($button == GLUT_LEFT_BUTTON)
  {
    print "Left";
  }
  elsif ($button == GLUT_MIDDLE_BUTTON)
  {
    print "Middle";
  }
  elsif ($button == GLUT_RIGHT_BUTTON)
  {
    print "Right";
  }
  else
  {
    print "Unknown";
  }
  print " mouse button, ";

  if ($state == GLUT_DOWN)
  {
    print "DOWN";
  }
  elsif ($state == GLUT_UP)
  {
    print "UP";
  }
  else
  {
    print "State UNKNOWN";
  }

  my $mod = GetKeyModifier();
  print " w/ $mod" if ($mod);
  print ": $x, $y\n";

  # Example of using GLU to determine 3D click points
  if ($state == GLUT_UP)
  {
    my ($model, $projection, $viewport) = dumpMatrices();
    print "\n";
  }

  $idleTime = $hasHires ? gettimeofday() : time();
}

sub dumpMatrices
{
  print "\n";
  glGetDoublev_c(GL_MODELVIEW_MATRIX,$mm->ptr());
  my @model = $mm->retrieve(0,16);
  glGetDoublev_c(GL_PROJECTION_MATRIX,$pm->ptr());
  my @projection = $pm->retrieve(0,16);
  glGetDoublev_c(GL_PROJECTION_MATRIX,$tm->ptr());
  my @texture = $tm->retrieve(0,16);
  glGetDoublev_c(GL_PROJECTION_MATRIX,$cm->ptr());
  my @colours = $cm->retrieve(0,16);
  for (['Model',\@model], ['Projection',\@projection], ['Texture',\@texture], ['Colour',\@colours]) {
    printf "%-19s$_->[1][0], $_->[1][1], $_->[1][2], $_->[1][3]\n", "$_->[0] Matrix:";
    print "                   $_->[1][4], $_->[1][5], $_->[1][6], $_->[1][7]\n";
    print "                   $_->[1][8], $_->[1][9], $_->[1][10], $_->[1][11]\n";
    print "                   $_->[1][12], $_->[1][13], $_->[1][14], $_->[1][15]\n";
  }
  glGetIntegerv_c(GL_VIEWPORT,$vp->ptr());
  my @viewport = $vp->retrieve(0,4);
  print "Viewport: $viewport[0], $viewport[1], $viewport[2], $viewport[3]\n";
  print "\n";
  (\@model, \@projection, \@viewport);
}

sub GetKeyModifier
{
  return $key_mods->{glutGetModifiers()};
}

# ------
# Callback routine executed whenever our window is resized.  Lets us
# request the newly appropriate perspective projection matrix for
# our needs.  Try removing the glFrustum() call to see what happens.

use constant PI => 3.1415926535897932384626433832795;
use constant FOVY => 45.0;
use constant ANGLE => FOVY / 360 * PI;
use constant TAN => sin(ANGLE)/cos(ANGLE);
use constant { zNEAR => 0.1, zFAR => 100.0 };
use constant fH => TAN * zNEAR;
sub cbResizeScene {
  my($Width, $Height) = @_;
  # Let's not core dump, no matter what.
  $Height = 1 if ($Height == 0);
  glViewport(0, 0, $Width, $Height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  my $fW = fH * $Width/$Height;
  glFrustum(-$fW, $fW, -fH(), fH, zNEAR, zFAR);
  glMatrixMode(GL_MODELVIEW);
  $Window_Width  = $Width;
  $Window_Height = $Height;
  $idleTime = $hasHires ? gettimeofday() : time();
}

sub cbWindowStat
{
  my($stat) = @_;
  print "Window status: $stat\n";
}

sub cbClose
{
  my($wid) = @_;
  print "User has closed window: \#$wid\n";
  ReleaseResources();
}

# this is a little complicated
# Using freeglut, doing a straight exit crashes on some systems, mostly observed
# on windows, likely due to thread issues.
# However on non-freeglut systems the proper way of using glutLeaveMainLoop is
# not available.
# So the proper one needs to be chosen.
# However while exit exits the thread, glutLeaveMainLoop only sets a flag for
# the event loop, thus we must take care to return when using it. Additionally
# any use of quit() ALSO needs to return.
#
#   return quit();
#
sub quit {
  my ($context) = @_;
  $context ||= "<unknown context>";
  print "Exiting in $context using ";
  if (OpenGL::_have_freeglut()) {
    print "glutLeaveMainLoop (freeglut)\n";
    glutLeaveMainLoop();
    return;
  }
  print "perl exit(0)\n";
  exit(0);
}

# ------
# The main() function.  Inits OpenGL.  Calls our own init function,
# then passes control onto OpenGL.

# Initialize GLUT/FreeGLUT
glutInit();

# To see OpenGL drawing, take out the GLUT_DOUBLE request.
glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA);

if ($^O ne 'MSWin32' and $OpenGL::Config->{DEFINE} !~ /-DHAVE_W32API/) { # skip these MODE checks on win32, they don't work

   if (not glutGet(GLUT_DISPLAY_MODE_POSSIBLE))
   {
      warn "glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH | GLUT_ALPHA) not possible";
      warn "...trying without GLUT_ALPHA";
      # try without GLUT_ALPHA
      glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
      if (not glutGet(GLUT_DISPLAY_MODE_POSSIBLE))
      {
         warn "glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH) not possible, exiting quietly";
         exit 0;
      }
   }

}

#glutInitDisplayString("rgb alpha>=0 double depth");

# Open Window
if (defined($gameMode) && glutGameModeString($gameMode))
{
  print "Running in Game Mode $gameMode\n";
  glutGameModeString($gameMode);
  $Window_ID = glutEnterGameMode();
  $Window_Width = glutGameModeGet( GLUT_GAME_MODE_WIDTH );
  $Window_Height = glutGameModeGet( GLUT_GAME_MODE_HEIGHT );
}
else
{
  glutInitWindowSize($Window_Width, $Window_Height);
  $Window_ID = glutCreateWindow( PROGRAM_TITLE );
}
glpSetAutoCheckErrors(1) if $^O ne 'MSWin32';

# Get OpenGL Info
print "\n";
print PROGRAM_TITLE;
print ' (using hires timer)' if ($hasHires);
print "\n\n";
my $version = glGetString(GL_VERSION);
my $vendor = glGetString(GL_VENDOR);
my $renderer = glGetString(GL_RENDERER);
print "Using POGL v$OpenGL::BUILD_VERSION\n";
print "OpenGL installation: $version\n$vendor\n$renderer\n\n";

print "Installed extensions (* implemented in the module):\n";
my $extensions = glGetString(GL_EXTENSIONS);
my @extensions = split(' ',$extensions);
foreach my $ext (sort @extensions)
{
  my $stat = glpCheckExtension($ext);
  printf("%s $ext\n",$stat?' ':'*');
  print("    $stat\n") if ($stat && $stat !~ m|^$ext |);
}

if (!OpenGL::glpCheckExtension('GL_ARB_vertex_buffer_object')) {
  # Perl 5.10 crashes on VBOs!
  $hasVBO = ($PERL_VERSION !~ m|^5\.10\.|);
}

if (!OpenGL::glpCheckExtension('GL_EXT_framebuffer_object')) {
  $hasFBO = 1;
  $FBO_On = 1;
  if (!OpenGL::glpCheckExtension('GL_ARB_fragment_program')) {
    $FBO_On++;
  }
}


# Register the callback function to do the drawing.
glutDisplayFunc(\&cbRenderScene);

# If there's nothing to do, draw.
glutIdleFunc(\&cbRenderScene);

# It's a good idea to know when our window's resized.
glutReshapeFunc(\&cbResizeScene);
#glutWindowStatusFunc(\&cbWindowStat);

# And let's get some keyboard input.
glutKeyboardFunc(\&cbKeyPressed);
glutSpecialFunc(\&cbSpecialKeyPressed);
glutKeyboardUpFunc(\&cbKeyUp);
glutSpecialUpFunc(\&cbSpecialKeyUp);

# Mouse handlers.
glutMouseFunc(\&cbMouseClick);
#glutMotionFunc(\&cbMouseDrag);
#glutPassiveMotionFunc(\&cbMouseTrack);

# Handle window close events.
glutCloseFunc(\&cbClose) if OpenGL::_have_freeglut();

# OK, OpenGL's ready to go.  Let's call our own init function.
ourInit($Window_Width, $Window_Height);


# Print out a bit of help dialog.
print qq
{
Hold down arrow keys to rotate, 'r' to reverse, 's' to stop.
Page up/down will move cube away from/towards camera.
Use first letter of shown display mode settings to alter.
Press 'g' to toggle fullscreen mode (not supported on all platforms).
Press 'c' to capture/save a RGBA targa file.
'q' or [Esc] to quit; OpenGL window must have focus for input.

};

# Pass off control to OpenGL.
# Above functions are called as appropriate.
if (OpenGL::_have_freeglut()) {
   print "Setting window close to trigger return from mainloop (freeglut).\n";
   glutSetOption(GLUT_ACTION_ON_WINDOW_CLOSE,GLUT_ACTION_GLUTMAINLOOP_RETURNS)
}

print "Entering glutMainLoop\n";
glutMainLoop();
print "Returned from glutMainLoop\n";

print "Exiting in main thread\n";

__END__
