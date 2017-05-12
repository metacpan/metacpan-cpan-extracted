#!/usr/bin/perl

=head1 NAME

tessellation.pl - Show workings of perl based tessellation

=head1 SOURCE

general ideas taken from:
http://glprogramming.com/red/chapter11.html

=head1 AUTHOR

Paul Seamons

=cut

use OpenGL::GLUT qw(:all);
use OpenGL::GLU qw(:all);
use OpenGL::Modern qw(:all);

use strict;
use warnings;

print "Starting $0\n";

my $color_toggle = 1;
my $edge_toggle  = 1;
my $solid_toggle = 1;
my $antialias_toggle = 1;
my $defaults_toggle  = 0;
my $opaque_toggle    = 'off';
my $opaque_cycle     = 0;
my ($w, $h) = (800, 600);

main();
exit;

sub main {
    glutInit();
    glutInitWindowSize($w, $h);
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE);
    glutCreateWindow("Tessellation");
    glClearColor (0.0, 0.0, 0.0, 0.0);

    init();

    glutDisplayFunc(\&render_scene);
    glutKeyboardFunc(sub {
        if ($_[0] == 27 || $_[0] == ord('q')) {
            exit;
        } elsif ($_[0] == ord('e')) {
            $edge_toggle = ($edge_toggle) ? 0 : 1;
        } elsif ($_[0] == ord('a')) {
            $antialias_toggle = ($antialias_toggle) ? 0 : 1;
        } elsif ($_[0] == ord('s')) {
            $solid_toggle = ($solid_toggle) ? 0 : 1;
        } elsif ($_[0] == ord('d')) {
            $defaults_toggle = ($defaults_toggle) ? 0 : 1;
        } elsif ($_[0] == ord('o')) {
            $opaque_toggle = ($opaque_toggle eq 'off') ? 'polygon_data' : ($opaque_toggle eq 'polygon_data') ? 'vertex_data' : 'off';
        } elsif ($_[0] == ord('y')) {
            $opaque_cycle++;
        } else {
            $color_toggle = ($color_toggle) ? 0 : 1;
        }
        render_scene();
    });

    print "'q' - Quit
'e' - Toggle edge flags (show triangles)
's' - Toggle solid (polygon vs lines)
'a' - Toggle anti-alias lines
'd' - Toggle perl callbacks vs default c implemented callbacks
'c' - Toggle color (perl callbacks only)
'o' - Toggle opaque data passing (off, polygon_data, vertex_data) (perl callbacks only)
'y' - Cycle the type of opaque data passed (perl callbacks only)
";
    glutMainLoop();
}

sub init {
    glViewport(0,0, $w,$h);

    glMatrixMode(GL_PROJECTION());
    glLoadIdentity();

    if ( @_ ) {
        gluPerspective(45.0,4/3,0.1,100.0);
    } else {
        glFrustum(-0.1,0.1,-0.075,0.075,0.175,100.0);
    }

    glMatrixMode(GL_MODELVIEW());
    glLoadIdentity();
}

sub render_scene {
    glClear (GL_COLOR_BUFFER_BIT);

    glLoadIdentity();
    glTranslatef(0, 0, -6);

    print "Callbacks: ".($defaults_toggle ? "c based" : '   perl')
        .", Solid: ".($solid_toggle ? ' on' : 'off')
        .", EdgeFlags: " .($edge_toggle ? ' on' : 'off')
        .", Color: " .($color_toggle ? ' on' : 'off')
        .", Anti-alias: " .($antialias_toggle ? ' on' : 'off')
        .", Opaque: $opaque_toggle"
        ."\n";

    my $tess = gluNewTess('do_color');
    my %opaque_printed;

    # ideally - these would be loaded into a call list - but this is just a sampling
    if ($defaults_toggle) {
        gluTessCallback($tess, GLU_TESS_BEGIN(),     'DEFAULT');
        gluTessCallback($tess, GLU_TESS_ERROR(),     'DEFAULT');
        gluTessCallback($tess, GLU_TESS_END(),       'DEFAULT');
        gluTessCallback($tess, GLU_TESS_VERTEX(),    'DEFAULT');
        gluTessCallback($tess, GLU_TESS_EDGE_FLAG(), 'DEFAULT') if $edge_toggle;
        gluTessCallback($tess, GLU_TESS_COMBINE(),   'DEFAULT');
    } else {
        gluTessCallback($tess, GLU_TESS_BEGIN(),     sub { glBegin(shift) });
        gluTessCallback($tess, GLU_TESS_ERROR(),     sub { my $errno = shift; my $err = gluErrorString($errno); print "got an error ($errno - $err)\n" });
        gluTessCallback($tess, GLU_TESS_END(),       sub { glEnd(); });
        gluTessCallback($tess, GLU_TESS_EDGE_FLAG(), sub { glEdgeFlag(shift) }) if $edge_toggle;

        my $type = ($opaque_toggle eq 'vertex_data') ? GLU_TESS_VERTEX() : GLU_TESS_VERTEX_DATA();
        gluTessCallback($tess, $type, sub {
            my ($x, $y, $z, $r, $g, $b, $a, $opaque) = @_;
            glColor4f($r, $g, $b, $a) if $color_toggle;
            glVertex3f($x, $y, $z);

            # the following is only a test of passing opaque polygon data or vertex data
            if ($opaque) {
                my $ref = ref($opaque) || 'SCALAR';
                my $pv = ($ref eq 'CODE')     ? $opaque->()
                       : ($ref eq 'ARRAY')    ? $opaque->[0]
                       : ($ref eq 'HASH')     ? $opaque->{'key'}
                       : ($opaque =~ /^\d+$/) ? do { $ref = 'SCALAR NUM'; chr($opaque) }
                       : $opaque;
                my $str = "Vertices were passed ".($pv eq 'p' ? 'polygon' : $pv eq 'v' ? 'vertex' : "other ($pv)")." data of type $ref\n";
                print $str if ! $opaque_printed{$str}++;
                print "We received a non-vertex data type ($pv $ref)\n" if $opaque_toggle eq 'vertex_data' && $pv ne 'v';
            }
        });

        gluTessCallback($tess, GLU_TESS_COMBINE(), sub {
            my ($x, $y, $z,
                $v0, $v1, $v2, $v3,
                $w0, $w1, $w2, $w3,
                $polygon_data) = @_; # polygon data is passed to COMBINE in addition to COMBINE_DATA

            # GLU_TESS_COMBINE and GLU_TESS_COMBINE_DATA call the same code so polygon data is always passed
            # When GLU_TESS_VERTEX is used, the two-four opaque elements passed to gluTessVertex are passed as the final element of each vector data
            #     In the GLU_TESS_VERTEX case an 8th return parameter can then be returned which can be any perl variable,
            #     which is then eventually passed as the data to the GLU_TESS_VERTEX callback.
            return (
                $x, $y, $z,
                $w0*$v0->[3] + $w1*$v1->[3] + $w2*$v2->[3] + $w3*$v3->[3],
                $w0*$v0->[4] + $w1*$v1->[4] + $w2*$v2->[4] + $w3*$v3->[4],
                $w0*$v0->[5] + $w1*$v1->[5] + $w2*$v2->[5] + $w3*$v3->[5],
                $w0*$v0->[6] + $w1*$v1->[6] + $w2*$v2->[6] + $w3*$v3->[6],
                ((@$v0 == 8 || @$v0 == 11) ? ($v0->[7] || $v1->[7] || $v2->[7] || $v3->[7]) : ()), # if we received vertex data - return some for the new vertex
                );
        });
    }

    glPolygonMode(GL_FRONT_AND_BACK, $solid_toggle ? GL_FILL : GL_LINE);

    glEnable (GL_BLEND);
    if ($antialias_toggle) {
        glEnable (GL_LINE_SMOOTH);
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glHint (GL_LINE_SMOOTH_HINT, GL_DONT_CARE);
        glHint (GL_POLYGON_SMOOTH_HINT, GL_DONT_CARE);
    } else {
        glDisable(GL_LINE_SMOOTH);
    }

    glColor3f(1,1,1);

    # triangle
    glPushMatrix();
    glTranslatef(-2.2, 1.2, 0);
    glScalef(.9, .9, 0);
    my $tri1 = [[0,1,0, 1,0,0,1], [-1,-1,0, 0,1,0,1], [1,-1,0, 0,0,1,1]];
    gluTessBeginPolygon($tess);
    gluTessBeginContour($tess);
    for my $q (@$tri1) {
        gluTessVertex_p($tess, @$q);
    }
    gluTessEndContour($tess);
    gluTessEndPolygon($tess);
    glPopMatrix();

    # square
    glPushMatrix();
    glTranslatef(0, 1.2, 0);
    glScalef(.9, .9, 0);
    my $quad0 = [[-1,1,0, 1,0,0,1], [1,1,0, 0,1,0,1], [1,-1,0, 0,0,1,1], [-1,-1,0, 1,1,0,1]];
    $quad0 = [reverse @$quad0];
    gluTessBeginPolygon($tess);
    gluTessBeginContour($tess);
    for my $q (@$quad0) {
        gluTessVertex_p($tess, @$q);
    }
    gluTessEndContour($tess);
    glColor3f(1,1,1);
    gluTessEndPolygon($tess);
    glPopMatrix();

    # pontiac
    glPushMatrix();
    glTranslatef(2.2, .1, 0);
    glScalef(.7, .7, 0);
    my $quad1 = [[-1,3,0, 1,0,0,1], [0,0,0, 1,1,0,1], [1,3,0, 0,0,1,1], [0,2,0, 0,1,0,1]];
    gluTessBeginPolygon($tess);
    gluTessBeginContour($tess);
    for my $q (@$quad1) {
        gluTessVertex_p($tess, @$q);
    }
    gluTessEndContour($tess);
    glColor3f(1,1,1);
    gluTessEndPolygon($tess);
    glPopMatrix();

    # window
    glPushMatrix();
    glTranslatef(-2.2, -2.1, 0);
    glScalef(.45, .45, 0);
    my $quad2 = [
        [[-2,3,0, 1,0,0,1], [-2,0,0, 1,1,0,1], [2,0,0, 0,0,1,1], [2,3,0, 0,1,0,1]],
        [[-1,2,0, 1,0,0,1], [-1,1,0, 1,1,0,1], [1,1,0, 0,0,1,1], [1,2,0, 0,1,0,1]],
        ];
    gluTessBeginPolygon($tess);
    for my $c (@$quad2) {
        gluTessBeginContour($tess);
        for my $q (@$c) {
            gluTessVertex_p($tess, @$q);
        }
        gluTessEndContour($tess);
    }
    glColor3f(1,1,1);
    gluTessEndPolygon($tess);
    glPopMatrix();

    # star
    glPushMatrix();
    glTranslatef(0, -2.1, 0);
    glScalef(.6, .6, 0);
    my $coord3 = [
        [ 0.0, 3.0, 0,  1,0,0,1],
        [-1.0, 0.0, 0,  0,1,0,1],
        [ 1.6, 1.9, 0,  1,0,1,1],
        [-1.6, 1.9, 0,  1,1,0,1],
        [ 1.0, 0.0, 0,  0,0,1,1],
        ];
    gluTessProperty($tess, GLU_TESS_WINDING_RULE(), GLU_TESS_WINDING_NONZERO());
    my @p_cycle = (sub { "p" }, ["p"], {key => "p"}, "p", ord('p'));
    my @v_cycle = (sub { "v" }, ["v"], {key => "v"}, "v", ord('v'));
    if ($opaque_toggle eq 'off') {
        gluTessBeginPolygon($tess);
    } else {
        gluTessBeginPolygon($tess, $p_cycle[$opaque_cycle % @p_cycle]);
    }
    gluTessBeginContour($tess);
    for my $q (@$coord3) {
        if ($opaque_toggle eq 'off') {
            gluTessVertex_p($tess, @$q);
        } else {
            gluTessVertex_p($tess, @$q, $v_cycle[$opaque_cycle % @v_cycle]);
        }
    }
    gluTessEndContour($tess);
    glColor3f(1,1,1);
    gluTessEndPolygon($tess);
    glPopMatrix();

    # octagon
    glPushMatrix();
    glTranslatef(2, -1.3, 0);
    glScalef(.35, .35, 0);
    my $coord4 = [
        [   -1,  2.4, 0,   1, 0, 0,1],
        [    1,  2.4, 0,   1, 1, 0,1],
        [  2.4,    1, 0,   0, 1, 0,1],
        [  2.4,   -1, 0,   0, 1, 1,1],
        [    1, -2.4, 0,   0, 0, 1,1],
        [   -1, -2.4, 0,   1, 0, 1,1],
        [ -2.4,   -1, 0,   1, 1, 1,1],
        [ -2.4,    1, 0,  .5,.5,.5,1],
        ];
    $coord4 = [reverse @$coord4];
    gluTessProperty($tess, GLU_TESS_WINDING_RULE(), GLU_TESS_WINDING_ODD());
    gluTessBeginPolygon($tess);
    gluTessBeginContour($tess);
    for my $q (@$coord4) {
        gluTessVertex_p($tess, @$q);
    }
    gluTessEndContour($tess);
    glColor3f(1,1,1);
    gluTessEndPolygon($tess);
    glPopMatrix();


    gluDeleteTess($tess);

    glutSwapBuffers();
}
