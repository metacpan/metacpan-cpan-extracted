package OpenGL::GLUT;

#  Copyright (c) 1998,1999 Kenneth Albanowski. All rights reserved.
#  Copyright (c) 2007 Bob Free. All rights reserved.
#  Copyright (c) 2009 Christopher Marshall. All rights reserved.
#  Copyright (c) 2015 Bob Free. All rights reserved.
#  Copyright (c) 2016,2017 Chris Marshall. All rights reserved.
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.

use strict;
use warnings;
require Exporter;
require DynaLoader;

use Carp;

our $VERSION = '0.72';
our $XS_VERSION = $VERSION;
our @ISA = qw(Exporter DynaLoader);
our ($gl_version, $AUTOLOAD);
our $glext_installed = {};

# Implemented extensions and their dependencies
our $glext_dependencies =
{
   GL_ARB_color_buffer_float=>'2.0', #39
   GL_ARB_depth_texture=>'1.1', #22
   GL_ARB_draw_buffers=>'1.3', #37
   GL_ARB_fragment_program=>'1.4;ARB_vertex_program', #27
   GL_ARB_fragment_program_shadow=>'1.4;ARB_fragment_program,ARB_shadow', #36
   GL_ARB_fragment_shader=>'1.4;ARB_shader_objects', #32
   GL_ARB_half_float_pixel=>'1.5', #40
   GL_ARB_multisample=>'1.0', #5
   GL_ARB_multitexture=>'1.1', # Moved to 1.2.1
   GL_ARB_pixel_buffer_object=>'1.5', #42
   GL_ARB_point_parameters=>'1.0', #14
   GL_ARB_point_sprite=>'1.4', #35
   GL_ARB_shading_language_100=>'1.4;ARB_shader_objects,ARB_fragment_shader,ARB_vertex_shader', #33
   GL_ARB_shader_objects=>'1.4', #30
   GL_ARB_shadow=>'1.1;ARB_depth_texture', #23
   GL_ARB_shadow_ambient=>'1.1;ARB_shadow,ARB_depth_texture', #23
   GL_ARB_texture_border_clamp=>'1.0', #13
   GL_ARB_texture_cube_map=>'1.0', #7
   GL_ARB_texture_env_add=>'1.0', #6
   GL_ARB_texture_env_combine=>'1.1;ARB_multitexture', #17
   GL_ARB_texture_env_dot3=>'1.1;ARB_multitexture,ARB_texture_env_combine', #19
   GL_ARB_texture_float=>'1.1', #41
   GL_ARB_texture_mirrored_repeat=>'1.0', #21
   GL_ARB_texture_non_power_of_two=>'1.4', #34
   GL_ARB_texture_rectangle=>'1.1', #38
   GL_ARB_vertex_buffer_object=>'1.4', #28
   GL_ARB_vertex_program=>'1.3', #26
   GL_ARB_vertex_shader=>'1.4;ARB_shader_objects', #31
   GL_ATI_texture_float=>'1.1', #280
   GL_ATI_texture_mirror_once=>'1.0;EXT_texture3D', #221
   GL_EXT_abgr=>'1.0', #1
   GL_EXT_bgra=>'1.0', #129
   GL_EXT_blend_color=>'1.0', #2
   GL_EXT_blend_subtract=>'1.0', #38
   GL_EXT_Cg_shader=>'1.0;ARB_shader_objects', #???
   GL_EXT_copy_texture=>'1.0', #10
   GL_EXT_framebuffer_object=>'1.1', #310
   GL_EXT_packed_pixels=>'1.0', #23
   GL_EXT_pixel_buffer_object=>'1.0', #???
   GL_EXT_rescale_normal=>'1.0', #27
   GL_EXT_separate_specular_color=>'1.0', #144
   GL_EXT_shadow_funcs=>'1.1;ARB_depth_texture,ARB_shadow', #267
   GL_EXT_stencil_wrap=>'1.0', #176
   GL_EXT_subtexture=>'1.0', #9
   GL_EXT_texture=>'1.0', #4
   GL_EXT_texture3D=>'1.1;EXT_abgr', #6
   GL_EXT_texture_cube_map=>'1.0', #6
   GL_EXT_texture_env_combine=>'1.0', #158
   GL_EXT_texture_env_dot3=>'1.0;EXT_texture_env_combine', #220
   GL_EXT_texture_filter_anisotropic=>'1.0', #187
   GL_EXT_texture_lod_bias=>'1.0', #186
   GL_EXT_texture_mirror_clamp=>'1.0', #298
   GL_EXT_vertex_array=>'1.0', #30
   GL_HP_occlusion_test=>'1.0', #137
   GL_IBM_rasterpos_clip=>'1.0', #110
   GL_NV_blend_square=>'1.0', #194
   GL_NV_copy_depth_to_color=>'1.0;NV_packed_depth_stencil', #243
   GL_NV_depth_clamp=>'1.0', #260
   GL_NV_fog_distance=>'1.0', #192
   GL_NV_fragment_program_option=>'1.0;ARB_fragment_program', #303
   GL_NV_fragment_program2=>'1.0;ARB_fragment_program,NV_fragment_program_option', #304
   GL_NV_light_max_exponent=>'1.0', #189
   GL_NV_multisample_filter_hint=>'1.0;ARB_multisample', #259
   GL_NV_packed_depth_stencil=>'1.0', #226
   GL_NV_texgen_reflection=>'1.0', #179
   GL_NV_texture_compression_vtc=>'1.0;ARB_texture_compression,EXT_texture_compression_s3tc,ARB_texture_non_power_of_two', #228
   GL_NV_texture_expand_normal=>'1.1', #286
   GL_NV_texture_rectangle=>'1.0', #229
   GL_NV_texture_shader=>'1.0;ARB_multitexture,ARB_texture_cube_map', #230
   GL_NV_texture_shader2=>'1.0;NV_texture_shader', #231
   GL_NV_texture_shader3=>'1.0;NV_texture_shader2', #265
   GL_NV_vertex_program1_1=>'1.0;NV_vertex_program', #266
   GL_NV_vertex_program2=>'1.0;NV_vertex_program', #287
   GL_NV_vertex_program2_option=>'1.0;ARB_vertex_program', #305
   GL_NV_vertex_program3=>'1.0;ARB_vertex_program,NV_vertex_program2_option', #306
   GL_S3_s3tc=>'1.1', #276
   GL_SGIS_generate_mipmap=>'1.1', #32
   GL_SGIS_texture_lod=>'1.1', #24
   GL_SGIX_depth_texture=>'1.1', #63
   GL_SGIX_shadow=>'1.0', #34
   GL_SUN_slice_accum=>'1.0' #258
};

my @glut_func = qw(
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

##------------------------------------------------------------------------
## FreeGLUT not implemented yet       -chm 2009-08-31
##------------------------------------------------------------------------
##
## Need to determine desired/useful interface
## glutGetProcAddress (const char *procName)
##
## Need to add pollInterval argument to glutJoystickFunc() call
## glutJoystickFunc (void(*callback)(unsigned int buttons, int xaxis, int yaxis, int zaxis), int pollInterval)
##
##------------------------------------------------------------------------

my @glut_const = qw(
   GLUT_API_VERSION
   GLUT_XLIB_IMPLEMENTATION
   GLUT_RGB
   GLUT_RGBA
   GLUT_INDEX
   GLUT_INIT_STATE
   GLUT_VERSION
   GLUT_SINGLE
   GLUT_DOUBLE
   GLUT_ACCUM
   GLUT_ALPHA
   GLUT_DEPTH
   GLUT_STENCIL
   GLUT_MULTISAMPLE
   GLUT_STEREO
   GLUT_LUMINANCE
   GLUT_LEFT_BUTTON
   GLUT_MIDDLE_BUTTON
   GLUT_RIGHT_BUTTON
   GLUT_DOWN
   GLUT_UP
   GLUT_KEY_F1
   GLUT_KEY_F2
   GLUT_KEY_F3
   GLUT_KEY_F4
   GLUT_KEY_F5
   GLUT_KEY_F6
   GLUT_KEY_F7
   GLUT_KEY_F8
   GLUT_KEY_F9
   GLUT_KEY_F10
   GLUT_KEY_F11
   GLUT_KEY_F12
   GLUT_KEY_LEFT
   GLUT_KEY_UP
   GLUT_KEY_RIGHT
   GLUT_KEY_DOWN
   GLUT_KEY_PAGE_UP
   GLUT_KEY_PAGE_DOWN
   GLUT_KEY_HOME
   GLUT_KEY_END
   GLUT_KEY_INSERT
   GLUT_LEFT
   GLUT_ENTERED
   GLUT_MENU_NOT_IN_USE
   GLUT_MENU_IN_USE
   GLUT_NOT_VISIBLE
   GLUT_VISIBLE
   GLUT_HIDDEN
   GLUT_FULLY_RETAINED
   GLUT_PARTIALLY_RETAINED
   GLUT_FULLY_COVERED
   GLUT_RED
   GLUT_GREEN
   GLUT_BLUE
   GLUT_NORMAL
   GLUT_OVERLAY
   GLUT_STROKE_ROMAN
   GLUT_STROKE_MONO_ROMAN
   GLUT_BITMAP_9_BY_15
   GLUT_BITMAP_8_BY_13
   GLUT_BITMAP_TIMES_ROMAN_10
   GLUT_BITMAP_TIMES_ROMAN_24
   GLUT_BITMAP_HELVETICA_10
   GLUT_BITMAP_HELVETICA_12
   GLUT_BITMAP_HELVETICA_18
   GLUT_WINDOW_X
   GLUT_WINDOW_Y
   GLUT_WINDOW_WIDTH
   GLUT_WINDOW_HEIGHT
   GLUT_WINDOW_BUFFER_SIZE
   GLUT_WINDOW_STENCIL_SIZE
   GLUT_WINDOW_DEPTH_SIZE
   GLUT_WINDOW_RED_SIZE
   GLUT_WINDOW_GREEN_SIZE
   GLUT_WINDOW_BLUE_SIZE
   GLUT_WINDOW_ALPHA_SIZE
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
   GLUT_WINDOW_FORMAT_ID
   GLUT_SCREEN_WIDTH
   GLUT_SCREEN_HEIGHT
   GLUT_SCREEN_WIDTH_MM
   GLUT_SCREEN_HEIGHT_MM
   GLUT_MENU_NUM_ITEMS
   GLUT_DISPLAY_MODE_POSSIBLE
   GLUT_INIT_WINDOW_X
   GLUT_INIT_WINDOW_Y
   GLUT_INIT_WINDOW_WIDTH
   GLUT_INIT_WINDOW_HEIGHT
   GLUT_INIT_DISPLAY_MODE
   GLUT_ELAPSED_TIME
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
   GLUT_OVERLAY_POSSIBLE
   GLUT_LAYER_IN_USE
   GLUT_HAS_OVERLAY
   GLUT_TRANSPARENT_INDEX
   GLUT_NORMAL_DAMAGED
   GLUT_OVERLAY_DAMAGED
   GLUT_NORMAL
   GLUT_OVERLAY
   GLUT_ACTIVE_SHIFT
   GLUT_ACTIVE_CTRL
   GLUT_ACTIVE_ALT
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
   GLUT_CURSOR_INHERIT
   GLUT_CURSOR_NONE
   GLUT_CURSOR_FULL_CROSSHAIR
   GLUT_ACTION_EXIT
   GLUT_ACTION_GLUTMAINLOOP_RETURNS
   GLUT_ACTION_CONTINUE_EXECUTION
   GLUT_ACTION_ON_WINDOW_CLOSE
   GLUT_GAME_MODE_ACTIVE
   GLUT_GAME_MODE_POSSIBLE
   GLUT_GAME_MODE_WIDTH
   GLUT_GAME_MODE_HEIGHT
   GLUT_GAME_MODE_PIXEL_DEPTH
   GLUT_GAME_MODE_REFRESH_RATE
   GLUT_GAME_MODE_DISPLAY_CHANGED
);

our @EXPORT = ();

# Other items we are prepared to export if requested
our @EXPORT_OK = (@glut_func, @glut_const);

my @constants = (@glut_const);
my @functions = (@glut_func);

our %EXPORT_TAGS = ('constants' => \@constants, 'functions' => \@functions, 'all' => \@EXPORT_OK,
	'glutconstants' => \@glut_const, 'glutfunctions' => \@glut_func,
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    # NOTE: THIS AUTOLOAD FUNCTION IS FLAWED (but is the best we can do for now).
    # Avoid old-style ``&CONST'' usage. Either remove the ``&'' or add ``()''.
    if (@_ > 0) {
        # Is it an old OpenGL-0.4 function? If so, remap it to newer variant
        (my $constname = $AUTOLOAD) =~ s/.*:://;
        $AutoLoader::AUTOLOAD = $AUTOLOAD;
        goto &AutoLoader::AUTOLOAD;
    }
    (my $constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if (not defined $val) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    my ($pack,$file,$line) = caller;
	    die "Your vendor has not defined OpenGL macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

#require XSLoader;
#XSLoader::load('OpenGL::GLUT', $VERSION);

bootstrap OpenGL::GLUT;


1;
__END__

=head1 NAME

OpenGL::GLUT - Perl bindings to GLUT/FreeGLUT GUI toolkit 

=head1 SYNOPSIS

  use OpenGL::GLUT qw(:all); # now can use GLUT calls

=head1 DESCRIPTION

OpenGL::GLUT is the alpha release of a stand-alone module for
GLUT/FreeGLUT bindings extracted from code in the original Perl
OpenGL module.  The purpose is to make this functionality
available independent of the legacy OpenGL module for use with
OpenGL::Modern.

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

L<OpenGL> (for now)

=head1 AUTHOR

Chris Marshall E<lt>chm AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Chris Marshall
Derived from OpenGL 0.70 code.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
