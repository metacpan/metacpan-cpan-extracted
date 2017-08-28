#========================================================================
#  3-D gear wheels.  This program is in the public domain.
#
#  Command line options:
#     -info      print GL implementation information
#     -exit      automatically exit after 30 seconds
#
#
#  Brian Paul
#
#
#  Marcus Geelnard:
#    - Conversion to GLFW
#    - Time based rendering (frame rate independent)
#    - Slightly modified camera that should work better for stereo viewing
#
#
#  Camilla Berglund:
#    - Removed FPS counter (this is not a benchmark)
#    - Added a few comments
#    - Enabled vsync
#========================================================================

use OpenGL::GLFW qw(:all);
use OpenGL::Modern qw(:all);
use OpenGL::Modern::Helpers qw(pack_GLfloat);

glpSetAutoCheckErrors( 1 );

#========================================================================
#
# OpenGL routines used in this example:
#
#     glBegin
#     glCallList
#     glClear
#     glEnable
#     glEnd
#     glEndList
#     glFrustum
#     glGenLists
#     glLightfv_p           TODO: add to OpenGL::Modern::Helpers
#     glLoadIdentity
#     glMaterialfv_p        TODO: add to OpenGL::Modern::Helpers
#     glMatrixMode
#     glNewList
#     glNormal3f
#     glPopMatrix
#     glPushMatrix
#     glRotatef
#     glShadeModel
#     glTranslatef
#     glVertex3f
#     glViewport
#
#========================================================================

#========================================================================
#
# Draw a gear wheel.  You'll probably want to call this function when
# building a display list since we do a lot of trig here.
#
# Input:  $inner_radius - radius of hole at center
#         $outer_radius - radius at center of teeth
#         $width - width of gear teeth - number of teeth
#         $tooth_depth - depth of tooth
#
#========================================================================

use Config;
our $PACK_TYPE = $Config{ptrsize} == 4 ? 'L' : 'Q';

use constant M_PI => 3.14159265358979323846;

sub glMaterialfv_p {
    my ( $face, $pname, @pvalues ) = @_;
    my $params = pack_GLfloat( @pvalues );    # set up packed data
    glMaterialfv_c( $face, $pname, unpack( $PACK_TYPE, pack( 'P', $params ) ) );    # get pointer value
}

sub glLightfv_p {
    my ( $light, $pname, @pvalues ) = @_;
    my $params = pack_GLfloat( @pvalues );                                          # set up packed data
    glLightfv_c( $light, $pname, unpack( $PACK_TYPE, pack( 'P', $params ) ) );      # get pointer value
}

sub gear {
    my ( $inner_radius, $outer_radius, $width, $teeth, $tooth_depth ) = @_;
    my $i;
    my $r0, $r1, $r2;
    my $angle, $da;
    my $u, $v, $len;

    $r0 = $inner_radius;
    $r1 = $outer_radius - $tooth_depth / 2;
    $r2 = $outer_radius + $tooth_depth / 2;

    $da = 2 * M_PI / $teeth / 4;

    glShadeModel( GL_FLAT );

    glNormal3f( 0.0, 0.0, 1.0 );

    # draw front face
    glBegin( GL_QUAD_STRIP );
    for ( $i = 0 ; $i <= $teeth ; $i++ ) {
        $angle = $i * 2 * M_PI / $teeth;
        glVertex3f( $r0 * cos( $angle ), $r0 * sin( $angle ), $width * 0.5 );
        glVertex3f( $r1 * cos( $angle ), $r1 * sin( $angle ), $width * 0.5 );
        if ( $i < $teeth ) {
            glVertex3f( $r0 * cos( $angle ),           $r0 * sin( $angle ),           $width * 0.5 );
            glVertex3f( $r1 * cos( $angle + 3 * $da ), $r1 * sin( $angle + 3 * $da ), $width * 0.5 );
        }
    }
    glEnd();

    # draw front sides of teeth
    glBegin( GL_QUADS );
    $da = 2 * M_PI / $teeth / 4;
    for ( $i = 0 ; $i < $teeth ; $i++ ) {
        $angle = $i * 2 * M_PI / $teeth;

        glVertex3f( $r1 * cos( $angle ),           $r1 * sin( $angle ),           $width * 0.5 );
        glVertex3f( $r2 * cos( $angle + $da ),     $r2 * sin( $angle + $da ),     $width * 0.5 );
        glVertex3f( $r2 * cos( $angle + 2 * $da ), $r2 * sin( $angle + 2 * $da ), $width * 0.5 );
        glVertex3f( $r1 * cos( $angle + 3 * $da ), $r1 * sin( $angle + 3 * $da ), $width * 0.5 );
    }
    glEnd();

    glNormal3f( 0.0, 0.0, -1.0 );

    # draw back face
    glBegin( GL_QUAD_STRIP );
    for ( $i = 0 ; $i <= $teeth ; $i++ ) {
        $angle = $i * 2 * M_PI / $teeth;
        glVertex3f( $r1 * cos( $angle ), $r1 * sin( $angle ), -$width * 0.5 );
        glVertex3f( $r0 * cos( $angle ), $r0 * sin( $angle ), -$width * 0.5 );
        if ( $i < $teeth ) {
            glVertex3f( $r1 * cos( $angle + 3 * $da ), $r1 * sin( $angle + 3 * $da ), -$width * 0.5 );
            glVertex3f( $r0 * cos( $angle ),           $r0 * sin( $angle ),           -$width * 0.5 );
        }
    }
    glEnd();

    # draw back sides of teeth
    glBegin( GL_QUADS );
    $da = 2 * M_PI / $teeth / 4;
    for ( $i = 0 ; $i < $teeth ; $i++ ) {
        $angle = $i * 2 * M_PI / $teeth;

        glVertex3f( $r1 * cos( $angle + 3 * $da ), $r1 * sin( $angle + 3 * $da ), -$width * 0.5 );
        glVertex3f( $r2 * cos( $angle + 2 * $da ), $r2 * sin( $angle + 2 * $da ), -$width * 0.5 );
        glVertex3f( $r2 * cos( $angle + $da ),     $r2 * sin( $angle + $da ),     -$width * 0.5 );
        glVertex3f( $r1 * cos( $angle ),           $r1 * sin( $angle ),           -$width * 0.5 );
    }
    glEnd();

    # draw outward faces of teeth
    glBegin( GL_QUAD_STRIP );
    for ( $i = 0 ; $i < $teeth ; $i++ ) {
        $angle = $i * 2 * M_PI / $teeth;

        glVertex3f( $r1 * cos( $angle ), $r1 * sin( $angle ), $width * 0.5 );
        glVertex3f( $r1 * cos( $angle ), $r1 * sin( $angle ), -$width * 0.5 );
        $u   = $r2 * cos( $angle + $da ) - $r1 * cos( $angle );
        $v   = $r2 * sin( $angle + $da ) - $r1 * sin( $angle );
        $len = sqrt( $u * $u + $v * $v );
        $u /= $len;
        $v /= $len;
        glNormal3f( $v, -$u, 0.0 );
        glVertex3f( $r2 * cos( $angle + $da ), $r2 * sin( $angle + $da ), $width * 0.5 );
        glVertex3f( $r2 * cos( $angle + $da ), $r2 * sin( $angle + $da ), -$width * 0.5 );
        glNormal3f( cos( $angle ), sin( $angle ), 0 );
        glVertex3f( $r2 * cos( $angle + 2 * $da ), $r2 * sin( $angle + 2 * $da ), $width * 0.5 );
        glVertex3f( $r2 * cos( $angle + 2 * $da ), $r2 * sin( $angle + 2 * $da ), -$width * 0.5 );
        $u = $r1 * cos( $angle + 3 * $da ) - $r2 * cos( $angle + 2 * $da );
        $v = $r1 * sin( $angle + 3 * $da ) - $r2 * sin( $angle + 2 * $da );
        glNormal3f( $v, -$u, 0 );
        glVertex3f( $r1 * cos( $angle + 3 * $da ), $r1 * sin( $angle + 3 * $da ), $width * 0.5 );
        glVertex3f( $r1 * cos( $angle + 3 * $da ), $r1 * sin( $angle + 3 * $da ), -$width * 0.5 );
        glNormal3f( cos( $angle ), sin( $angle ), 0 );
    }

    glVertex3f( $r1 * cos( 0 ), $r1 * sin( 0 ), $width * 0.5 );
    glVertex3f( $r1 * cos( 0 ), $r1 * sin( 0 ), -$width * 0.5 );

    glEnd();

    glShadeModel( GL_SMOOTH );

    # draw inside radius cylinder
    glBegin( GL_QUAD_STRIP );
    for ( $i = 0 ; $i <= $teeth ; $i++ ) {
        $angle = $i * 2 * M_PI / $teeth;
        glNormal3f( -cos( $angle ), -sin( $angle ), 0 );
        glVertex3f( $r0 * cos( $angle ), $r0 * sin( $angle ), -$width * 0.5 );
        glVertex3f( $r0 * cos( $angle ), $r0 * sin( $angle ), $width * 0.5 );
    }
    glEnd();

}

my ( $view_rotx, $view_roty, $view_rotz ) = ( 20, 30, 0 );
my $gear1, $gear2, $gear3;
my $angle = 0;

# OpenGL draw function & timing
sub draw {
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glPushMatrix();
    glRotatef( $view_rotx, 1.0, 0.0, 0.0 );
    glRotatef( $view_roty, 0.0, 1.0, 0.0 );
    glRotatef( $view_rotz, 0.0, 0.0, 1.0 );

    glPushMatrix();
    glTranslatef( -3.0, -2.0, 0.0 );
    glRotatef( $angle, 0.0, 0.0, 1.0 );
    glCallList( $gear1 );
    glPopMatrix();

    glPushMatrix();
    glTranslatef( 3.1, -2, 0 );
    glRotatef( -2 * $angle - 9, 0, 0, 1 );
    glCallList( $gear2 );
    glPopMatrix();

    glPushMatrix();
    glTranslatef( -3.1, 4.2, 0 );
    glRotatef( -2 * $angle - 25, 0, 0, 1 );
    glCallList( $gear3 );
    glPopMatrix();

    glPopMatrix();
}

# update animation parameters
sub animate {
    $angle = 100 * glfwGetTime();
}

# change view angle, exit upon ESC
my $key = sub {
    my ( $window, $k, $s, $action, $mods ) = @_;

    return if $action != GLFW_PRESS;

    for ( $k ) {
        if ( $k == GLFW_KEY_Z ) {
            if ( $mods & GLFW_MOD_SHIFT ) {
                $view_rotz -= 5.0;
            }
            else {
                $view_rotz += 5.0;
            }
        }
        if ( $k == GLFW_KEY_ESCAPE ) {
            glfwSetWindowShouldClose( $window, GLFW_TRUE );
        }
        if ( $k == GLFW_KEY_UP ) {
            $view_rotx += 5.0;
        }
        if ( $k == GLFW_KEY_DOWN ) {
            $view_rotx -= 5.0;
        }
        if ( $k == GLFW_KEY_LEFT ) {
            $view_roty += 5.0;
        }
        if ( $k == GLFW_KEY_RIGHT ) {
            $view_roty -= 5.0;
        }
        return;
    }
};

# new window size
my $reshape = sub {
    my ( $window, $width, $height ) = @_;
    my $h = $height / $width;
    my $xmax, $znear, $zfar;

    $znear = 5.0;
    $zfar  = 30.0;
    $xmax  = $znear * 0.5;

    glViewport( 0, 0, $width, $height );
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glFrustum( -$xmax, $xmax, -$xmax * $h, $xmax * $h, $znear, $zfar );
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    glTranslatef( 0.0, 0.0, -20.0 );
};

# program & OpenGL initialization
sub init {
    my @pos   = ( 5,   5,   10,  0 );
    my @red   = ( 0.8, 0.1, 0,   1 );
    my @green = ( 0,   0.8, 0.2, 1 );
    my @blue  = ( 0.2, 0.2, 1,   1 );

    glLightfv_p( GL_LIGHT0, GL_POSITION, @pos );
    glEnable( GL_CULL_FACE );
    glEnable( GL_LIGHTING );
    glEnable( GL_LIGHT0 );
    glEnable( GL_DEPTH_TEST );

    # make the gears
    $gear1 = glGenLists( 1 );
    glNewList( $gear1, GL_COMPILE );
    glMaterialfv_p( GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @red );
    gear( 1, 4, 1, 20, 0.7 );
    glEndList();

    $gear2 = glGenLists( 1 );
    glNewList( $gear2, GL_COMPILE );
    glMaterialfv_p( GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @green );
    gear( 0.5, 2, 2, 10, 0.7 );
    glEndList();

    $gear3 = glGenLists( 1 );
    glNewList( $gear3, GL_COMPILE );
    glMaterialfv_p( GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @blue );
    gear( 1.3, 2, 0.5, 10, 0.7 );
    glEndList();

    glEnable( GL_NORMALIZE );
}

#========================================================================
# Main program entry
#========================================================================

my $window;
my $width, $height;

if ( !glfwInit() ) {
    die "Failed to initialize GLFW\n";
}

glfwWindowHint( GLFW_DEPTH_BITS, 16 );

$window = glfwCreateWindow( 300, 300, "Gears", NULL, NULL );
if ( !$window ) {
    glfwTerminate();
    die "Failed to open GLFW window\n";
}

# Set callback functions
glfwSetFramebufferSizeCallback( $window, $reshape );
glfwSetKeyCallback( $window, $key );

glfwMakeContextCurrent( $window );
glfwSwapInterval( 1 );

( $width, $height ) = glfwGetFramebufferSize( $window );
&$reshape( $window, $width, $height );

# Parse command-line options
init();

# Main loop
while ( !glfwWindowShouldClose( $window ) ) {

    # Draw gears
    draw();

    # Update animation
    animate();

    # Swap buffers
    glfwSwapBuffers( $window );
    glfwPollEvents();
}

# Terminate GLFW
glfwTerminate();
