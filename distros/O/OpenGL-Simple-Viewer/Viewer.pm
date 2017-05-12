package OpenGL::Simple::Viewer;

use 5.006001;
use strict;
$^W=1;
use OpenGL::Simple ':all';
use OpenGL::Simple::GLUT ':all';
use Math::Quaternion;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::Simple::Viewer ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
'all' => [ qw(
        basic_mousefunc
        basic_reshapefunc
        basic_motionfunc
        basic_displayfunc
        postredisplay
        ) ],
'basic' => [ qw(
        basic_mousefunc
        basic_reshapefunc
        basic_motionfunc
        basic_displayfunc
        postredisplay
)],

);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# These variables are for the old-style basic_* functions.

our ($clickx, $clicky, %buttonstate) = (0,0,
 GLUT_LEFT_BUTTON(), 0, GLUT_MIDDLE_BUTTON(), 0, GLUT_RIGHT_BUTTON(), 0 );
 
our $orientation = new Math::Quaternion;
our $mousescale    = 0.01;
our $zoomscale     = 0.1;
our ($geomx, $geomy, $geomz) = (0,0,0);
my $sphererad;

# Let's dump the old functions here as well.

sub basic_reshapefunc {
    my ( $screenx, $screeny ) = @_;
    $sphererad = $screeny * 0.5;
    glViewport( 0, 0, $screenx, $screeny );
}

sub basic_mousefunc {
    my ( $button, $state, $x, $y ) = @_;

    ( $clickx, $clicky ) = ( $x, $y );
    $buttonstate{$button} = ( GLUT_DOWN() == $state ) ? 1 : 0;
}

sub basic_motionfunc {
    my ( $x, $y ) = @_;
    my ( $left, $mid, $right ) =
      @buttonstate{ GLUT_LEFT_BUTTON(), GLUT_MIDDLE_BUTTON(), GLUT_RIGHT_BUTTON() };

    if ($left) { basic_mouserotatemotion( $clickx, $clicky, $x, $y ); }
    elsif ($mid) { basic_mousezoommotion( $y - $clicky ); }
    elsif ($right) { basic_mousetransmotion( $clickx, $clicky, $x, $y ); }
    ( $clickx, $clicky ) = ( $x, $y );
}

sub postredisplay { glutPostRedisplay(); }

sub basic_mouserotatemotion {
    my ( $x0, $y0, $x1, $y1 ) = @_;

    my $s  = $sphererad;
    my $my = $x1 - $x0; my $mx = $y1 - $y0;
    my $m  = sqrt( $mx * $mx + $my * $my );

    my $theta;
    if ( ( $m > 0 ) && ( $m < $s ) ) {
        $theta = $m / $s;

        $mx /= $m;
        $my /= $m;

        my $rotquat = Math::Quaternion::rotation( $theta, $mx, $my, 0.0 );
        $orientation = $rotquat * $orientation;
    }

    postredisplay;
}

sub basic_mousetransmotion {
    my ( $x0, $y0, $x1, $y1 ) = @_;
    $geomx += $mousescale * ( $x1 - $x0 );
    $geomy += $mousescale * ( $y0 - $y1 );
    postredisplay;
}

sub basic_mousezoommotion { $geomz -= $zoomscale * shift; postredisplay; }

sub drawback { glClear( GL_COLOR_BUFFER_BIT() | GL_DEPTH_BUFFER_BIT() ); }

sub basic_displayfunc {
    my $callback = shift;
    return sub {
    drawback();

    # Set up perspective projection
    glMatrixMode(GL_PROJECTION());
    glLoadIdentity();
    gluPerspective( 45.0, 1.0, 0.1, 100.0 );
    glMatrixMode(GL_MODELVIEW());
    glLoadIdentity();

    # Position and orient geometry

    glTranslate( $geomx, $geomy, $geomz );
    my @m = $orientation->matrix4x4;
    glMultMatrix(@m);
    $callback->();
    glFlush();
    glutSwapBuffers();
    }
}

=head1 NAME

OpenGL::Simple::Viewer - Simple 3D geometry viewer using GLUT

=head1 SYNOPSIS

  use OpenGL::Simple::Viewer;
  use OpenGL::Simple::GLUT qw(:all);

  glutInit;

  my $v = new OpenGL::Simple::Viewer(
                draw_geometry => sub { glutSolidTeapot(1.0); }
  );

  glutMainLoop;


=head1 ABSTRACT

This module uses OpenGL::Simple and OpenGL::Simple::GLUT to provide a
quick and simple geometry viewer. If you just want to view a single
biomolecule, or throw some polygons at the screen and make sure they
come out looking OK, then this module might be for you. If you want to
write a first-person-shooter or comprehensive visualization toolkit,
this module is probably not for you.

=head1 DESCRIPTION

This package provides a simple OpenGL geometry viewer, through the GLUT
library. An instance of OpenGL::Simple::Viewer opens a GLUT window, and
renders some geometry provided through a callback subroutine; the
geometry can be rotated, translated, and zoomed using the mouse.

When the viewer moves around, the window must be redrawn; this usually
entails clearing the window, redrawing the background, setting the
correct position and orientation, and then drawing the geometry. By
default, all you need to supply is a subroutine which draws the
geometry; everything else is taken care of. User-defined backgrounds can
be set through a callback.

An OpenGL::Simple::Viewer object can be treated as a hashref with
several user-adjustable properties:

=over 1

=item B<position>

This is a reference to an array of three numbers, corresponding to the
position of the viewer with respect to the geometry in 3D space.

=item B<orientation>

This is a Math::Quaternion representing the orientation of the geometry.

=item B<translatescale>,B<zoomscale>

These control translation and zooming speeds.

=back

=head1 METHODS

=cut

=over 1

=item B<new>

 my $v = new OpenGL::Simple::Viewer; # Should Just Work.

 my $v2 = new OpenGL::Simple::Viewer(
        title => 'Shiny window',        # Set window title
        nearclip => 0.1,                # Near clipping plane
        translatescale => 0.01,         # Mouse translation speed
        zoomscale => 0.02,              # Mouse zoom speed
        screenx => 256,                 # Initial window dimensions
        screeny => 256,
        sphererad => 256*0.5,           # Virtual trackball size
        displaymode => GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH,
                                        # Window display mode

        initialize_gl => sub {
                glClearColor(0,0,1,1);  # Blue background
        },

        draw_background => sub {
                # Clear the window before drawing geometry
                glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
        },

        # Draw a teapot.
        draw_geometry => sub { glutSolidTeapot(1.0); },

 );

This method opens up a new GLUT window with some useful event callbacks
set, and returns an OpenGL::Simple::Viewer object to represent it.
glutInit() should have been called beforehand, to set up the GLUT
library.

new() takes either a hash or a reference to a hash of arguments, which
can include:

=over 2

=item B<title>

Sets the title of the window.

=item B<nearclip>

Sets the distance of the near clipping plane. Anything closer
to the viewer than this will not be displayed.

=item B<translatescale>

Sets the scale of mouse translation; the larger the scale, the faster
the geometry will move for a given mouse motion.

=item B<zoomscale>

Sets the scale of mouse zooming; the larger the scale, the faster
the geometry will move for a given mouse motion.

=item B<screenx>,B<screeny>

Sets the initial size of the window.

=item B<sphererad>

Sets the radius of the virtual trackball sphere.

=item B<displaymode>

Initial arguments to glutInitDisplayMode.

=item B<initialize_gl>

This is a subroutine which is called once the window has been created,
to set up initial GL state such as lighting, texture environment,
background colour, etc. By default it sets a black background and a
white light. If this argument is set to undef, then no GL state will be
changed.

=item B<draw_geometry>

Every time the viewer moves around, the geometry must be redrawn in its
new position. This argument is a coderef which is called to redraw the
geometry; you can put any GL calls you like in here.

=item B<draw_background>

When a redraw event occurs, this routine is called first, before the
viewer is oriented or the geometry drawn. It can be used to draw a
background image.

=back

=cut

sub new {
        my $class = shift;

        my %arg = (0==$#_) ? %{$#_} : @_; # Take a hash or hashref of args.

        my $self = {
                orientation => new Math::Quaternion,
                position => [0,0,-5],
                nearclip => 0.1,
                translatescale => 0.01,
                zoomscale  =>0.02,
                screenx => 256,
                screeny => 256,
                sphererad => 256*0.5,   # Radius of trackball sphere
                displaymode => GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH,

                draw_background => sub {
                        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
                },
                draw_geometry => sub { 1; }, # Do nothing by default

                # The following are really default arguments, rather
                # than properties which can be usefully modified later.
                
                title => 'OpenGL::Simple::Viewer',
                initialize_gl => sub {
                        my @LightAmbient = ( 0.1,0.1,0.1,1.0);
                        my @LightDiffuse = ( 0.5, 0.5, 0.5, 1.0);
                        my @LightSpecular = ( 0.1, 0.1, 0.1, 0.1);
                        my @LightPos = ( 0, 0, 2, 1.0);
                        glShadeModel(GL_SMOOTH);

                        glLight(GL_LIGHT1,GL_AMBIENT,@LightAmbient);
                        glLight(GL_LIGHT1,GL_DIFFUSE,@LightDiffuse);
                        glLight(GL_LIGHT1,GL_SPECULAR,@LightSpecular);
                        glLight(GL_LIGHT1,GL_POSITION,@LightPos);
                        glEnable(GL_LIGHT1);
                        glEnable(GL_LIGHTING);
                        glEnable(GL_DEPTH_TEST);

                        glColorMaterial(GL_FRONT,GL_AMBIENT_AND_DIFFUSE);
                        glEnable(GL_COLOR_MATERIAL);
                        
                        glClearColor(0,0,0,1);
                },

                # The following are internal state variables.

                _buttonstate => {	GLUT_LEFT_BUTTON,0,
                                        GLUT_MIDDLE_BUTTON,0,
                                        GLUT_RIGHT_BUTTON,0 },
                                # Current button state
                _lastclick => [0,0], # Coordinates of last mouse click


        };


        $self={%$self,%arg}; # Override defaults
        bless $self,$class;

        glutInitWindowSize(@$self{qw(screenx screeny)});
        glutInitDisplayMode($self->{'displaymode'});

        $self->{'window'} = glutCreateWindow($self->{'title'});
        
        # Create a list of slave viewer objects which change when the mouse
        # is dragged in this viewer's window.
        #
        # Actually, use a hash instead of a list so it's easy to ungang
        # a specific slave.
        #
        # A viewer is its own slave by default.
 
        $self->{'slaves'} = { $self->{'window'} => $self };

        if (defined($self->{'initialize_gl'})) { $self->{'initialize_gl'}->(); }

        glutDisplayFunc($self->make_displayfunc);
        glutReshapeFunc($self->make_reshapefunc);
        glutMouseFunc($self->make_mousefunc);
        glutMotionFunc($self->make_motionfunc);

        return $self;
        
}

=item B<make_reshapefunc>

This method returns a callback subroutine which can be passed to
glutReshapeFunc, and which sets the OpenGL::Viewer::Simple state after a
window is resized. You are free to set your own reshape callback by
calling glutReshapeFunc(); if you ever want the old one back, then simply

 glutReshapeFunc($viewer->make_reshapefunc);

=cut

sub make_reshapefunc {
        my $self = shift;
        return sub {
                my ($w,$h) = @_;

                $self->{'screenx'} = $w; $self->{'screeny'} = $h;
                $self->{'sphererad'} = 0.5*$w;
                glViewport(0,0,$w,$h);
        }
}

=item B<make_displayfunc>

Similarly to make_reshapefunc(), this returns the default display
callback subroutine.

=cut

sub make_displayfunc {
        my $self = shift;
        return sub {
                # Draw background if required.
                if (defined($self->{'draw_background'})) {
                        $self->{'draw_background'}->();
                }
                # Set up perspective projection
                glMatrixMode(GL_PROJECTION);
                glLoadIdentity();
                gluPerspective(45.0,1.0,0.1,100.0);
                glMatrixMode(GL_MODELVIEW);
                glLoadIdentity();

                # Position and orient geometry 

                glTranslate(@{$self->{'position'}});
                glMultMatrix($self->{'orientation'}->matrix4x4);

                $self->{'draw_geometry'}->();

                # Make sure it hits the screen.
                glFlush();
                glutSwapBuffers();
        };
}

=item B<make_mousefunc>

Similarly to make_reshapefunc(), this returns the default mouse click
callback subroutine.

=cut


sub make_mousefunc {
        my $self = shift;
        return sub {
                my ($button,$state,$x,$y) = @_;

                $self->{'_lastclick'} = [$x,$y];
                $self->{'_buttonstate'}->{$button} 
                        = (GLUT_DOWN == $state) ? 1 : 0;
        };
}

=item B<make_motionfunc>

Similarly to make_reshapefunc(), this returns the default mouse motion
callback subroutine.

=cut

sub make_motionfunc {
        my $self = shift;
        return sub {
                my ($x,$y) = @_;
                my %buttonstate = %{$self->{'_buttonstate'}};
                my ($left,$mid,$right) =
                 @buttonstate{GLUT_LEFT_BUTTON,
                              GLUT_MIDDLE_BUTTON,
                              GLUT_RIGHT_BUTTON};
                my ($clickx,$clicky)=@{$self->{'_lastclick'}};

                # Invoke the appropriate motion method on each
                # Viewer object which has registered to receive
                # control from this one.
 
                # Save current window (although it ought to be $self->{window})
 
                my $prevwin = glutGetWindow;

                if ($left) { 
                        while (my ($w,$v) = each %{$self->{'slaves'}}) {
                                glutSetWindow($w);
                                $v->mouserotatemotion($clickx,$clicky,$x,$y);
                        }
                } elsif ($mid) {
                        while (my ($w,$v) = each %{$self->{'slaves'}}) {
                                glutSetWindow($w);
                                $v->mousetransmotion($clickx,$clicky,$x,$y);
                        }
                } elsif ($right) {
                        while (my ($w,$v) = each %{$self->{'slaves'}}) {
                                glutSetWindow($w);
                                $v->mousezoommotion($y-$clicky);
                        }
                }
                $self->{'_lastclick'} = [$x,$y];

                glutSetWindow($prevwin); # Restore window

        };

}

=item B<mouserotatemotion> ($x0,$y0,$x1,$y1)

This method takes four arguments, corresponding to a motion from
($x0,$y0) to ($x1,$y1). It interprets the motion as the user dragging on
a virtual trackball sitting on the window, and rotates the geometry
accordingly. The radius of the trackball is set through the B<sphererad>
property.


=cut


sub mouserotatemotion {
        my $self = shift;
	my ($x0,$y0,$x1,$y1) = @_;

	my $s = $self->{'sphererad'};
	my $my = $x1-$x0;
	my $mx = $y1-$y0;
	my $m=sqrt($mx*$mx+$my*$my);

	my $theta;

	if (($m>0) && ($m<$s)) {
		$theta = $m/$s;

		$mx /= $m;
		$my /= $m;

		my $rotquat = Math::Quaternion::rotation($theta,$mx,$my,0.0);
		$self->{'orientation'} = $rotquat * $self->{'orientation'};
	}

	glutPostRedisplay();
}

=item B<mousetransmotion> ($x0,$y0,$x1,$y1) 

This method takes the coordinates of a mouse drag event, and interprets
it as a translation. The magnitude of the translation can be set through
the B<translatescale> property.

=cut

sub mousetransmotion {
        my $self = shift;
	my ($x0,$y0,$x1,$y1) = @_;

        my ($oldx,$oldy,$oldz) = @{$self->{'position'}};
        $self->{'position'} = [
                                $oldx + $self->{'translatescale'}*($x1-$x0),
                                $oldy + $self->{'translatescale'}*($y0-$y1),
                                $oldz
                              ];

	glutPostRedisplay();
}

=item B<mousetransmotion> ($dz) 

This method takes a single argument representing the length of a mouse
drag event, and zooms the geometry accordingly, controlled by the
B<zoomscale> property.

=cut

sub mousezoommotion {
        my $self = shift;
	my $dz = shift;
        $self->{'position'}->[2] -= $self->{'zoomscale'}*$dz;
	glutPostRedisplay();
}

=item B<enslave>

This method takes a list of OpenGL::Simple::Viewer objects, and sets
them all to receive motion events from the object on which the method is
invoked. If you have two viewers, $v1 and $v2, then

 $v1->enslave($v2);

means that dragging the mouse around in viewer $v1 will cause both $v1
and $v2 to move; however, mouse-dragging in viewer $v2 will only
cause it to move, and not $v1.

=cut

sub enslave {
        my $self = shift;

        for my $slave (@_) {
                $self->{'slaves'}->{$slave->{'window'}} = $slave;
        }
}

=item B<decouple>

This method takes a list of Viewer objects, and decouples their motion
from that of the object on which it was invoked.

 $v1->decouple($v2,$v3);

is the inverse of
 
 $v1->enslave($v2,$v3);

=cut

sub decouple {
        my $self = shift;

        for my $slave(@_) {
                delete $self->{'slaves'}->{$slave->{'window'}};
        }
}

=item B<gang_together>

This method takes a list of OpenGL::Simple::Viewer objects, and couples
together their motion, so that mouse dragging in any of them will cause
all of them to move.

 $v1->gang_together($v2,$v3);

is the same as

 OpenGL::Simple::Viewer::gang_together($v1,$v2,$v3)

and will couple the motion of $v1,$v2, and $v3.

=cut

sub gang_together {
        my @viewers = @_;

        for my $master (@viewers) {
                $master->enslave(@viewers);
        }
}


=back

=head1 SEE ALSO

OpenGL::Simple, OpenGL::Simple::GLUT

=head1 AUTHOR

Jonathan Chin, E<lt>jon-opengl-simple-viewer@earth.liE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jonathan Chin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

__END__
