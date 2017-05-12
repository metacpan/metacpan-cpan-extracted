#!/usr/bin/perl
use strict;
use warnings;
use SDL::OpenGL::Cg qw/:all/;
use SDL::OpenGL;
use SDL;
use SDL::Event;
use SDL::OpenGL;
use SDL::App;

# mydump();
my $app = new SDL::App ( -w => 800, -h => 600, -d => 16, -gl => 1 );

# Init SDL
SDL::Init (SDL_INIT_VIDEO())==0 or die "Cannot init SDL";
$app->sync();

glViewport(0,0,800,600);
glMatrixMode(GL_PROJECTION());
glLoadIdentity();
glFrustum(-0.1, 0.1, -0.075, 0.075, 0.175, 100.0);
glShadeModel(GL_SMOOTH());
glClearDepth(1);
glEnable(GL_DEPTH_TEST);
glDepthFunc(GL_LEQUAL);
glClear(GL_COLOR_BUFFER_BIT() | GL_DEPTH_BUFFER_BIT());
glMatrixMode(GL_MODELVIEW());
glLoadIdentity();

# Activate the shader.
my $cg = SDL::OpenGL::Cg->new();
list_supported_profiles();
my $vertex_profile = activate_vertex_profile();
my $cg_context = cgCreateContext();
$cg_context or die "Cannot create context\n";
my $file = '../shaders/vertex/xyplot.cg';

my $vertex_program =
  cgCreateProgramFromFile($cg_context, CG_SOURCE(),
  $file, $vertex_profile, 'main', undef);
$vertex_program or die "Cannot load program from file ".cgGetError()."\n";
cgLoadProgram($vertex_program) or die "Cannot load program onto GPU\n";
cgBindProgram($vertex_program);

# Grab the modelview parameter so the shader can be controlled.
my $modelview_param = cgGetNamedParameter($vertex_program, 'modelViewProj');
$modelview_param or die "Cannot get modelViewProj param\n";

my $event = new SDL::Event;
my $rotx = 0;
my $roty = 0;
redraw($rotx, $roty);
$app->sync();

print "Controls\n";
print "  Arrow keys rotate cube\n";
print "  Escape quits\n";

$app->loop({
  SDL_QUIT() => sub {
    cgDestroyContext($cg_context);
    cgDisableProfile($vertex_profile);
    exit (0)
  },
  SDL_KEYDOWN() => sub {
    my ($event) = @_;
    my $keysym = $event->key_sym();
    
    if ($keysym == SDLK_ESCAPE) {
      cgDestroyContext($cg_context);
      cgDisableProfile($vertex_profile);
      exit(0);
    } elsif ($keysym == SDLK_UP) {
      redraw($rotx-=5,$roty);
      $app->sync();
    } elsif ($keysym == SDLK_DOWN) {
      redraw($rotx+=5,$roty);
      $app->sync();
    } elsif ($keysym == SDLK_RIGHT) {
      redraw($rotx, $roty+=5);
      $app->sync();
    } elsif ($keysym == SDLK_LEFT) {
      redraw($rotx, $roty-=5);
      $app->sync();
    }
  },
});

sub redraw {
  my ($rotx,$roty) = @_;
  glClear (GL_DEPTH_BUFFER_BIT() | GL_COLOR_BUFFER_BIT());
  glLoadIdentity();
  glTranslate(0,0,-6);
  glRotate($rotx, 1,0,0);
  glRotate($roty, 0,1,0);
  glColor (1,1,1);

  my @verts = (
    [ -1,1,1], [1,1,1], [-1,-1,1], [1,-1,1],
    [ -1,1,-1], [1,1,-1], [-1,-1,-1], [1,-1,-1],
  );

  # Update the shader's modelview to the current OpenGL view.
  cgSetStateMatrixParameter($modelview_param,
    CG_MODELVIEW_PROJECTION_MATRIX(), CG_MATRIX_IDENTITY())
    or die "Cannot set modelViewProj parameter to OpenGL's\n";

  glBegin (GL_QUADS);
    glNormal(0,0,1);
    glVertex(@{$verts[0]});
    glVertex(@{$verts[1]});
    glVertex(@{$verts[3]});
    glVertex(@{$verts[2]});

    glNormal(1,0,0);
    glVertex(@{$verts[3]});
    glVertex(@{$verts[1]});
    glVertex(@{$verts[5]});
    glVertex(@{$verts[7]});

    glNormal(0,1,0);
    glVertex(@{$verts[0]});
    glVertex(@{$verts[1]});
    glVertex(@{$verts[5]});
    glVertex(@{$verts[4]});

    glNormal(-1,0,0);
    glVertex(@{$verts[2]});
    glVertex(@{$verts[0]});
    glVertex(@{$verts[4]});
    glVertex(@{$verts[6]});

    glNormal(0,-1,0);
    glVertex(@{$verts[2]});
    glVertex(@{$verts[3]});
    glVertex(@{$verts[7]});
    glVertex(@{$verts[6]});

    glNormal(0,0,-1);
    glVertex(@{$verts[4]});
    glVertex(@{$verts[5]});
    glVertex(@{$verts[7]});
    glVertex(@{$verts[6]});
  glEnd();
}

sub list_supported_profiles {
  print "Fragment profiles\n";
  print "  ARBFP1 : ",
    cgIsProfileSupported(CG_PROFILE_ARBFP1()) ? "Yes\n" : "No\n";
  print "  FP20 : ",
    cgIsProfileSupported(CG_PROFILE_FP20()) ? "Yes\n" : "No\n";
  print "  FP20 : ",
    cgIsProfileSupported(CG_PROFILE_FP30()) ? "Yes\n" : "No\n";
  print "Vertex profiles\n";
  print "  ARBVP1 : ",
    cgIsProfileSupported(CG_PROFILE_ARBVP1()) ? "Yes\n" : "No\n";
  print "  VP20 : ",
    cgIsProfileSupported(CG_PROFILE_VP20()) ? "Yes\n" : "No\n";
  print "  VP30 : ",
    cgIsProfileSupported(CG_PROFILE_VP30()) ? "Yes\n" : "No\n";
}
 
sub activate_vertex_profile {
  my @profiles = (CG_PROFILE_ARBVP1(), CG_PROFILE_VP20(), CG_PROFILE_VP30());
  foreach my $profile (@profiles) {
    if (cgIsProfileSupported($profile)) {
      print "Activating ",cgGetProfileString($profile),"\n";
      unless (cgEnableProfile($profile)) {
        die "Error activating profile ",cgGetError(),"\n";
      }
      return $profile;
    } else {
      print cgGetProfileString($profile), " not supported, skipping\n";
    }
  }
  die "No vertex profiles supported\n";
}
