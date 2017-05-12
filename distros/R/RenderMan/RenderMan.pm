package RenderMan;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	RIE_BADFILE
	RIE_BADHANDLE
	RIE_BADMOTION
	RIE_BADSOLID
	RIE_BADTOKEN
	RIE_BUG
	RIE_CONSISTENCY
	RIE_ERROR
	RIE_ILLSTATE
	RIE_INCAPABLE
	RIE_INFO
	RIE_LIMIT
	RIE_MATH
	RIE_MISSINGDATA
	RIE_NESTING
	RIE_NOERROR
	RIE_NOFILE
	RIE_NOMEM
	RIE_NOSHADER
	RIE_NOTATTRIBS
	RIE_NOTOPTIONS
	RIE_NOTPRIMS
	RIE_NOTSTARTED
	RIE_OPTIONAL
	RIE_RANGE
	RIE_SEVERE
	RIE_SYNTAX
	RIE_SYSTEM
	RIE_UNIMPLEMENT
	RIE_VERSION
	RIE_WARNING
	RI_BEZIERSTEP
	RI_BSPLINESTEP
	RI_CATMULLROMSTEP
	RI_EPSILON
	RI_FALSE
	RI_H
	RI_HERMITESTEP
	RI_INFINITY
	RI_NULL
	RI_POWERSTEP
	RI_TRUE

	RI_A
	RI_ABORT
	RI_AMBIENTLIGHT
	RI_AMPLITUDE
	RI_AZ
	RI_BACKGROUND
	RI_BEAMDISTRIBUTION
	RI_BICUBIC
	RI_BILINEAR
	RI_BLACK
	RI_BUMPY
	RI_CAMERA
	RI_CLAMP
	RI_COMMENT
	RI_CONEANGLE
	RI_CONEDELTAANGLE
	RI_CONSTANT
	RI_CS
	RI_DEPTHCUE
	RI_DIFFERENCE
	RI_DISTANCE
	RI_DISTANTLIGHT
	RI_FILE
	RI_FLATNESS
	RI_FOG
	RI_FOV
	RI_FRAMEBUFFER
	RI_FROM
	RI_HANDLER
	RI_HIDDEN
	RI_IDENTIFIER
	RI_IGNORE
	RI_INSIDE
	RI_INTENSITY
	RI_INTERSECTION
	RI_KA
	RI_KD
	RI_KR
	RI_KS
	RI_LH
	RI_LIGHTCOLOR
	RI_MATTE
	RI_MAXDISTANCE
	RI_METAL
	RI_MINDISTANCE
	RI_N
	RI_NAME
	RI_NONPERIODIC
	RI_NP
	RI_OBJECT
	RI_ORIGIN
	RI_ORTHOGRAPHIC
	RI_OS
	RI_OUTSIDE
	RI_P
	RI_PAINT
	RI_PAINTEDPLASTIC
	RI_PERIODIC
	RI_PERSPECTIVE
	RI_PLASTIC
	RI_POINTLIGHT
	RI_PRIMITIVE
	RI_PRINT
	RI_PW
	RI_PZ
	RI_RASTER
	RI_RGB
	RI_RGBA
	RI_RGBAZ
	RI_RGBZ
	RI_RH
	RI_ROUGHNESS
	RI_S
	RI_SCREEN
	RI_SHINYMETAL
	RI_SMOOTH
	RI_SPECULARCOLOR
	RI_SPOTLIGHT
	RI_ST
	RI_STRUCTURE
	RI_T
	RI_TEXTURENAME
	RI_TO
	RI_UNION
	RI_WORLD
	RI_Z

	RI_LINEAR
	RI_CUBIC
	RI_WIDTH
	RI_CONSTANTWIDTH

	RI_CURRENT
	RI_WORLD
	RI_OBJECT
	RI_SHADER
	RI_RASTER
	RI_NDC
	RI_SCREEN
	RI_CAMERA
	RI_EYE
        
	BSplineBasis
	BezierBasis
	CatmullRomBasis
	HermiteBasis
	PowerBasis

	Declare
	Begin
	End
	FrameBegin
	FrameEnd
	WorldBegin
	WorldEnd
	Format
	FrameAspectRatio
	ScreenWindow
	CropWindow
	Projection
	Clipping
	DepthOfField
	Shutter
	PixelVariance
	PixelSamples
	PixelFilter
	Exposure
	Imager
	Quantize
	Display
	GaussianFilter
	BoxFilter
	TriangleFilter
	CatmullRomFilter
	SincFilter
	Hider
	ColorSamples
	RelativeDetail
	Option
	AttributeBegin
	AttributeEnd
	Color
	Opacity
	TextureCoordinates
	LightSource
	AreaLightSource
	Illuminate
	Surface
	Atmosphere
	Interior
	Exterior
	ShadingRate
	ShadingInterpolation
	Matte
	Bound
	Detail
	DetailRange
	GeometricApproximation
	GeometricRepresentation
	Orientation
	ReverseOrientation
	Sides
	Identity
	Transform
	ConcatTransform
	Perspective
	Translate
	Rotate
	Scale
	Skew
	Deformation
	Displacement
	CoordinateSystem
	TransformPoints
	TransformBegin
	TransformEnd
	Attribute
	Polygon
	GeneralPolygon
	PointsPolygons
	PointsGeneralPolygons
	Basis
	Patch
	PatchMesh
	NuPatch
	TrimCurve
	Sphere
	Cone
	Cylinder
	Hyperboloid
	Paraboloid
	Disk
	Torus
	Geometry
	Curves
	Points
	SubdivisionMesh
	Blobby
	ProcDelayedReadArchive
	ProcRunProgram
	ProcDynamicLoad
	SolidBegin
	SolidEnd
	ObjectBegin
	ObjectEnd
	ObjectInstance
	MotionBegin
	MotionEnd
	MakeTexture
	MakeBump
	MakeLatLongEnvironment
	MakeCubeFaceEnvironment
	MakeShadow
	ErrorHandler
	ErrorIgnore
	ErrorPrint
	ErrorAbort
	ArchiveRecord
	ReadArchive
);
$VERSION = '0.04';

bootstrap RenderMan $VERSION;

# Preloaded methods go here.

sub RIE_BADFILE      {  4; }    # Bad file format
sub RIE_BADHANDLE    { 44; }    # Bad object/light handle
sub RIE_BADMOTION    { 29; }    # Badly formed motion block
sub RIE_BADSOLID     { 30; }    # Badly formed solid block
sub RIE_BADTOKEN     { 41; }    # Invalid token for request
sub RIE_BUG          { 14; }    # Probably a bug in renderer
sub RIE_CONSISTENCY  { 43; }    # Parameters inconsistent
sub RIE_ERROR        {  2; }    # Problem.  Results may be wrong
sub RIE_ILLSTATE     { 28; }    # Other invalid state
sub RIE_INCAPABLE    { 11; }    # Optional RI feature
sub RIE_INFO         {  0; }    # Rendering stats & other info
sub RIE_LIMIT        { 13; }    # Arbitrary program limit
sub RIE_MATH         { 61; }    # Zerodivide, noninvert matrix, etc.
sub RIE_MISSINGDATA  { 46; }    # Required parameters not provided
sub RIE_NESTING      { 24; }    # Bad begin-end nesting
sub RIE_NOERROR      {  0; }
sub RIE_NOFILE       {  3; }    # File nonexistant
sub RIE_NOMEM        {  1; }    # Out of memory
sub RIE_NOSHADER     { 45; }    # Can't load requested shader
sub RIE_NOTATTRIBS   { 26; }    # Invalid state for attributes
sub RIE_NOTOPTIONS   { 25; }    # Invalid state for options
sub RIE_NOTPRIMS     { 27; }    # Invalid state for primitives
sub RIE_NOTSTARTED   { 23; }    # RiBegin not called
sub RIE_OPTIONAL     { 11; }    # Optional RI feature
sub RIE_RANGE        { 42; }    # Parameter out of range
sub RIE_SEVERE       {  3; }    # So bad you should probably abort
sub RIE_SYNTAX       { 47; }    # Declare type syntax error
sub RIE_SYSTEM       {  2; }    # Miscellaneous system error
sub RIE_UNIMPLEMENT  { 12; }    # Unimplemented feature
sub RIE_VERSION      {  5; }    # File version mismatch
sub RIE_WARNING      {  1; }    # Something seems wrong, maybe okay
sub RI_BEZIERSTEP    {  3; }
sub RI_BSPLINESTEP   {  1; }
sub RI_CATMULLROMSTEP{  1; }
sub RI_EPSILON       { 1.0e-10; }
sub RI_FALSE         {  0; }
sub RI_H             {  1; }
sub RI_HERMITESTEP   {  2; }
sub RI_INFINITY      { 1.0e38; }
sub RI_NULL          {  ""; }
sub RI_POWERSTEP     {  4; }
sub RI_TRUE          {  1; }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RenderMan - A RenderMan binding as a Perl 5.6 module

=head1 SYNOPSIS

  use RenderMan;

=head1 DESCRIPTION

This RenderMan module implements a Perl 5.6 binding for the BMRT client library
(libribout).  It fully supports the client library.
Therefore, this module has the following limitations:
Error Handling callbacks are not implemented, Filter function callbacks are
not implemented, and the TransformPoints function does nothing.
Also, Blobby is not yet supported by BMRT 2.5.0.8.

The full RenderMan specification is way beyond the scope of this man page.
Please refer to the documents below for more information about RenderMan.
The Perl binding is identical to the C binding except a few minor points:
All "parameterlist"s are passed as a reference to a hash (i.e. \%params).
Anywhere that a function's arguments can be terminated by RI_NULL, you can
simply choose to not include that RI_NULL argument, which is incredibly nice.

All array, matrix, and basis types are single-dimension arrays of doubles in
this Perl binding.  The order for 2-dimension types is first-row followed
by second-row, etc.

You will typically want to run your RenderMan Perl script and pipe the
results into any RenderMan-compliant renderer, such as "rgl", "rendribv",
or "rendrib", which all come with the excellent BMRT backage by Larry Gritz.

If using the WinNT version of BMRT, you can specify a filename, "rgl" or "rendrib"
as the argument to Begin(); and the output will be sent to a file or automatically
piped to "rgl" or "rendrib" since the piping mechanism (and general functionality)
of WinNT's command line parser is, uh, limited.

=head1 AUTHOR

Glenn M. Lewis, mailto:glenn@gmlewis.com, http://www.gmlewis.com/

=head1 SEE ALSO

Blue Moon Rendering Toolkit (BMRT) by Larry Gritz.
http://www.bmrt.org/

The RenderMan Companion: A Programmer's Guide to Realistic Computer Graphics
by Steve Upstill, published by Addison Wesley.  ISBN 0-201-50868-0.

Advanced RenderMan: Creating CGI for Motion Pictures
by Anthony A. Apodaca and Larry Gritz, published by Morgan Kaufmann Publishers
ISBN 1-55860-618-1

The RenderMan Interface Specification, Version 3.2, July 2000, Pixar.
http://www.pixar.com/products/rendermandocs/toolkit/Toolkit/

RenderMan is a registered trademark of Pixar.
http://www.pixar.com/

=cut
