package OpenGL::Simple::GLUT;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::Simple::GLUT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

glutInit
glutInitWindowSize
glutInitWindowPosition
glutInitDisplayMode

glutMainLoop

glutCreateWindow
glutCreateSubWindow
glutSetWindow
glutGetWindow
glutDestroyWindow
glutPostRedisplay
glutSwapBuffers
glutPositionWindow
glutReshapeWindow
glutFullScreen
glutPopWindow
glutPushWindow
glutShowWindow
glutHideWindow
glutIconifyWindow
glutSetWindowTitle
glutSetIconTitle
glutSetCursor

glutEstablishOverlay
glutUseLayer
glutRemoveOverlay
glutPostOverlayRedisplay
glutShowOverlay
glutHideOverlay

glutCreateMenu
glutSetMenu
glutGetMenu
glutDestroyMenu
glutAddMenuEntry
glutAddSubMenu
glutChangeToMenuEntry
glutChangeToSubMenu
glutRemoveMenuItem
glutAttachMenu
glutDetachMenu

glutDisplayFunc
glutOverlayDisplayFunc
glutReshapeFunc
glutKeyboardFunc
glutMouseFunc
glutMotionFunc
glutPassiveMotionFunc
glutVisibilityFunc
glutEntryFunc
glutSpecialFunc
glutSpaceballMotionFunc
glutSpaceballRotateFunc
glutSpaceballButtonFunc
glutButtonBoxFunc
glutDialsFunc
glutTabletMotionFunc
glutTabletButtonFunc
glutMenuStatusFunc
glutMenuStateFunc
glutIdleFunc
glutTimerFunc

glutSetColor
glutGetColor
glutCopyColormap

glutGet
glutLayerGet
glutDeviceGet
glutGetModifiers
glutExtensionSupported

glutSolidSphere glutWireSphere
glutSolidTorus glutWireTorus
glutSolidCone glutWireCone
glutSolidTetrahedron glutWireTetrahedron
glutSolidCube glutWireCube
glutSolidOctahedron glutWireOctahedron
glutSolidDodecahedron glutWireDodecahedron
glutSolidIcosahedron glutWireIcosahedron
glutSolidTeapot glutWireTeapot

GLUT_RGBA GLUT_RGB GLUT_INDEX 
GLUT_SINGLE GLUT_DOUBLE
GLUT_ACCUM GLUT_ALPHA GLUT_DEPTH GLUT_STENCIL
GLUT_MULTISAMPLE GLUT_STEREO GLUT_LUMINANCE

GLUT_CURSOR_RIGHT_ARROW
GLUT_CURSOR_LEFT_ARROW
GLUT_CURSOR_INFO
GLUT_CURSOR_DESTROY
GLUT_CURSOR_HELP
GLUT_CURSOR_CYCLE
GLUT_CURSOR_SPRAY
GLUT_CURSOR_WAIT
GLUT_CURSOR_TEXT
GLUT_CURSOR_CROSSHAIR
GLUT_CURSOR_UP_DOWN
GLUT_CURSOR_LEFT_RIGHT
GLUT_CURSOR_TOP_SIDE
GLUT_CURSOR_BOTTOM_SIDE
GLUT_CURSOR_LEFT_SIDE
GLUT_CURSOR_RIGHT_SIDE
GLUT_CURSOR_TOP_LEFT_CORNER
GLUT_CURSOR_TOP_RIGHT_CORNER
GLUT_CURSOR_BOTTOM_RIGHT_CORNER
GLUT_CURSOR_BOTTOM_LEFT_CORNER
GLUT_CURSOR_FULL_CROSSHAIR
GLUT_CURSOR_NONE
GLUT_CURSOR_INHERIT

GLUT_NORMAL GLUT_OVERLAY

		GLUT_WINDOW_X GLUT_WINDOW_Y
		GLUT_WINDOW_WIDTH GLUT_WINDOW_HEIGHT
		GLUT_WINDOW_BUFFER_SIZE
		GLUT_WINDOW_STENCIL_SIZE
		GLUT_WINDOW_DEPTH_SIZE
		GLUT_WINDOW_RED_SIZE GLUT_WINDOW_GREEN_SIZE
		GLUT_WINDOW_BLUE_SIZE GLUT_WINDOW_ALPHA_SIZE
		GLUT_WINDOW_ACCUM_RED_SIZE
		GLUT_WINDOW_ACCUM_GREEN_SIZE
		GLUT_WINDOW_ACCUM_BLUE_SIZE
		GLUT_WINDOW_ACCUM_ALPHA_SIZE
		GLUT_WINDOW_DOUBLEBUFFER
		GLUT_WINDOW_RGBA
		GLUT_WINDOW_PARENT
		GLUT_WINDOW_NUM_CHILDREN
		GLUT_WINDOW_COLORMAP_SIZE
		GLUT_WINDOW_NUM_SAMPLES
		GLUT_WINDOW_STEREO
		GLUT_WINDOW_CURSOR
		GLUT_SCREEN_WIDTH
		GLUT_SCREEN_HEIGHT
		GLUT_SCREEN_WIDTH_MM
		GLUT_SCREEN_HEIGHT_MM
		GLUT_MENU_NUM_ITEMS
		GLUT_DISPLAY_MODE_POSSIBLE
		GLUT_INIT_DISPLAY_MODE
		GLUT_INIT_WINDOW_X GLUT_INIT_WINDOW_Y
		GLUT_INIT_WINDOW_WIDTH GLUT_INIT_WINDOW_HEIGHT
		GLUT_ELAPSED_TIME

		GLUT_OVERLAY_POSSIBLE
		GLUT_LAYER_IN_USE
		GLUT_HAS_OVERLAY
		GLUT_TRANSPARENT_INDEX
		GLUT_NORMAL_DAMAGED
		GLUT_OVERLAY_DAMAGED

		GLUT_HAS_KEYBOARD
		GLUT_HAS_MOUSE
		GLUT_HAS_SPACEBALL
		GLUT_HAS_DIAL_AND_BUTTON_BOX
		GLUT_HAS_TABLET
		GLUT_NUM_MOUSE_BUTTONS
		GLUT_NUM_SPACEBALL_BUTTONS
		GLUT_NUM_BUTTON_BOX_BUTTONS
		GLUT_NUM_DIALS
		GLUT_NUM_TABLET_BUTTONS

		GLUT_ACTIVE_SHIFT
		GLUT_ACTIVE_CTRL
		GLUT_ACTIVE_ALT

		GLUT_LEFT_BUTTON GLUT_MIDDLE_BUTTON GLUT_RIGHT_BUTTON

		GLUT_KEY_F1 GLUT_KEY_F2 GLUT_KEY_F3
		GLUT_KEY_F4 GLUT_KEY_F5 GLUT_KEY_F6
		GLUT_KEY_F7 GLUT_KEY_F8 GLUT_KEY_F9
		GLUT_KEY_F10 GLUT_KEY_F11 GLUT_KEY_F12
		GLUT_KEY_LEFT GLUT_KEY_UP GLUT_KEY_RIGHT GLUT_KEY_DOWN
		GLUT_KEY_PAGE_UP GLUT_KEY_PAGE_DOWN 
		GLUT_KEY_HOME GLUT_KEY_END GLUT_KEY_INSERT

		GLUT_UP GLUT_DOWN
		GLUT_LEFT GLUT_ENTERED

                GLUT_MENU_NOT_IN_USE GLUT_MENU_IN_USE 

                GLUT_NOT_VISIBLE GLUT_VISIBLE 

                GLUT_HIDDEN GLUT_FULLY_RETAINED 
                GLUT_PARTIALLY_RETAINED GLUT_FULLY_COVERED 

                GLUT_RED GLUT_GREEN GLUT_BLUE 

                GLUT_STROKE_ROMAN GLUT_STROKE_MONO_ROMAN
                GLUT_BITMAP_9_BY_15 GLUT_BITMAP_8_BY_13
                GLUT_BITMAP_TIMES_ROMAN_10 GLUT_BITMAP_TIMES_ROMAN_24
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.03';

#
# Stolen from output of h2xs

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&OpenGL::Simple::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('OpenGL::Simple::GLUT', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

OpenGL::Simple::GLUT - Another interface to GLUT

=head1 SYNOPSIS

  use OpenGL::Simple qw(:all);
  use OpenGL::Simple::GLUT qw(:all);

  # ...

  glutSolidTeapot(1);


=head1 DESCRIPTION

This module provides an interface to the GLUT OpenGL toolkit library; it 
binds the GLUT functions and constants to Perl subroutines with a 
polymorphic interface. 

=head1 SEE ALSO

L<OpenGL::Simple>

=head1 AUTHOR

Jonathan Chin, E<lt>jon-opengl-simple-glut@earth.liE<gt> ; documentation and
sanitization by Simon Cozens.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jonathan Chin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
