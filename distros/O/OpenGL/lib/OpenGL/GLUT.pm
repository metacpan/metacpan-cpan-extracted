package OpenGL::GLUT;

use strict;
use warnings;

use Exporter 'import';
require DynaLoader;

our $VERSION = '0.7202';
our @ISA = qw(DynaLoader);

our @const = qw(
   GLUT_ACCUM
   GLUT_ACTION_CONTINUE_EXECUTION
   GLUT_ACTION_EXIT
   GLUT_ACTION_GLUTMAINLOOP_RETURNS
   GLUT_ACTION_ON_WINDOW_CLOSE
   GLUT_ACTIVE_ALT
   GLUT_ACTIVE_CTRL
   GLUT_ACTIVE_SHIFT
   GLUT_ALPHA
   GLUT_API_VERSION
   GLUT_BITMAP_8_BY_13
   GLUT_BITMAP_9_BY_15
   GLUT_BITMAP_HELVETICA_10
   GLUT_BITMAP_HELVETICA_12
   GLUT_BITMAP_HELVETICA_18
   GLUT_BITMAP_TIMES_ROMAN_10
   GLUT_BITMAP_TIMES_ROMAN_24
   GLUT_BLUE
   GLUT_CURSOR_BOTTOM_LEFT_CORNER
   GLUT_CURSOR_BOTTOM_RIGHT_CORNER
   GLUT_CURSOR_BOTTOM_SIDE
   GLUT_CURSOR_CROSSHAIR
   GLUT_CURSOR_CYCLE
   GLUT_CURSOR_DESTROY
   GLUT_CURSOR_FULL_CROSSHAIR
   GLUT_CURSOR_HELP
   GLUT_CURSOR_INFO
   GLUT_CURSOR_INHERIT
   GLUT_CURSOR_LEFT_ARROW
   GLUT_CURSOR_LEFT_RIGHT
   GLUT_CURSOR_LEFT_SIDE
   GLUT_CURSOR_NONE
   GLUT_CURSOR_RIGHT_ARROW
   GLUT_CURSOR_RIGHT_SIDE
   GLUT_CURSOR_SPRAY
   GLUT_CURSOR_TEXT
   GLUT_CURSOR_TOP_LEFT_CORNER
   GLUT_CURSOR_TOP_RIGHT_CORNER
   GLUT_CURSOR_TOP_SIDE
   GLUT_CURSOR_UP_DOWN
   GLUT_CURSOR_WAIT
   GLUT_DEPTH
   GLUT_DISPLAY_MODE_POSSIBLE
   GLUT_DOUBLE
   GLUT_DOWN
   GLUT_ELAPSED_TIME
   GLUT_ENTERED
   GLUT_FULLY_COVERED
   GLUT_FULLY_RETAINED
   GLUT_GAME_MODE_ACTIVE
   GLUT_GAME_MODE_DISPLAY_CHANGED
   GLUT_GAME_MODE_HEIGHT
   GLUT_GAME_MODE_PIXEL_DEPTH
   GLUT_GAME_MODE_POSSIBLE
   GLUT_GAME_MODE_REFRESH_RATE
   GLUT_GAME_MODE_WIDTH
   GLUT_GREEN
   GLUT_HAS_DIAL_AND_BUTTON_BOX
   GLUT_HAS_KEYBOARD
   GLUT_HAS_MOUSE
   GLUT_HAS_OVERLAY
   GLUT_HAS_SPACEBALL
   GLUT_HAS_TABLET
   GLUT_HIDDEN
   GLUT_INDEX
   GLUT_INIT_DISPLAY_MODE
   GLUT_INIT_STATE
   GLUT_INIT_WINDOW_HEIGHT
   GLUT_INIT_WINDOW_WIDTH
   GLUT_INIT_WINDOW_X
   GLUT_INIT_WINDOW_Y
   GLUT_KEY_DOWN
   GLUT_KEY_END
   GLUT_KEY_F1
   GLUT_KEY_F10
   GLUT_KEY_F11
   GLUT_KEY_F12
   GLUT_KEY_F2
   GLUT_KEY_F3
   GLUT_KEY_F4
   GLUT_KEY_F5
   GLUT_KEY_F6
   GLUT_KEY_F7
   GLUT_KEY_F8
   GLUT_KEY_F9
   GLUT_KEY_HOME
   GLUT_KEY_INSERT
   GLUT_KEY_LEFT
   GLUT_KEY_PAGE_DOWN
   GLUT_KEY_PAGE_UP
   GLUT_KEY_RIGHT
   GLUT_KEY_UP
   GLUT_LAYER_IN_USE
   GLUT_LEFT
   GLUT_LEFT_BUTTON
   GLUT_LUMINANCE
   GLUT_MENU_IN_USE
   GLUT_MENU_NOT_IN_USE
   GLUT_MENU_NUM_ITEMS
   GLUT_MIDDLE_BUTTON
   GLUT_MULTISAMPLE
   GLUT_NORMAL
   GLUT_NORMAL_DAMAGED
   GLUT_NOT_VISIBLE
   GLUT_NUM_BUTTON_BOX_BUTTONS
   GLUT_NUM_DIALS
   GLUT_NUM_MOUSE_BUTTONS
   GLUT_NUM_SPACEBALL_BUTTONS
   GLUT_NUM_TABLET_BUTTONS
   GLUT_OVERLAY
   GLUT_OVERLAY_DAMAGED
   GLUT_OVERLAY_POSSIBLE
   GLUT_PARTIALLY_RETAINED
   GLUT_RED
   GLUT_RGB
   GLUT_RGBA
   GLUT_RIGHT_BUTTON
   GLUT_SCREEN_HEIGHT
   GLUT_SCREEN_HEIGHT_MM
   GLUT_SCREEN_WIDTH
   GLUT_SCREEN_WIDTH_MM
   GLUT_SINGLE
   GLUT_STENCIL
   GLUT_STEREO
   GLUT_STROKE_MONO_ROMAN
   GLUT_STROKE_ROMAN
   GLUT_TRANSPARENT_INDEX
   GLUT_UP
   GLUT_VERSION
   GLUT_VISIBLE
   GLUT_WINDOW_ACCUM_ALPHA_SIZE
   GLUT_WINDOW_ACCUM_BLUE_SIZE
   GLUT_WINDOW_ACCUM_GREEN_SIZE
   GLUT_WINDOW_ACCUM_RED_SIZE
   GLUT_WINDOW_ALPHA_SIZE
   GLUT_WINDOW_BLUE_SIZE
   GLUT_WINDOW_BUFFER_SIZE
   GLUT_WINDOW_COLORMAP_SIZE
   GLUT_WINDOW_CURSOR
   GLUT_WINDOW_DEPTH_SIZE
   GLUT_WINDOW_DOUBLEBUFFER
   GLUT_WINDOW_FORMAT_ID
   GLUT_WINDOW_GREEN_SIZE
   GLUT_WINDOW_HEIGHT
   GLUT_WINDOW_NUM_CHILDREN
   GLUT_WINDOW_NUM_SAMPLES
   GLUT_WINDOW_PARENT
   GLUT_WINDOW_RED_SIZE
   GLUT_WINDOW_RGBA
   GLUT_WINDOW_STENCIL_SIZE
   GLUT_WINDOW_STEREO
   GLUT_WINDOW_WIDTH
   GLUT_WINDOW_X
   GLUT_WINDOW_Y
   GLUT_XLIB_IMPLEMENTATION
);

our @func = qw(
   done_glutInit
   glutAddMenuEntry
   glutAddSubMenu
   glutAttachMenu
   glutBitmapCharacter
   glutBitmapHeight
   glutBitmapLength
   glutBitmapString
   glutBitmapWidth
   glutButtonBoxFunc
   glutChangeToMenuEntry
   glutChangeToSubMenu
   glutCloseFunc
   glutCopyColormap
   glutCreateMenu
   glutCreateSubWindow
   glutCreateWindow
   glutDestroyMenu
   glutDestroyWindow
   glutDetachMenu
   glutDeviceGet
   glutDialsFunc
   glutDisplayFunc
   glutEnterGameMode
   glutEntryFunc
   glutEstablishOverlay
   glutExtensionSupported
   glutForceJoystickFunc
   glutFullScreen
   glutGameModeGet
   glutGameModeString
   glutGet
   glutGetColor
   glutGetMenu
   glutGetModifiers
   glutGetWindow
   glutHideOverlay
   glutHideWindow
   glutIconifyWindow
   glutIdleFunc
   glutIgnoreKeyRepeat
   glutInit
   glutInitDisplayMode
   glutInitDisplayString
   glutInitWindowPosition
   glutInitWindowSize
   glutKeyboardFunc
   glutKeyboardUpFunc
   glutLayerGet
   glutLeaveGameMode
   glutLeaveMainLoop
   glutMainLoop
   glutMainLoopEvent
   glutMenuDestroyFunc
   glutMenuStateFunc
   glutMenuStatusFunc
   glutMotionFunc
   glutMouseFunc
   glutMouseWheelFunc
   glutOverlayDisplayFunc
   glutPassiveMotionFunc
   glutPopWindow
   glutPositionWindow
   glutPostOverlayRedisplay
   glutPostRedisplay
   glutPostWindowOverlayRedisplay
   glutPostWindowRedisplay
   glutPushWindow
   glutRemoveMenuItem
   glutRemoveOverlay
   glutReportErrors
   glutReshapeFunc
   glutReshapeWindow
   glutSetColor
   glutSetCursor
   glutSetIconTitle
   glutSetKeyRepeat
   glutSetMenu
   glutSetOption
   glutSetWindow
   glutSetWindowTitle
   glutShowOverlay
   glutShowWindow
   glutSolidCone
   glutSolidCube
   glutSolidCylinder
   glutSolidDodecahedron
   glutSolidIcosahedron
   glutSolidOctahedron
   glutSolidRhombicDodecahedron
   glutSolidSphere
   glutSolidTeapot
   glutSolidTetrahedron
   glutSolidTorus
   glutSpaceballButtonFunc
   glutSpaceballMotionFunc
   glutSpaceballRotateFunc
   glutSpecialFunc
   glutSpecialUpFunc
   glutStrokeCharacter
   glutStrokeHeight
   glutStrokeLength
   glutStrokeString
   glutStrokeWidth
   glutSwapBuffers
   glutTabletButtonFunc
   glutTabletMotionFunc
   glutTimerFunc
   glutUseLayer
   glutVisibilityFunc
   glutWarpPointer
   glutWindowStatusFunc
   glutWireCone
   glutWireCube
   glutWireCylinder
   glutWireDodecahedron
   glutWireIcosahedron
   glutWireOctahedron
   glutWireRhombicDodecahedron
   glutWireSphere
   glutWireTeapot
   glutWireTetrahedron
   glutWireTorus
);

our @EXPORT_OK = (@const, @func, qw(_have_glut _have_freeglut glpHasGLUT));
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
  constants => \@const,
  glutconstants => \@const,
  functions => \@func,
  glutfunctions => \@func,
);

__PACKAGE__->bootstrap;

1;

__END__

=head1 NAME

OpenGL::GLUT - Perl bindings to GLUT/FreeGLUT GUI toolkit

=head1 SYNOPSIS

  use OpenGL::GLUT qw(:all); # now can use GLUT calls

=head1 DESCRIPTION

OpenGL::GLUT is, as of 0.7202, back as part of the main L<OpenGL>
distribution, but now it works separately.
The purpose is to make this functionality
available independent of the legacy OpenGL module for use with
L<OpenGL::Modern>.

When you register a C<glutCloseFunc>, ensure that you de-register it
before destroying the window. See the supplied F<test.pl>.

=head2 EXPORT

  :all - exports all GLUT functions and constants
  :constants - export only GLUT constants (same as :glutconstants)
  :functions - export only GLUT functions (same as :glutfunctions)

=head2 Exportable functions

  void glutAddMenuEntry( const char* label, int value )
  void glutAddSubMenu( const char* label, int subMenu )
  void glutAttachMenu( int button )
  void glutBitmapCharacter( void* font, int character )
  int glutBitmapLength( void* font, const unsigned char* string )
  int glutBitmapWidth( void* font, int character )
  void glutButtonBoxFunc( void (* callback)( int, int ) )
  void glutChangeToMenuEntry( int item, const char* label, int value )
  void glutChangeToSubMenu( int item, const char* label, int value )
  void glutCloseFunc( void (* callback)( void ) )
  void glutCopyColormap( int window )
  int glutCreateMenu( void (* callback)( int menu ) )
  int glutCreateSubWindow( int window, int x, int y, int width, int height )
  int glutCreateWindow( const char* title )
  void glutDestroyMenu( int menu )
  void glutDestroyWindow( int window )
  void glutDetachMenu( int button )
  int glutDeviceGet( GLenum query )
  void glutDialsFunc( void (* callback)( int, int ) )
  void glutDisplayFunc( void (* callback)( void ) )
  int glutEnterGameMode( void )
  void glutEntryFunc( void (* callback)( int ) )
  void glutEstablishOverlay( void )
  int glutExtensionSupported( const char* extension )
  void glutForceJoystickFunc( void )
  void glutFullScreen( void )
  int glutGameModeGet( GLenum query )
  void glutGameModeString( const char* string )
  int glutGet( GLenum query )
  GLfloat glutGetColor( int color, int component )
  int glutGetMenu( void )
  int glutGetModifiers( void )
  int glutGetWindow( void )
  void glutHideOverlay( void )
  void glutHideWindow( void )
  void glutIconifyWindow( void )
  void glutIdleFunc( void (* callback)( void ) )
  void glutIgnoreKeyRepeat( int ignore )
  void glutInit( int* pargc, char** argv )
  void glutInitDisplayMode( unsigned int displayMode )
  void glutInitDisplayString( const char* displayMode )
  void glutInitWindowPosition( int x, int y )
  void glutInitWindowSize( int width, int height )
  void glutKeyboardFunc( void (* callback)( unsigned char, int, int ) )
  void glutKeyboardUpFunc( void (* callback)( unsigned char, int, int ) )
  int glutLayerGet( GLenum query )
  void glutLeaveGameMode( void )
  void glutMainLoop( void )
  void glutMenuStateFunc( void (* callback)( int ) )
  void glutMenuStatusFunc( void (* callback)( int, int, int ) )
  void glutMotionFunc( void (* callback)( int, int ) )
  void glutMouseFunc( void (* callback)( int, int, int, int ) )
  void glutOverlayDisplayFunc( void (* callback)( void ) )
  void glutPassiveMotionFunc( void (* callback)( int, int ) )
  void glutPopWindow( void )
  void glutPositionWindow( int x, int y )
  void glutPostOverlayRedisplay( void )
  void glutPostRedisplay( void )
  void glutPostWindowOverlayRedisplay( int window )
  void glutPostWindowRedisplay( int window )
  void glutPushWindow( void )
  void glutRemoveMenuItem( int item )
  void glutRemoveOverlay( void )
  void glutReportErrors( void )
  void glutReshapeFunc( void (* callback)( int, int ) )
  void glutReshapeWindow( int width, int height )
  void glutSetColor( int color, GLfloat red, GLfloat green, GLfloat blue )
  void glutSetCursor( int cursor )
  void glutSetIconTitle( const char* title )
  void glutSetKeyRepeat( int repeatMode )
  void glutSetMenu( int menu )
  void glutSetWindow( int window )
  void glutSetWindowTitle( const char* title )
  void glutSetupVideoResizing( void )
  void glutShowOverlay( void )
  void glutShowWindow( void )
  void glutSolidCone( GLdouble base, GLdouble height, GLint slices, GLint stacks )
  void glutSolidCube( GLdouble size )
  void glutSolidDodecahedron( void )
  void glutSolidIcosahedron( void )
  void glutSolidOctahedron( void )
  void glutSolidSphere( GLdouble radius, GLint slices, GLint stacks )
  void glutSolidTeapot( GLdouble size )
  void glutSolidTetrahedron( void )
  void glutSolidTorus( GLdouble innerRadius, GLdouble outerRadius, GLint sides, GLint rings )
  void glutSpaceballButtonFunc( void (* callback)( int, int ) )
  void glutSpaceballMotionFunc( void (* callback)( int, int, int ) )
  void glutSpaceballRotateFunc( void (* callback)( int, int, int ) )
  void glutSpecialFunc( void (* callback)( int, int, int ) )
  void glutSpecialUpFunc( void (* callback)( int, int, int ) )
  void glutStopVideoResizing( void )
  void glutStrokeCharacter( void* font, int character )
  int glutStrokeLength( void* font, const unsigned char* string )
  int glutStrokeWidth( void* font, int character )
  void glutSwapBuffers( void )
  void glutTabletButtonFunc( void (* callback)( int, int, int, int ) )
  void glutTabletMotionFunc( void (* callback)( int, int ) )
  void glutTimerFunc( unsigned int time, void (* callback)( int ), int value )
  void glutUseLayer( GLenum layer )
  void glutVideoPan( int x, int y, int width, int height )
  void glutVideoResize( int x, int y, int width, int height )
  int glutVideoResizeGet( GLenum query )
  void glutVisibilityFunc( void (* callback)( int ) )
  void glutWarpPointer( int x, int y )
  void glutWindowStatusFunc( void (* callback)( int ) )
  void glutWireCone( GLdouble base, GLdouble height, GLint slices, GLint stacks )
  void glutWireCube( GLdouble size )
  void glutWireDodecahedron( void )
  void glutWireIcosahedron( void )
  void glutWireOctahedron( void )
  void glutWireSphere( GLdouble radius, GLint slices, GLint stacks )
  void glutWireTeapot( GLdouble size )
  void glutWireTetrahedron( void )
  void glutWireTorus( GLdouble innerRadius, GLdouble outerRadius, GLint sides, GLint rings )

=head1 SEE ALSO

L<OpenGL>

=head1 AUTHOR

Chris Marshall E<lt>chm AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Chris Marshall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
