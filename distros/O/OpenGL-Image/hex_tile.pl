#!/usr/bin/perl -w
use strict;
use Math::Trig;
use OpenGL qw/ :all /;
use OpenGL::Image;

die "Requires ImageMagick\n" if (!OpenGL::Image::HasEngine('Magick'));

eval 'use Time::HiRes qw( gettimeofday )';
my $hasHires = !$@;

$|++;


# Define constants
use constant DEBUG=>0;


# Get image file
my($path,@opts) = @ARGV;
die qq
{
USAGE: $0 [IMAGE_FILE | PATH] [OPTIONS]

IMAGE_FILE	Identifies a single source image for tiling
PATH		Recursed path for randomly selected source images

OPTIONS:
w=WIDTH     Width of display window     - If neither w nor h are present,
h=HEIGHT    Height of display window      fullscreen mode is assumed.
xf=XFREQ    Horizonal tiling frequency  - If neither xf nor yf are present,
yf=YFREQ    Vertical tiling frequency     a default is selected.
d=DURATION  Seconds between images      - Ignored for single source images.
fps=FPS     Max frames per second       - Requires Time::HiRes.
sort=SORT   random | alpha | none	- Defaults to random.

} if (!$path);


# Get options
my $opts = {};
foreach my $opt (@opts)
{
  my($key,$value) = split('=',$opt);
  next if (!$key);
  $opts->{$key} = defined($value) ? $value : 0;
}

# Default options
my $sort = $opts->{sort} || 'random';
my $dur = defined($opts->{d}) ? $opts->{d} : 60;
my $scl = $opts->{s} || 1.0;
my $sgn = 1.0;
my $display_source = 0;

# Get image path(s)
my @images = GetImages($path);
my $images = scalar(@images);
die "No images (jpg,png,gif,tga,bmp) found\n" if (!$images);
my $current = 0;

# Set default frame size
if (!$opts->{w} && !$opts->{h})
{
  $opts->{w} = 512;
  $opts->{h} = 512;
  $opts->{fs} = 1;
}
elsif (!$opts->{h})
{
  $opts->{h} = $opts->{w};
}
elsif (!$opts->{w})
{
  $opts->{w} = $opts->{h};
}
$opts->{fps} = 30 if (!defined($opts->{fps}));
my $fps = $opts->{fps};

# Set default tiling frequency
if (!$opts->{xf} && !$opts->{yf})
{
  ($opts->{xf},$opts->{yf}) = DefaultFreq($opts->{w},$opts->{h});
}
elsif (!$opts->{yf})
{
  $opts->{yf} = $opts->{xf} * 2;
}
elsif (!$opts->{xf})
{
  $opts->{xf} = int(.5 + $opts->{yf} / 2) || 1;
}
my $freqx = $opts->{xf};
my $freqy = $opts->{yf};

# Get app name
$0 =~ m|^([^\.]+)|;
my $name = $1 || 'capture';

# Window parameters
my $wnd_ID;
my $wnd_title = 'Grafman Hexagonal Tiler';
my $wnd_width = $opts->{w};
my $wnd_height = $opts->{h};
my($save_w,$save_h,$save_x,$save_y);

# State parameters
my $last_time = $hasHires ? gettimeofday() : 0;
my $last_image = 0;
my $frames = 0;
my $pause = 0;
my($image,$image_w,$image_h);
my($x0,$y0,$x1,$y1,$x2,$y2);
my($ix,$iy,$ix0,$iy0,$ix1,$iy1,$ix2,$iy2);
my($dx,$dy,$dx0,$dy0,$dx1,$dy1,$dx2,$dy2);

# Init GLUT
glutInit();
glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
glutInitWindowSize($wnd_width,$wnd_height);

# Open a window
$wnd_ID = glutCreateWindow($wnd_title);
ToggleFS(1) if ($opts->{fs});
print "Window size: $wnd_width x $wnd_height\n";

# Test for necessary OpenGL Extensions
# Must do this _after_ window context is established
my $stat = OpenGL::glpCheckExtension('GL_ARB_texture_rectangle');
my $hasTexRect = !$stat;
my $tex_mode = $hasTexRect ? GL_TEXTURE_RECTANGLE_ARB : GL_TEXTURE_2D;

# Alloc texture
my($tex_ID) = glGenTextures_p(1);
Terminate("Unable to alloc texture ID") if (!$tex_ID);
glBindTexture($tex_mode, $tex_ID);
glTexParameteri($tex_mode, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri($tex_mode, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
glTexParameteri($tex_mode, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri($tex_mode, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

# Register rendering callback
glutDisplayFunc(\&cbRenderScene);

# Register idle callback
glutIdleFunc(\&cbRenderScene);

# Register resize callback
glutReshapeFunc(\&cbResizeScene);

# Register keyboard callback
glutKeyboardFunc(\&cbKeyPressed);

# Init app environment
InitApp($wnd_width,$wnd_height);

# Print keyboard commands
print qq
{
p to toggle pause; r to rewind; n steps to next image;
+ for faster; - for slower; * to unthrottle framerate;
1-9 sets tiling frequency; s to save as JPEG;
q or <esc> to quit.

OpenGL window must have focus for input.

};

# Pass off control to GLUT
glutMainLoop();
exit(0);


########
# Subroutines
########

# Cleanup routine
sub Terminate
{
  # Disable app
  glutHideWindow();
  glutKeyboardFunc();
  glutSpecialFunc();
  glutIdleFunc();
  glutReshapeFunc();

  glDeleteTextures_p($tex_ID) if ($tex_ID);

  # Now we can destroy window
  glutDestroyWindow($wnd_ID);
}

# Recursively locate images in a path
sub GetImages
{
  my @paths = @_;
  my @images;

  foreach my $path (@paths)
  {
    if (-d $path)
    {
      next if (!opendir(DIR,$path));
      foreach my $file (readdir(DIR))
      {
        next if ($file =~ m|^\.|);
        push(@images,GetImages("$path/$file"));
      }
      closedir(DIR);
    }
    else
    {
      next if ($path !~ m/\.(jpg|png|gif|tga|bmp)$/);
      push(@images,$path);
    }
  }
  return ($sort eq 'alpha') ? sort(@images) : @images;
}

# Load image
sub LoadNextImage
{
  my($force) = @_;

  if (!$force && $image)
  {
    return 1 if (!$dur || $images==1);

    my $secs = time() - $last_image;

    if ($pause || $display_source)
    {
      $last_image += $dur - $secs;
      return 1;
    }

    return 1 if ($secs < $dur);
  }
  $last_image = time();

  my $path;
  if ($sort eq 'random')
  {
    $current = int(rand($images));
    $path = $images[$current];
  }
  else
  {
    $path = $images[$current++];
    $current %= $images;
  }
  #$path =~ m|[/\\](.*)|;
  #print "Attempting to load: '$1'\n";

  $image = new OpenGL::Image(engine=>'Magick',source=>$path);
  return 0 if (!$image);

  # Resample image if GL_ARB_texture_rectangle not supported
  if (!$hasTexRect)
  {
    my $size = $image->GetPowerOf2();
    $image->Native->Resize(width=>$size,height=>$size,filter=>'Hermite');
    $image->SyncOGA();
  }

  ($image_w,$image_h) = $image->Get('width','height');
  return 0 if (!$image_w || !$image_h);

  # Init texture coords
  $x0 = rand($image_w);
  $y0 = rand($image_h);
  $x1 = rand($image_w);
  $y1 = rand($image_h);
  $x2 = rand($image_w);
  $y2 = rand($image_h);

  # Init texture velocity
  $dx = $image_w/100;
  $dy = $image_h/100;
  $ix0 = rand($dx)-$dx;
  $iy0 = rand($dy)-$dy;
  $ix1 = rand($dx)-$dx;
  $iy1 = rand($dy)-$dy;
  $ix2 = rand($dx)-$dx;
  $iy2 = rand($dy)-$dy;

  # Scale velocity
  $dx0 = $sgn * $scl * $ix0;
  $dy0 = $sgn * $scl * $iy0;
  $dx1 = $sgn * $scl * $ix1;
  $dy1 = $sgn * $scl * $iy1;
  $dx2 = $sgn * $scl * $ix2;
  $dy2 = $sgn * $scl * $iy2;

  my($ifmt,$fmt,$type) = $image->Get('gl_internalformat','gl_format','gl_type');

  glTexImage2D_c($tex_mode, 0, $ifmt, $image_w, $image_h,
    0, $fmt, $type, $image->Ptr());

  glBindTexture($tex_mode, $tex_ID);
  glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);

  return 1;
}

# Rendering callback
sub cbRenderScene
{
  # Throttle FPS
  if ($hasHires && ($fps > 0))
  {
    my $spf = 1 / $fps;
    return if ($spf > (gettimeofday() - $last_time));
    $last_time = gettimeofday();
  }

  # Clear buffers
  glLoadIdentity();
  #glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  #glColor3i(1, 1, 1);

  # Load image texture
  print "Bad image\n" while (!LoadNextImage());
	
  glEnable($tex_mode);

  # Abstract texcoord extensions
  my $tw = $hasTexRect ? $image_w : 1.0;
  my $th = $hasTexRect ? $image_h : 1.0;

  # Display source image
  if ($display_source)
  {
    glBegin (GL_QUADS);
    {
      glTexCoord2f(0,0);
      glVertex2f(0,0);

      glTexCoord2f($tw,0);
      glVertex2f($wnd_width,0);

      glTexCoord2f($tw,$th);
      glVertex2f($wnd_width,$wnd_height);

      glTexCoord2f(0,$th);
      glVertex2f(0,$wnd_height);
    }
    glEnd ();
  }
  # Render tiles
  else
  {
    my $x00 = $hasTexRect ? $x0 : $x0/$image_w;
    my $y00 = $hasTexRect ? $y0 : $y0/$image_h;
    my $x01 = $hasTexRect ? $x1 : $x1/$image_w;
    my $y01 = $hasTexRect ? $y1 : $y1/$image_h;
    my $x02 = $hasTexRect ? $x2 : $x2/$image_w;
    my $y02 = $hasTexRect ? $y2 : $y2/$image_h;

    my $xa = ($x01+$x02)/2;
    my $ya = ($y01+$y02)/2;

    my $tile_x = $wnd_width / $freqx;
    my $tile_y = $wnd_height / $freqy;

    for (my $i=0; $i<$freqy; $i++)
    {
      for (my $j=0; $j<$freqx; $j++)
      {
        my $x = $j*$tile_x;
        my $y = $i*$tile_y;

        glBegin (GL_TRIANGLE_STRIP);
        {
          glTexCoord2f($xa,$ya);
          glVertex2f($x,$y+$tile_y/2);

          glTexCoord2f($x00,$y00);
          glVertex2f($x,$y);

          glTexCoord2f($x01,$y01);
          glVertex2f($x+$tile_x/6,$y+$tile_y/2);

          glTexCoord2f($x02,$y02);
          glVertex2f($x+$tile_x/3,$y);

          glTexCoord2f($x00,$y00);
          glVertex2f($x+$tile_x/2,$y+$tile_y/2);

          glTexCoord2f($x01,$y01);
          glVertex2f($x+2*$tile_x/3,$y);

          glTexCoord2f($x02,$y02);
          glVertex2f($x+5*$tile_x/6,$y+$tile_y/2);

          glTexCoord2f($x00,$y00);
          glVertex2f($x+$tile_x,$y);

          glTexCoord2f($xa,$ya);
          glVertex2f($x+$tile_x,$y+$tile_y/2);
        }
        glEnd ();

        glBegin (GL_TRIANGLE_STRIP);
        {
          glTexCoord2f($xa,$ya);
          glVertex2f($x+$tile_x,$y+$tile_y/2);

          glTexCoord2f($x00,$y00);
          glVertex2f($x+$tile_x,$y+$tile_y);

          glTexCoord2f($x02,$y02);
          glVertex2f($x+5*$tile_x/6,$y+$tile_y/2);

          glTexCoord2f($x01,$y01);
          glVertex2f($x+2*$tile_x/3,$y+$tile_y);

          glTexCoord2f($x00,$y00);
          glVertex2f($x+$tile_x/2,$y+$tile_y/2);

          glTexCoord2f($x02,$y02);
          glVertex2f($x+$tile_x/3,$y+$tile_y);

          glTexCoord2f($x01,$y01);
          glVertex2f($x+$tile_x/6,$y+$tile_y/2);

          glTexCoord2f($x00,$y00);
          glVertex2f($x,$y+$tile_y);

          glTexCoord2f($xa,$ya);
          glVertex2f($x,$y+$tile_y/2);
        }
        glEnd ();
      }
    }
  }

  glDisable($tex_mode);

  glutSwapBuffers();

  if ($fps && !$pause)
  {
    ($x0,$dx0) = nudge($x0,$dx0,$image_w);
    ($y0,$dy0) = nudge($y0,$dy0,$image_h);
    ($x1,$dx1) = nudge($x1,$dx1,$image_w);
    ($y1,$dy1) = nudge($y1,$dy1,$image_h);
    ($x2,$dx2) = nudge($x2,$dx2,$image_w);
    ($y2,$dy2) = nudge($y2,$dy2,$image_h);
  }
}

# Clamp texcoords
sub nudge
{
  my($v,$d,$max) = @_;
  $v += $d;
  return(abs($v),-$d) if ($v < 0);
  return(2*$max-$v,-$d) if ($v > $max);
  return($v,$d);
}

# Keyboard callback
sub cbKeyPressed
{
  my $key = shift;
  my $c = uc chr $key;
  if ($key == 27 or $c eq 'Q')
  {
    TermApp();
    exit(1);
  }
  elsif ($c eq 'P')
  {
    $pause = !$pause;
  }
  elsif ($c eq '*')
  {
    $fps = -1;
  }
  elsif (($c eq 'R') || ($c eq '+') || ($c eq '-'))
  {
    if ($c eq 'R')
    {
      $sgn *= -1.0;
    }
    elsif ($hasHires)
    {
      if ($c eq '+')
      {
        $fps = (($fps < 0) || ($fps >= 60)) ? -1 : $fps + 5;
      }
      elsif ($fps < 0)
      {
        $fps = 60;
      }
      elsif ($fps < 5)
      {
        $fps = 0;
      }
      else
      {
        $fps -= 5;
      }
      return;
    }
    else
    {
      if ($c eq '+')
      {
        $scl += 0.1;
      }
      elsif ($scl > 0.1)
      {
        $scl -= 0.1;
      }
      else
      {
        $scl = 0.0;
      }
    }

    $dx0 = $sgn * $scl * $ix0;
    $dy0 = $sgn * $scl * $iy0;
    $dx1 = $sgn * $scl * $ix1;
    $dy1 = $sgn * $scl * $iy1;
    $dx2 = $sgn * $scl * $ix2;
    $dy2 = $sgn * $scl * $iy2;
  }
  elsif ($c eq 'O')
  {
    $display_source = !$display_source;
  }
  elsif ($c eq 'F')
  {
    ToggleFS();
  }
  elsif ($c eq 'N')
  {
    LoadNextImage(1);
  }
  elsif ($c eq 'S')
  {
    my $frame = new OpenGL::Image(engine=>'Magick',
      width=>$wnd_width, height=>$wnd_height);
    my($fmt,$size) = $frame->Get('gl_format','gl_type');
    glReadPixels_c( 0, 0, $wnd_width, $wnd_height, $fmt, $size, $frame->Ptr() );
    $frame->Save("$name.jpg");
  }
  elsif ($c eq '0')
  {
    $freqx = $opts->{xf};
    $freqy = $opts->{yf};
  }
  elsif ($c ge '1' && $c le '9')
  {
    $freqx = $c;
    $freqy = $c;
  }
  else
  {
    printf "Key action undefined for %d.\n", $key;
  }
}

# Toggle fullscreen mode
sub ToggleFS
{
  my($enable) = @_;

  $opts->{fs} = ($enable) ? 1 : !$opts->{fs};

  if ($opts->{fs})
  {
    $save_x = glutGet(GLUT_WINDOW_X);
    $save_y = glutGet(GLUT_WINDOW_Y);
    $save_w = $wnd_width;
    $save_h = $wnd_height;
    glutFullScreen();
    $wnd_width = glutGet(GLUT_SCREEN_WIDTH);
    $wnd_height = glutGet(GLUT_SCREEN_HEIGHT);
  }
  else
  {
    $wnd_width = $save_w;
    $wnd_height = $save_h;
    glutReshapeWindow($wnd_width,$wnd_height);
    glutPositionWindow($save_x,$save_y);
  }

  $freqx = $opts->{xf};
  $freqy = $opts->{yf};
}

# Get default tiling freqencies
sub DefaultFreq
{
  my($w,$h) = @_;
  my $aspect =  ($w || $wnd_width || 1) / ($h || $wnd_height || 1);

  my($freqx,$freqy);
  if ($aspect >= 1)
  {
    $freqx = 2;
    $freqy = int(.5 + 2 * $freqx / $aspect) || 1;
  }
  else
  {
    $freqy = 2;
    $freqx = int(.5 + $freqy * $aspect / 2) || 1;
  }

  return($freqx,$freqy);
}

# Window resize callback
sub cbResizeScene
{
  my ($Width,$Height) = @_;

  $wnd_width  = $Width;
  $wnd_height = $Height;

  InitApp();
}

# Initialize app
sub InitApp
{
  glViewport(0, 0, $wnd_width, $wnd_height);

  # Set up projection matrix
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluOrtho2D(0, $wnd_width, 0, $wnd_height);

  # Load identity modelview
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  # Shading states
  glShadeModel(GL_SMOOTH);
  glClearColor(0, 0, 0, 1);
  glColor4f(1.0, 1.0, 1.0, 1.0);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

  # Depth states
  glClearDepth(1.0);
  glDepthFunc(GL_LEQUAL);
  glEnable(GL_DEPTH_TEST);

  glEnable(GL_CULL_FACE);
}

# Cleanup routine
sub TermApp
{
  # Disable app
  glutHideWindow();
  glutKeyboardFunc();
  glutSpecialFunc();
  glutIdleFunc();
  glutReshapeFunc();

  glDeleteTextures_p($tex_ID);

  # Now you can destroy window
  glutDestroyWindow($wnd_ID);
}
