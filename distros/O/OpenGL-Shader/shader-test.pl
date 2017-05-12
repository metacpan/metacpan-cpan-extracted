#!/usr/bin/perl

# Purpose: Simple demo of per-pixel lighting with GLSL and OpenGL::Shader

# Copyright (c) 2007, Geoff Broadwell; this script is released
# as open source and may be distributed and modified under the terms
# of either the Artistic License or the GNU General Public License,
# in the same manner as Perl itself.  These licenses should have been
# distributed to you as part of your Perl distribution, and can be
# read using `perldoc perlartistic` and `perldoc perlgpl` respectively.

use strict;
use warnings;
use OpenGL ':all';
use OpenGL::Shader;
use Time::HiRes 'time';

our $VERSION = '0.1.0';

my $width  = 1000;
my $height = 1000;
my ($frames, $start);
my ($window, $teapot);
my ($shader, $shader_enabled);

go();

sub go {
    # Simple usage
    print "Press 'Q' or 'Esc' to exit, or any other key to toggle shader.\n";

    # GLUT setup
    glutInit;
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE | GLUT_DEPTH);
    glutInitWindowSize($width, $height);

    $window = glutCreateWindow('Shader Test');

    glutIdleFunc    (\&cb_draw);
    glutDisplayFunc (\&cb_draw);
    glutKeyboardFunc(\&cb_keyboard);

    # Shader program
    $shader      = new OpenGL::Shader('GLSL');
    die "This program requires support for GLSL shaders.\n" unless $shader;

    my $fragment = fragment_shader();
    my $vertex   = vertex_shader();
    my $info     = $shader->Load($fragment, $vertex);
    print $info if $info;
    toggle_shader();

    # Display list for teapot
    $teapot = glGenLists(1);
    glNewList($teapot, GL_COMPILE);
    glutSolidTeapot(1);
    glEndList;

    # Unchanging GL config
    glViewport(0, 0, $width, $height);

    glEnable(GL_DEPTH_TEST);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    gluPerspective(90, $width/$height, 1, 10);
    glMatrixMode(GL_MODELVIEW);

    glShadeModel(GL_SMOOTH);
    glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glLightfv_p(GL_LIGHT0, GL_POSITION, 4, 4, 4, 1);

    glMaterialfv_p(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, 1, .7, .7, 1);
    glMaterialfv_p(GL_FRONT_AND_BACK, GL_SPECULAR,            1,  1,  1, 1);
    glMaterialf   (GL_FRONT_AND_BACK, GL_SHININESS,           50          );

    # Actually start the test
    $start = time;
    glutMainLoop;
}

sub cb_draw {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glLoadIdentity;
    glTranslatef(0, 0, -3);

    my $slow_time = time / 5;
    my $frac_time = $slow_time - int $slow_time;
    my $angle     = $frac_time * 360;
    glRotatef($angle, 0, 1, 0);
    glRotatef(30, 1, 0, 0);

    glCallList($teapot);

    glutSwapBuffers;

    $frames++;
}

sub cb_keyboard {
    my $key = shift;
    my $chr = lc chr $key;

    if ($key == 27 or $chr eq 'q') {
        my $time = time - $start;
        my $fps  = $frames / $time;
        printf "%.3f FPS\n", $fps;

        glutDestroyWindow($window);
        exit(0);
    }
    else {
        toggle_shader();
    }
}

sub toggle_shader {
    $shader_enabled = !$shader_enabled;
    $shader_enabled ? $shader->Enable : $shader->Disable;
}

sub vertex_shader {
    return <<'VERTEX';

varying vec3 Normal;
varying vec3 Position;

void main(void) {
    gl_Position = ftransform();
    Position    = vec3(gl_ModelViewMatrix * gl_Vertex);
    Normal      = gl_NormalMatrix * gl_Normal;
}

VERTEX
}

sub fragment_shader {
    return <<'FRAGMENT';

varying vec3 Position;
varying vec3 Normal;

void main(void) {
    vec3 normal    = normalize(Normal);
    vec3 reflected = normalize(reflect(Position, normal));
    vec3 light_dir = normalize(vec3(gl_LightSource[0].position) - Position);

    float diffuse  = max  (dot(light_dir, normal   ), 0.0);
    float spec     = clamp(dot(light_dir, reflected), 0.0, 1.0);
          spec     = pow  (spec, gl_FrontMaterial.shininess);

    gl_FragColor   =             gl_FrontLightModelProduct.sceneColor
                     +           gl_FrontLightProduct[0].ambient
                     + diffuse * gl_FrontLightProduct[0].diffuse
                     + spec    * gl_FrontLightProduct[0].specular;
}

FRAGMENT
}
