package OpenGL::Simple;

use 5.006;
use strict;
use warnings;
use Carp;
use Imager;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

        glAccum glAlphaFunc glClearAccum glClearIndex glClearStencil
        glEdgeFlag glFogf glFogi glFog
        glIndexMask glInitNames glIsEnabled glLoadName
        glPushName glPopName glRenderMode
        glScissor glStencilFunc glStencilOp


	glGetString
	glBegin glEnd glEnable glDisable glFinish glFlush
	glClearColor glClear glClearDepth
        glClipPlane glGetClipPlane
	glLoadIdentity glMatrixMode glLoadMatrix glMultMatrix
	glPushMatrix glPopMatrix

        glPushAttrib glPopAttrib

	glRotate glRotatef glRotated
        glTranslate glTranslatef glTranslated
        glScale
	glRect
	glVertex glNormal
	glVertex2d glVertex2f glVertex2i glVertex2s glVertex3d
	glVertex3f glVertex3i glVertex3s glVertex4d glVertex4f glVertex4i

	glColor
        glColor3b glColor3d glColor3f glColor3i glColor3s glColor3ub
        glColor3ui glColor3us glColor4b glColor4d glColor4f glColor4i 
        glColor4s glColor4ub glColor4ui glColor4us

        glColorMaterial glMaterial

	glNewList glCallList glCallLists glEndList 
        glIsList glGenLists glDeleteLists glListBase

	glLightModel glShadeModel

	glCullFace
	
	glDepthFunc glDepthMask glDepthRange
        glColorMask
	
	glPolygonMode glPolygonOffset
	
	glViewport

	glBlendFunc

	glHint

	glLineWidth
        glLineStipple
        glPolygonStipple

	glPointSize

	glOrtho glFrustum

	glLight

	glFrontFace

	glGet

	glBindTexture glGenTextures glTexParameter glTexCoord glTexEnv
	glDeleteTextures glTexGen


	glTexImage2D
	glTexSubImage2D

	glDrawBuffer

	glTexImage3D

	glPixelStorei glPixelStoref glPixelStore

	glPixelTransferi glPixelTransferf glPixelTransfer

		GL_VENDOR GL_RENDERER GL_VERSION GL_EXTENSIONS

 		GL_POINTS GL_LINES GL_LINE_STRIP GL_LINE_LOOP
		GL_TRIANGLES GL_TRIANGLE_STRIP GL_TRIANGLE_FAN
		GL_QUADS GL_QUAD_STRIP GL_POLYGON

		GL_ALPHA_TEST GL_AUTO_NORMAL GL_BLEND GL_CLIP_PLANE0
		GL_CLIP_PLANE1 GL_CLIP_PLANE2 GL_CLIP_PLANE3 GL_CLIP_PLANE4
		GL_CLIP_PLANE5 GL_COLOR_LOGIC_OP GL_COLOR_MATERIAL GL_CULL_FACE
		GL_DEPTH_TEST GL_DITHER GL_FOG GL_INDEX_LOGIC_OP
		GL_LIGHT0 GL_LIGHT1 GL_LIGHT2 GL_LIGHT3
		GL_LIGHT4 GL_LIGHT5 GL_LIGHT6 GL_LIGHT7
		GL_LIGHTING GL_LINE_SMOOTH GL_LINE_STIPPLE GL_MAP1_COLOR_4
		GL_MAP1_INDEX GL_MAP1_NORMAL GL_MAP1_TEXTURE_COORD_1
		GL_MAP1_TEXTURE_COORD_2 GL_MAP1_TEXTURE_COORD_3
		GL_MAP1_TEXTURE_COORD_4 GL_MAP1_VERTEX_3 GL_MAP1_VERTEX_4
		GL_MAP2_COLOR_4 GL_MAP2_INDEX GL_MAP2_NORMAL
		GL_MAP2_TEXTURE_COORD_1 GL_MAP2_TEXTURE_COORD_2
		GL_MAP2_TEXTURE_COORD_3 GL_MAP2_TEXTURE_COORD_4
		GL_MAP2_VERTEX_3 GL_MAP2_VERTEX_4 GL_NORMALIZE
		GL_POINT_SMOOTH GL_POLYGON_OFFSET_FILL GL_POLYGON_OFFSET_LINE
		GL_POLYGON_OFFSET_POINT GL_POLYGON_SMOOTH GL_POLYGON_STIPPLE
		GL_SCISSOR_TEST GL_STENCIL_TEST GL_TEXTURE_1D
		GL_TEXTURE_2D GL_TEXTURE_GEN_Q GL_TEXTURE_GEN_R
		GL_TEXTURE_GEN_S GL_TEXTURE_GEN_T

                GL_Q GL_R GL_S GL_T

                        GL_TEXTURE_GEN_MODE GL_REFLECTION_MAP
                                GL_OBJECT_LINEAR GL_EYE_LINEAR
                                GL_SPHERE_MAP
                                        GL_TEXTURE_CUBE_MAP


		GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT
		GL_ACCUM_BUFFER_BIT GL_STENCIL_BUFFER_BIT

		GL_MODELVIEW GL_PROJECTION GL_TEXTURE

		GL_COMPILE GL_COMPILE_AND_EXECUTE

		GL_FRONT GL_BACK GL_FRONT_AND_BACK
		GL_AMBIENT GL_DIFFUSE GL_SPECULAR GL_AMBIENT_AND_DIFFUSE

		GL_LIGHT_MODEL_LOCAL_VIEWER GL_LIGHT_MODEL_TWO_SIDE 
		GL_LIGHT_MODEL_AMBIENT

		GL_FLAT GL_SMOOTH

		GL_NEVER GL_LESS GL_EQUAL GL_LEQUAL GL_GREATER
		GL_NOTEQUAL GL_GEQUAL GL_ALWAYS

		GL_TRUE GL_FALSE

		GL_POINT GL_LINE GL_FILL

		GL_ZERO GL_ONE
		GL_DST_COLOR GL_ONE_MINUS_DST_COLOR GL_SRC_ALPHA 
		GL_ONE_MINUS_SRC_ALPHA GL_DST_ALPHA GL_ONE_MINUS_DST_ALPHA
		GL_SRC_ALPHA_SATURATE

		GL_SRC_COLOR GL_ONE_MINUS_SRC_COLOR 

		GL_FOG_HINT GL_LINE_SMOOTH_HINT GL_PERSPECTIVE_CORRECTION_HINT
		GL_POINT_SMOOTH_HINT GL_POLYGON_SMOOTH_HINT
		GL_FASTEST GL_NICEST GL_DONT_CARE

		GL_POSITION
		GL_SPOT_DIRECTION GL_SPOT_EXPONENT GL_SPOT_CUTOFF
		GL_CONSTANT_ATTENUATION GL_LINEAR_ATTENUATION
		GL_QUADRATIC_ATTENUATION

		GL_CW GL_CCW
                GL_EXP GL_EXP2

		GL_TEXTURE_MIN_FILTER GL_TEXTURE_MAG_FILTER
		GL_TEXTURE_WRAP_S GL_TEXTURE_WRAP_T GL_TEXTURE_PRIORITY
		GL_TEXTURE_BORDER_COLOR

		GL_NEAREST GL_LINEAR
		GL_NEAREST_MIPMAP_NEAREST GL_LINEAR_MIPMAP_NEAREST
		GL_NEAREST_MIPMAP_LINEAR  GL_LINEAR_MIPMAP_LINEAR

		GL_CLAMP GL_REPEAT


		GL_PROXY_TEXTURE_2D

		GL_ALPHA GL_ALPHA4 GL_ALPHA8 GL_ALPHA12 GL_ALPHA16 
		GL_LUMINANCE GL_LUMINANCE4 GL_LUMINANCE8 
		GL_LUMINANCE12 GL_LUMINANCE16 GL_LUMINANCE_ALPHA 
		GL_LUMINANCE4_ALPHA4 GL_LUMINANCE6_ALPHA2 GL_LUMINANCE8_ALPHA8 
		GL_LUMINANCE12_ALPHA4 GL_LUMINANCE12_ALPHA12 
		GL_LUMINANCE16_ALPHA16 GL_INTENSITY GL_INTENSITY4 
		GL_INTENSITY8 GL_INTENSITY12 GL_INTENSITY16 
		GL_R3_G3_B2 GL_RGB GL_RGB4 GL_RGB5 GL_RGB8 GL_RGB10 GL_RGB12
		GL_RGB16 GL_RGBA GL_RGBA2 GL_RGBA4 GL_RGB5_A1 
		GL_RGBA8 GL_RGB10_A2 GL_RGBA12 GL_RGBA16 

		GL_COLOR_INDEX GL_RED GL_GREEN GL_BLUE 

		GL_UNSIGNED_BYTE GL_BYTE GL_BITMAP 
		GL_UNSIGNED_SHORT GL_SHORT GL_UNSIGNED_INT GL_INT GL_FLOAT 

		GL_TEXTURE_ENV_MODE GL_TEXTURE_ENV GL_TEXTURE_ENV_COLOR 

		GL_MODULATE GL_DECAL GL_REPLACE

		GL_COLOR_ARRAY GL_CURRENT_RASTER_POSITION_VALID
		GL_DEPTH_WRITEMASK GL_DOUBLEBUFFER GL_EDGE_FLAG
		GL_EDGE_FLAG_ARRAY GL_INDEX_ARRAY GL_INDEX_MODE
		GL_MAP_COLOR GL_MAP_STENCIL GL_NORMAL_ARRAY
		GL_PACK_LSB_FIRST GL_PACK_SWAP_BYTES GL_RGBA_MODE
		GL_STEREO GL_TEXTURE_COORD_ARRAY GL_UNPACK_LSB_FIRST
		GL_UNPACK_SWAP_BYTES GL_VERTEX_ARRAY GL_COLOR_WRITEMASK
		GL_ACCUM_ALPHA_BITS GL_ACCUM_BLUE_BITS GL_ACCUM_GREEN_BITS
		GL_ACCUM_RED_BITS GL_ALPHA_BITS GL_ALPHA_TEST_FUNC
		GL_ATTRIB_STACK_DEPTH GL_AUX_BUFFERS GL_BLEND_DST
		GL_BLEND_EQUATION_EXT GL_BLEND_SRC GL_CLIENT_ATTRIB_STACK_DEPTH
		GL_COLOR_ARRAY_SIZE GL_COLOR_ARRAY_STRIDE GL_COLOR_ARRAY_TYPE
		GL_COLOR_MATERIAL_FACE GL_COLOR_MATERIAL_PARAMETER
		GL_CULL_FACE_MODE GL_CURRENT_INDEX GL_CURRENT_RASTER_INDEX
		GL_DEPTH_BITS GL_DEPTH_FUNC GL_DRAW_BUFFER
		GL_EDGE_FLAG_ARRAY_STRIDE GL_FOG_INDEX GL_FOG_MODE
		GL_FRONT_FACE GL_GREEN_BITS GL_INDEX_ARRAY_STRIDE
		GL_INDEX_ARRAY_TYPE GL_INDEX_BITS GL_INDEX_CLEAR_VALUE
		GL_INDEX_OFFSET GL_INDEX_SHIFT GL_INDEX_WRITEMASK
		GL_LINE_STIPPLE_PATTERN GL_LINE_STIPPLE_REPEAT GL_LIST_BASE
		GL_LIST_INDEX GL_LIST_MODE GL_LOGIC_OP_MODE
		GL_MAP1_GRID_SEGMENTS GL_MATRIX_MODE
		GL_MAX_CLIENT_ATTRIB_STACK_DEPTH GL_MAX_ATTRIB_STACK_DEPTH
		GL_MAX_CLIP_PLANES GL_MAX_EVAL_ORDER GL_MAX_LIGHTS
		GL_MAX_LIST_NESTING GL_MAX_MODELVIEW_STACK_DEPTH
		GL_MAX_NAME_STACK_DEPTH GL_MAX_PIXEL_MAP_TABLE
		GL_MAX_PROJECTION_STACK_DEPTH GL_MAX_TEXTURE_SIZE
		GL_MAX_TEXTURE_STACK_DEPTH GL_MODELVIEW_STACK_DEPTH
		GL_NAME_STACK_DEPTH GL_NORMAL_ARRAY_STRIDE
		GL_NORMAL_ARRAY_TYPE GL_PACK_ALIGNMENT
		GL_PACK_ROW_LENGTH GL_PACK_SKIP_PIXELS
		GL_PACK_SKIP_ROWS GL_PIXEL_MAP_A_TO_A_SIZE
		GL_PIXEL_MAP_B_TO_B_SIZE GL_PIXEL_MAP_G_TO_G_SIZE
		GL_PIXEL_MAP_I_TO_A_SIZE GL_PIXEL_MAP_I_TO_B_SIZE
		GL_PIXEL_MAP_I_TO_G_SIZE GL_PIXEL_MAP_I_TO_I_SIZE
		GL_PIXEL_MAP_I_TO_R_SIZE GL_PIXEL_MAP_R_TO_R_SIZE
		GL_PIXEL_MAP_S_TO_S_SIZE GL_PROJECTION_STACK_DEPTH
		GL_READ_BUFFER GL_RED_BITS GL_RENDER_MODE GL_SHADE_MODEL
		GL_STENCIL_BITS GL_STENCIL_CLEAR_VALUE GL_STENCIL_FAIL
		GL_STENCIL_FUNC GL_STENCIL_PASS_DEPTH_FAIL
		GL_STENCIL_PASS_DEPTH_PASS GL_STENCIL_REF GL_STENCIL_VALUE_MASK
		GL_STENCIL_WRITEMASK GL_SUBPIXEL_BITS
		GL_TEXTURE_COORD_ARRAY_SIZE GL_TEXTURE_COORD_ARRAY_STRIDE
		GL_TEXTURE_COORD_ARRAY_TYPE GL_TEXTURE_STACK_DEPTH
		GL_UNPACK_ALIGNMENT GL_UNPACK_ROW_LENGTH
		GL_UNPACK_SKIP_PIXELS GL_UNPACK_SKIP_ROWS
		GL_VERTEX_ARRAY_SIZE GL_VERTEX_ARRAY_STRIDE
		GL_VERTEX_ARRAY_TYPE GL_MAP2_GRID_SEGMENTS
		GL_MAX_VIEWPORT_DIMS GL_POLYGON_MODE
		GL_SCISSOR_BOX GL_VIEWPORT
		GL_ALPHA_BIAS GL_ALPHA_SCALE
		GL_ALPHA_TEST_REF GL_BLUE_BIAS GL_BLUE_BITS
		GL_BLUE_SCALE GL_CURRENT_RASTER_DISTANCE
		GL_DEPTH_BIAS GL_DEPTH_CLEAR_VALUE
		GL_DEPTH_SCALE GL_FOG_DENSITY
		GL_FOG_END GL_FOG_START
		GL_GREEN_SCALE GL_LINE_WIDTH
		GL_LINE_WIDTH_GRANULARITY GL_LINE_WIDTH_RANGE
		GL_POINT_SIZE GL_POINT_SIZE_GRANULARITY
		GL_POLYGON_OFFSET_FACTOR GL_POLYGON_OFFSET_UNITS
		GL_RED_BIAS GL_RED_SCALE
		GL_ZOOM_X GL_ZOOM_Y
		GL_DEPTH_RANGE GL_MAP1_GRID_DOMAIN
		GL_POINT_SIZE_RANGE GL_CURRENT_NORMAL
		GL_ACCUM_CLEAR_VALUE GL_BLEND_COLOR_EXT
		GL_COLOR_CLEAR_VALUE GL_CURRENT_COLOR
		GL_CURRENT_RASTER_COLOR GL_CURRENT_RASTER_POSITION
		GL_CURRENT_TEXTURE_COORDS GL_FOG_COLOR
		GL_GREEN_BIAS GL_MAP2_GRID_DOMAIN
		GL_MODELVIEW_MATRIX GL_PROJECTION_MATRIX GL_TEXTURE_MATRIX

		GL_NONE GL_FRONT_LEFT GL_FRONT_RIGHT GL_BACK_LEFT GL_BACK_RIGHT
		GL_LEFT GL_RIGHT GL_AUX0 GL_AUX1 GL_AUX2 GL_AUX3

		GL_PACK_IMAGE_HEIGHT GL_PACK_LENGTH
		GL_PACK_SKIP_IMAGES 
		GL_UNPACK_IMAGE_HEIGHT GL_UNPACK_LENGTH
		GL_UNPACK_SKIP_IMAGES GL_UNPACK_SKIP_ROWS
		GL_TEXTURE_WRAP_R GL_TEXTURE_3D

		
                glGetError

		gluPerspective gluOrtho2D gluLookAt
                gluErrorString

        glLoadTexture
        glSetupTexGen

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.03';

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

bootstrap OpenGL::Simple $VERSION;

# Preloaded methods go here.

sub glPolygonStipple {
    if (-1==$#_) {
        croak("glPolygonStipple needs at least one argument");
    } elsif (0==$#_) {
        my $s = shift;
        if ("ARRAY" eq ref $s) { 
            realglPolygonStipple(pack("C128",@{$s}));
        } else {
            realglPolygonStipple($s);
        }
    } else {
        # Assume it's an array of bitmap values. Pack it into
        # a 128-byte (32x32 bit) string.
        my $s = pack("C128",@_);
        realglPolygonStipple($s);
    }
}

# Wrapper around real TI2D call

sub glTexImage2D {

	# Preserve old 9-anonymous-argument version.
	if (9==@_) {
		realGLTexImage2D(@_);
		return;
	}

	# Otherwise assume we've been passed a hash.

	my %arg = @_;
	my $img = $arg{'image'};
	my $pixdata = undef;
	my $pixels=undef;
	my ($channels,$bits,$width,$height);

	if (defined($arg{'image'})) {
		my $img = $arg{'image'};
		$img = $img->to_rgb8;

		croak('image argument should be an Imager object')
			unless $img->isa('Imager');

		$channels = $img->getchannels;
		$bits = $img->bits;
		$width = $img->getwidth;
		$height = $img->getheight;

		# Grab the image data in raw format, and write into $pixels.
		$img->write(
			data => \$pixdata,
			type => 'raw') or croak('Image->write() failed');

		$pixels = \$pixdata;

	} else {
		$pixels = $arg{'pixels'}
			or croak('Need image or pixels argument');
		$bits = $arg{'bits'}
			or croak('Need "bits" argument');
		$width = $arg{'width'}
			or croak('Need "width" argument');
		$height = $arg{'height'}
			or croak('Need "height" argument');
	}


	# $pixels,$bits,$channels,$width,$height all defined.

	if ( (8!=$bits) && (16!=$bits)) {
		croak('Can only take 8 or 16-bit images');
	}

	# Now guess the format if not explicitly specified.

	my $format;

	if (!defined($format = $arg{'format'})) {
		if ( (0>=$channels) || ($channels>4)) {
			croak("Don't understand $channels-channel images");
		}
		$format =
		( GL_LUMINANCE(),GL_LUMINANCE_ALPHA(),GL_RGB(),GL_RGBA() )
			[$channels-1];
	}

	# If not explicitly specified, set internal format to
	# the number of channels.

	my $internalformat;
	if (!defined($internalformat = $arg{'internalformat'})) {
		$internalformat = $channels;
	}

	my $border = ($arg{'border'} or 0);
	my $target = ($arg{'target'} or GL_TEXTURE_2D());
	my $level = ($arg{'level'} or 0);
	my $type;

	if (!defined($type=$arg{'type'})) {
		if (8==$bits) {
			$type = GL_UNSIGNED_BYTE();
		} elsif (16==$bits) {
			$type = GL_UNSIGNED_SHORT();
		} else {
			croak("Don't understand $bits-bit images");
		}
	}


	# $target is either GL_TEXTURE_2D or GL_PROXY_TEXTURE_2D
	# $level is the LoD or mipmap level.
	# $internalformat specifies the number of components.
	# $width, $height, $channels hold the obvious.
	# $border is the border width, either 0 or 1
	# $format specifies the pixel format: GL_RED, GL_RGBA, etc.
	# $type describes the data type, eg GL_BYTE or GL_SHORT
	# $pixels is a reference to a scalar containing raw pixel data
	#
	realglTexImage2D(
		$target,
		$level,
		$internalformat,
		$width,
		$height,
		$border,
		$format,
		$type,
		$pixels
	);

}

# Wrapper around real TSI2D call

sub glTexSubImage2D {

    # Preserve old 9-anonymous-argument version.
    if (9==@_) {
        realglTexSubImage2D(@_);
        return;
    }

    # Otherwise assume we've been passed a hash.

    my %arg = @_;


        # Deal with the straightforward arguments first.

    my $target = ($arg{'target'} or GL_TEXTURE_2D());
    my $level = ($arg{'level'} or 0);
    my $xoffset = ($arg{'xoffset'} or 0);
    my $yoffset = ($arg{'yoffset'} or 0);

    # Now process the image data.

    my $img = $arg{'image'};
    croak("Require 'image' argument")
        unless defined($img);
    croak('image argument should be an Imager object')
        unless $img->isa('Imager');

    # NB convert it to RGB8!
    $img = $img->to_rgb8;

    my $bits = $img->bits;

    if ( (8!=$bits) && (16!=$bits)) {
            croak('Can only take 8 or 16-bit images');
    }

    # Grab the image data in raw format, and write into $pixels.
    my $pixdata;
    $img->write(
        data => \$pixdata,
        type => 'raw') or croak('Image->write() failed');
    my $pixels = \$pixdata;

    my $width = $img->getwidth;
    my $height = $img->getheight;

    my $channels = $img->getchannels;

    # Now guess the format if not explicitly specified.

    my $format = $arg{'format'};

    if (!defined($format)) {
        if ( (0>=$channels) || ($channels>4)) {
            croak("Don't understand $channels-channel images");
        }
        $format =
        ( GL_LUMINANCE(),GL_LUMINANCE_ALPHA(),GL_RGB(),GL_RGBA() )
            [$channels-1];
    }

    my $type=$arg{'type'};

    if (!defined($type)) {
        if (8==$bits) {
            $type = GL_UNSIGNED_BYTE();
        } elsif (16==$bits) {
            $type = GL_UNSIGNED_SHORT();
        } else {
            croak("Don't understand $bits-bit images");
        }
    }

    realglTexSubImage2D(
        $target, $level,
        $xoffset,$yoffset,
        $width,$height,
        $format,$type,$pixels);

}


sub glReadPixels {
	# Preserve old 7-anonymous-argument version.
	if (7==@_) {
		realglReadPixels(@_);
		return;
	}

        # Else assume we've been passed a hash or hashref.

        my %arg;
        if (1==@_) {
            %arg=%{$_[0]};
        } else {
            %arg = @_;
        }

        my $rawRef = $arg{'rawdata'};
        my $imageRef = $arg{'image'};
        
        croak("glReadPixels unfinished");

}

sub glPixelStore {
	my ($pname,$param) = @_;
	glPixelStorei($pname,$param);
}

sub glPixelTransfer {
	my ($pname,$param) = @_;
	glPixelTransferi($pname,$param);
}


1;
__END__

=head1 NAME

OpenGL::Simple - Another interface to OpenGL

=head1 SYNOPSIS

  use OpenGL::Simple qw(:all);
  use OpenGL::Simple::GLUT qw(:all);

  # All your favourite OpenGL functions and constants:
  glShadeModel(GL_SMOOTH);

  glLight(GL_LIGHT1,GL_AMBIENT,@LightAmbient);
  glLight(GL_LIGHT1,GL_DIFFUSE,@LightDiffuse);
  glLight(GL_LIGHT1,GL_SPECULAR,@LightSpecular);
  glLight(GL_LIGHT1,GL_POSITION,@LightPos);
  glEnable(GL_LIGHT1);
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
  ...


=head1 DESCRIPTION

This module provides an interface to the OpenGL 3d graphics library; it 
binds the OpenGL functions and constants to Perl subroutines with a 
polymorphic interface. 

For instance, the twenty-four C<glVertex*> functions are provided by a single
C<glVertex> routine which dispatches to the correct routine based on the number
of arguments.

=head1 AUTHORS

Jonathan Chin, E<lt>jon-opengl-simple@earth.liE<gt> ; Simon Cozens sanitized
the code and ported to MacOS X.

=head1 SEE ALSO

L<OpenGL::Simple::GLUT>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jonathan Chin
                                                                                
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
