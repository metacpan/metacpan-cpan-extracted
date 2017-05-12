# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..241\n"; }
END {print "not ok 1\n" unless $loaded;}
use RenderMan;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print RenderMan::RI_A eq "a" ? "ok 2" : "not ok 2", "\n";
print RenderMan::RI_ABORT eq "abort" ? "ok 3" : "not ok 3", "\n";
print RenderMan::RI_AMBIENTLIGHT eq "ambientlight" ? "ok 4" : "not ok 4", "\n";
print RenderMan::RI_AMPLITUDE eq "amplitude" ? "ok 5" : "not ok 5", "\n";
print RenderMan::RI_AZ eq "az" ? "ok 6" : "not ok 6", "\n";
print RenderMan::RI_BACKGROUND eq "background" ? "ok 7" : "not ok 7", "\n";
print RenderMan::RI_BEAMDISTRIBUTION eq "beamdistribution" ? "ok 8" : "not ok 8", "\n";
print RenderMan::RI_BICUBIC eq "bicubic" ? "ok 9" : "not ok 9", "\n";
print RenderMan::RI_BILINEAR eq "bilinear" ? "ok 10" : "not ok 10", "\n";
print RenderMan::RI_BLACK eq "black" ? "ok 11" : "not ok 11", "\n";
print RenderMan::RI_BUMPY eq "bumpy" ? "ok 12" : "not ok 12", "\n";
print RenderMan::RI_CAMERA eq "camera" ? "ok 13" : "not ok 13", "\n";
print RenderMan::RI_CLAMP eq "clamp" ? "ok 14" : "not ok 14", "\n";
print RenderMan::RI_COMMENT eq "comment" ? "ok 15" : "not ok 15", "\n";
print RenderMan::RI_CONEANGLE eq "coneangle" ? "ok 16" : "not ok 16", "\n";
print RenderMan::RI_CONEDELTAANGLE eq "conedeltaangle" ? "ok 17" : "not ok 17", "\n";
print RenderMan::RI_CONSTANT eq "constant" ? "ok 18" : "not ok 18", "\n";
print RenderMan::RI_CS eq "Cs" ? "ok 19" : "not ok 19", "\n";
print RenderMan::RI_DEPTHCUE eq "depthcue" ? "ok 20" : "not ok 20", "\n";
print RenderMan::RI_DIFFERENCE eq "difference" ? "ok 21" : "not ok 21", "\n";
print RenderMan::RI_DISTANCE eq "distance" ? "ok 22" : "not ok 22", "\n";
print RenderMan::RI_DISTANTLIGHT eq "distantlight" ? "ok 23" : "not ok 23", "\n";
print RenderMan::RI_FILE eq "file" ? "ok 24" : "not ok 24", "\n";
print RenderMan::RI_FLATNESS eq "flatness" ? "ok 25" : "not ok 25", "\n";
print RenderMan::RI_FOG eq "fog" ? "ok 26" : "not ok 26", "\n";
print RenderMan::RI_FOV eq "fov" ? "ok 27" : "not ok 27", "\n";
print RenderMan::RI_FRAMEBUFFER eq "framebuffer" ? "ok 28" : "not ok 28", "\n";
print RenderMan::RI_FROM eq "from" ? "ok 29" : "not ok 29", "\n";
print RenderMan::RI_HANDLER eq "handler" ? "ok 30" : "not ok 30", "\n";
print RenderMan::RI_HIDDEN eq "hidden" ? "ok 31" : "not ok 31", "\n";
print RenderMan::RI_IDENTIFIER eq "identifier" ? "ok 32" : "not ok 32", "\n";
print RenderMan::RI_IGNORE eq "ignore" ? "ok 33" : "not ok 33", "\n";
print RenderMan::RI_INSIDE eq "inside" ? "ok 34" : "not ok 34", "\n";
print RenderMan::RI_INTENSITY eq "intensity" ? "ok 35" : "not ok 35", "\n";
print RenderMan::RI_INTERSECTION eq "intersection" ? "ok 36" : "not ok 36", "\n";
print RenderMan::RI_KA eq "Ka" ? "ok 37" : "not ok 37", "\n";
print RenderMan::RI_KD eq "Kd" ? "ok 38" : "not ok 38", "\n";
print RenderMan::RI_KR eq "Kr" ? "ok 39" : "not ok 39", "\n";
print RenderMan::RI_KS eq "Ks" ? "ok 40" : "not ok 40", "\n";
print RenderMan::RI_LH eq "lh" ? "ok 41" : "not ok 41", "\n";
print RenderMan::RI_LIGHTCOLOR eq "lightcolor" ? "ok 42" : "not ok 42", "\n";
print RenderMan::RI_MATTE eq "matte" ? "ok 43" : "not ok 43", "\n";
print RenderMan::RI_MAXDISTANCE eq "maxdistance" ? "ok 44" : "not ok 44", "\n";
print RenderMan::RI_METAL eq "metal" ? "ok 45" : "not ok 45", "\n";
print RenderMan::RI_MINDISTANCE eq "mindistance" ? "ok 46" : "not ok 46", "\n";
print RenderMan::RI_N eq "N" ? "ok 47" : "not ok 47", "\n";
print RenderMan::RI_NAME eq "name" ? "ok 48" : "not ok 48", "\n";
print RenderMan::RI_NONPERIODIC eq "nonperiodic" ? "ok 49" : "not ok 49", "\n";
print RenderMan::RI_NP eq "Np" ? "ok 50" : "not ok 50", "\n";
print RenderMan::RI_OBJECT eq "object" ? "ok 51" : "not ok 51", "\n";
print RenderMan::RI_ORIGIN eq "origin" ? "ok 52" : "not ok 52", "\n";
print RenderMan::RI_ORTHOGRAPHIC eq "orthographic" ? "ok 53" : "not ok 53", "\n";
print RenderMan::RI_OS eq "Os" ? "ok 54" : "not ok 54", "\n";
print RenderMan::RI_OUTSIDE eq "outside" ? "ok 55" : "not ok 55", "\n";
print RenderMan::RI_P eq "P" ? "ok 56" : "not ok 56", "\n";
print RenderMan::RI_PAINT eq "paint" ? "ok 57" : "not ok 57", "\n";
print RenderMan::RI_PAINTEDPLASTIC eq "paintedplastic" ? "ok 58" : "not ok 58", "\n";
print RenderMan::RI_PERIODIC eq "periodic" ? "ok 59" : "not ok 59", "\n";
print RenderMan::RI_PERSPECTIVE eq "perspective" ? "ok 60" : "not ok 60", "\n";
print RenderMan::RI_PLASTIC eq "plastic" ? "ok 61" : "not ok 61", "\n";
print RenderMan::RI_POINTLIGHT eq "pointlight" ? "ok 62" : "not ok 62", "\n";
print RenderMan::RI_PRIMITIVE eq "primitive" ? "ok 63" : "not ok 63", "\n";
print RenderMan::RI_PRINT eq "print" ? "ok 64" : "not ok 64", "\n";
print RenderMan::RI_PW eq "Pw" ? "ok 65" : "not ok 65", "\n";
print RenderMan::RI_PZ eq "Pz" ? "ok 66" : "not ok 66", "\n";
print RenderMan::RI_RASTER eq "raster" ? "ok 67" : "not ok 67", "\n";
print RenderMan::RI_RGB eq "rgb" ? "ok 68" : "not ok 68", "\n";
print RenderMan::RI_RGBA eq "rgba" ? "ok 69" : "not ok 69", "\n";
print RenderMan::RI_RGBAZ eq "rgbaz" ? "ok 70" : "not ok 70", "\n";
print RenderMan::RI_RGBZ eq "rgbz" ? "ok 71" : "not ok 71", "\n";
print RenderMan::RI_RH eq "rh" ? "ok 72" : "not ok 72", "\n";
print RenderMan::RI_ROUGHNESS eq "roughness" ? "ok 73" : "not ok 73", "\n";
print RenderMan::RI_S eq "s" ? "ok 74" : "not ok 74", "\n";
print RenderMan::RI_SCREEN eq "screen" ? "ok 75" : "not ok 75", "\n";
print RenderMan::RI_SHINYMETAL eq "shinymetal" ? "ok 76" : "not ok 76", "\n";
print RenderMan::RI_SMOOTH eq "smooth" ? "ok 77" : "not ok 77", "\n";
print RenderMan::RI_SPECULARCOLOR eq "specularcolor" ? "ok 78" : "not ok 78", "\n";
print RenderMan::RI_SPOTLIGHT eq "spotlight" ? "ok 79" : "not ok 79", "\n";
print RenderMan::RI_ST eq "st" ? "ok 80" : "not ok 80", "\n";
print RenderMan::RI_STRUCTURE eq "structure" ? "ok 81" : "not ok 81", "\n";
print RenderMan::RI_T eq "t" ? "ok 82" : "not ok 82", "\n";
print RenderMan::RI_TEXTURENAME eq "texturename" ? "ok 83" : "not ok 83", "\n";
print RenderMan::RI_TO eq "to" ? "ok 84" : "not ok 84", "\n";
print RenderMan::RI_UNION eq "union" ? "ok 85" : "not ok 85", "\n";
print RenderMan::RI_WORLD eq "world" ? "ok 86" : "not ok 86", "\n";
print RenderMan::RI_Z eq "z" ? "ok 87" : "not ok 87", "\n";
@val = RenderMan::BSplineBasis;
print "@val" eq "-0.16666667163372 0.5 -0.5 0.16666667163372 0.5 -1 0.5 0 -0.5 0 0.5 0 0.16666667163372 0.666666686534882 0.16666667163372 0" ? "ok 88" : "not ok 88", "\n";
@val = RenderMan::BezierBasis;
print "@val" eq "-1 3 -3 1 3 -6 3 0 -3 3 0 0 1 0 0 0" ? "ok 89" : "not ok 89", "\n";
@val = RenderMan::CatmullRomBasis;
print "@val" eq "-0.5 1.5 -1.5 0.5 1 -2.5 2 -0.5 -0.5 0 0.5 0 0 1 0 0" ? "ok 90" : "not ok 90", "\n";
@val = RenderMan::HermiteBasis;
print "@val" eq "2 1 -2 1 -3 -2 3 -1 0 1 0 0 1 0 0 0" ? "ok 91" : "not ok 91", "\n";
@val = RenderMan::PowerBasis;
print "@val" eq "1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1" ? "ok 92" : "not ok 92", "\n";
print RenderMan::RIE_BADFILE      ==  4 ? "ok 93" : "not ok 93", "\n";    # Bad file format
print RenderMan::RIE_BADHANDLE    == 44 ? "ok 94" : "not ok 94", "\n";    # Bad object/light handle
print RenderMan::RIE_BADMOTION    == 29 ? "ok 95" : "not ok 95", "\n";    # Badly formed motion block
print RenderMan::RIE_BADSOLID     == 30 ? "ok 96" : "not ok 96", "\n";    # Badly formed solid block
print RenderMan::RIE_BADTOKEN     == 41 ? "ok 97" : "not ok 97", "\n";    # Invalid token for request
print RenderMan::RIE_BUG          == 14 ? "ok 98" : "not ok 98", "\n";    # Probably a bug in renderer
print RenderMan::RIE_CONSISTENCY  == 43 ? "ok 99" : "not ok 99", "\n";    # Parameters inconsistent
print RenderMan::RIE_ERROR        ==  2 ? "ok 100" : "not ok 100", "\n";    # Problem.  Results may be wrong
print RenderMan::RIE_ILLSTATE     == 28 ? "ok 101" : "not ok 101", "\n";    # Other invalid state
print RenderMan::RIE_INCAPABLE    == 11 ? "ok 102" : "not ok 102", "\n";    # Optional RI feature
print RenderMan::RIE_INFO         ==  0 ? "ok 103" : "not ok 103", "\n";    # Rendering stats & other info
print RenderMan::RIE_LIMIT        == 13 ? "ok 104" : "not ok 104", "\n";    # Arbitrary program limit
print RenderMan::RIE_MATH         == 61 ? "ok 105" : "not ok 105", "\n";    # Zerodivide, noninvert matrix, etc.
print RenderMan::RIE_MISSINGDATA  == 46 ? "ok 106" : "not ok 106", "\n";    # Required parameters not provided
print RenderMan::RIE_NESTING      == 24 ? "ok 107" : "not ok 107", "\n";    # Bad begin-end nesting
print RenderMan::RIE_NOERROR      ==  0 ? "ok 108" : "not ok 108", "\n";
print RenderMan::RIE_NOFILE       ==  3 ? "ok 109" : "not ok 109", "\n";    # File nonexistant
print RenderMan::RIE_NOMEM        ==  1 ? "ok 110" : "not ok 110", "\n";    # Out of memory
print RenderMan::RIE_NOSHADER     == 45 ? "ok 111" : "not ok 111", "\n";    # Can't load requested shader
print RenderMan::RIE_NOTATTRIBS   == 26 ? "ok 112" : "not ok 112", "\n";    # Invalid state for attributes
print RenderMan::RIE_NOTOPTIONS   == 25 ? "ok 113" : "not ok 113", "\n";    # Invalid state for options
print RenderMan::RIE_NOTPRIMS     == 27 ? "ok 114" : "not ok 114", "\n";    # Invalid state for primitives
print RenderMan::RIE_NOTSTARTED   == 23 ? "ok 115" : "not ok 115", "\n";    # RiBegin not called
print RenderMan::RIE_OPTIONAL     == 11 ? "ok 116" : "not ok 116", "\n";    # Optional RI feature
print RenderMan::RIE_RANGE        == 42 ? "ok 117" : "not ok 117", "\n";    # Parameter out of range
print RenderMan::RIE_SEVERE       ==  3 ? "ok 118" : "not ok 118", "\n";    # So bad you should probably abort
print RenderMan::RIE_SYNTAX       == 47 ? "ok 119" : "not ok 119", "\n";    # Declare type syntax error
print RenderMan::RIE_SYSTEM       ==  2 ? "ok 120" : "not ok 120", "\n";    # Miscellaneous system error
print RenderMan::RIE_UNIMPLEMENT  == 12 ? "ok 121" : "not ok 121", "\n";    # Unimplemented feature
print RenderMan::RIE_VERSION      ==  5 ? "ok 122" : "not ok 122", "\n";    # File version mismatch
print RenderMan::RIE_WARNING      ==  1 ? "ok 123" : "not ok 123", "\n";    # Something seems wrong, maybe okay
print RenderMan::RI_BEZIERSTEP    ==  3 ? "ok 124" : "not ok 124", "\n";
print RenderMan::RI_BSPLINESTEP   ==  1 ? "ok 125" : "not ok 125", "\n";
print RenderMan::RI_CATMULLROMSTEP==  1 ? "ok 126" : "not ok 126", "\n";
print RenderMan::RI_EPSILON       == 1.0e-10 ? "ok 127" : "not ok 127", "\n";
print RenderMan::RI_FALSE         ==  0 ? "ok 128" : "not ok 128", "\n";
print RenderMan::RI_H             ==  1 ? "ok 129" : "not ok 129", "\n";
print RenderMan::RI_HERMITESTEP   ==  2 ? "ok 130" : "not ok 130", "\n";
print RenderMan::RI_INFINITY      == 1.0e38 ? "ok 131" : "not ok 131", "\n";
print RenderMan::RI_NULL          ==  0 ? "ok 132" : "not ok 132", "\n";
print RenderMan::RI_POWERSTEP     ==  4 ? "ok 133" : "not ok 133", "\n";
print RenderMan::RI_TRUE          ==  1 ? "ok 134" : "not ok 134", "\n";

# New constants as of BMRT2.3.6b...
print RenderMan::RI_LINEAR eq "linear" ? 'ok 135' : 'not ok 135', "\n";
print RenderMan::RI_CUBIC eq "cubic" ? 'ok 136' : 'not ok 136', "\n";
print RenderMan::RI_WIDTH eq "width" ? 'ok 137' : 'not ok 137', "\n";
print RenderMan::RI_CONSTANTWIDTH eq "constantwidth" ? 'ok 138' : 'not ok 138', "\n";

# Make sure that we get basic output from libribout...
Begin("foo");
End();

open TESTFILE, "<./foo";
$bar = <TESTFILE>;
if ($bar eq "##RenderMan RIB-Structure 1.0\n") {print "ok 139\n";} else {print "not ok 139\n";}
$bar = <TESTFILE>;
if ($bar eq "version 3.03\n") {print "ok 140\n";} else {print "not ok 140\n";}
close(TESTFILE);
unlink "./foo";

# Now test the individual routines and make sure we get reasonable output...
Begin("foo");
  $val = Declare("Howdy", "float");
  if ($val eq "Howdy") {print "ok 141\n";} else {print "not ok 141\n";}

  FrameBegin(27);
  FrameEnd();
  WorldBegin();
  WorldEnd();
  Format(600, 400, 1);
  FrameAspectRatio(1);
  ScreenWindow(0, 1, 0.1, 0.9);
  CropWindow(0.1, 0.9, 0.2, 0.8);
  Projection("perspective");
  Clipping(0.5, 0.8);
  DepthOfField(2.0, 20.0, 40.0);
  Shutter(0.1, 0.2);
  PixelVariance(0.5);
  PixelSamples(3,3);
# PixelFilter();
  Exposure(4,0.7);
  Imager("imager");
  Quantize("quantize", 1, 2, 3, 4);
  Display("perltest.tif", "framebuffer", "rgba");
#  $val = GaussianFilter(20,30,0.2,0.3);
#  $val = BoxFilter(20,30,0.2,0.3);
#  $val = TriangleFilter(20,30,0.2,0.3);
#  $val = CatmullRomFilter(20,30,0.2,0.3);
#  $val = SincFilter(20,30,0.2,0.3);
  Hider("hider");
  ColorSamples(2, [1,2,3,4,5,6], [6,5,4,3,2,1]);    # interesting... no output
  RelativeDetail(5.0);
  Option("testme");
  AttributeBegin();
  AttributeEnd();
  Color(1,2,3);
  Color([1,2,3]);
  Opacity(4,5,6);
  Opacity([4,5,6]);
  TextureCoordinates(1,2,3,4,5,6,7,8);
  $val = LightSource("distantlight");
  if ($val eq "distantlight") {print "ok 142\n";} else {print "not ok 142\n";}

  $val = AreaLightSource("arealight");
  if ($val eq "arealight") {print "ok 143\n";} else {print "not ok 143\n";}

  Illuminate(1, 0);
  Surface("yo");
  Atmosphere("yep");
  Interior("uh_huh");
  Exterior("yessirreeLarry");
  ShadingRate(2);
  ShadingInterpolation("wave");
  Matte(1);
  Bound([1,2,3,4,5,6]);
  Detail([7,8,9,1,2,3]);
  DetailRange(1,2,3,4);
  GeometricApproximation("itsybitsy",4);
  GeometricRepresentation("tiny");
  Orientation("upsidedown");
  ReverseOrientation();
  Sides(2);
  Identity();
  Transform([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]);
  ConcatTransform([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]);
  Perspective(40);
  Translate(1,2,3);
  Rotate(90,1,1,1);
  Scale(2,4,6);
  Skew(30,1,2,3,4,5,6);
  Deformation("deform");
  Displacement("displace");
  CoordinateSystem("mine");
#  TransformPoints("world", "object", 3, [1,2,3, 4,5,6, 7,8,9]);
  TransformBegin();
  TransformEnd();
  Attribute("feo");
  Attribute("light", {"integer nsamples" => 4});
  Attribute("light", {"string shadows" => "on"});
  Polygon(2, { "P" => [1,2,3, 4,5,6] });
  GeneralPolygon(2, [2,2], { "P" => [1,2,3, 4,5,6, 7,8,9, 10,11,12] });
  PointsPolygons(1, [2], [0,1], { "P" => [1,2,3, 4,5,6] });
  PointsGeneralPolygons(1, [1], [2], [0,1], { "P" => [1,2,3, 4,5,6] });
  Basis([ HermiteBasis ], 2, [ BezierBasis ], 3);
  Patch(RI_BICUBIC);
  PatchMesh(RI_BILINEAR, 1, "yo", 2, "yow");
  TrimCurve(1, [4], [2,2,2,2], [0,0,1,1,0,0,30.9472,30.9472,0,0,1,1,-30.9472,-30.9472,0,0], [0,0,0,-30.9472], [1,30.9472,1,0], [2,2,2,2], [0,1,1,1,1,0,0,0], [0,0,0,1,1,1,1,0], [1,1,1,1,1,1,1,1]);
  NuPatch(9,3,[0,0,0,0.25,0.25,0.5,0.5,0.75,0.75,1,1,1 ],0,1,5,3,[ 0,0,0,0.5,0.5,1,1,1 ],0,1, {"Pw" => [0.0730667,0.146111,10.1086,1,0.051666,0.103316,7.14788,0.707107,0.0730667,0.146111,10.1086,1,0.051666,0.103316,7.14788,0.707107,0.0730667,0.146111,10.1086,1,0.051666,0.103316,7.14788,0.707107,0.0730667,0.146111,10.1086,1,0.051666,0.103316,7.14788,0.707107,0.0730667,0.146111,10.1086,1,7.19955,0.103316,7.14788,0.707107,5.09085,-4.98126,5.05432,0.5,0.051666,-7.04457,7.14788,0.707107,-5.01778,-4.98126,5.05432,0.5,-7.09622,0.103316,7.14788,0.707107,-5.01778,5.12737,5.05432,0.5,0.051666,7.2512,7.14788,0.707107,5.09085,5.12737,5.05432,0.5,7.19955,0.103316,7.14788,0.707107,10.1817,0.146111,-8.74301e-016,1,7.19955,-7.04457,-6.18224e-016,0.707107,0.0730667,-9.96252,-8.74301e-016,1,-7.09622,-7.04457,-6.18224e-016,0.707107,-10.0356,0.146111,-8.74301e-016,1,-7.09622,7.2512,-6.18224e-016,0.707107,0.0730667,10.2547,-8.74301e-016,1,7.19955,7.2512,-6.18224e-016,0.707107,10.1817,0.146111,-8.74301e-016,1,7.19955,0.103316,-7.14788,0.707107,5.09085,-4.98126,-5.05432,0.5,0.051666,-7.04457,-7.14788,0.707107,-5.01778,-4.98126,-5.05432,0.5,-7.09622,0.103316,-7.14788,0.707107,-5.01778,5.12737,-5.05432,0.5,0.051666,7.2512,-7.14788,0.707107,5.09085,5.12737,-5.05432,0.5,7.19955,0.103316,-7.14788,0.707107,0.0730667,0.146111,-10.1086,1,0.051666,0.103316,-7.14788,0.707107,0.0730667,0.146111,-10.1086,1,0.051666,0.103316,-7.14788,0.707107,0.0730667,0.146111,-10.1086,1,0.051666,0.103316,-7.14788,0.707107,0.0730667,0.146111,-10.1086,1,0.051666,0.103316,-7.14788,0.707107,0.0730667,0.146111,-10.1086,1]} );

  Sphere(1,-1,1,360);
  Cone(5,2,180);
  Cylinder(2,-2,2,90);
  Hyperboloid([1,2,3], [4,5,6], 360);
  Paraboloid(2,4,7,120);
  Disk(0,3,260);
  Torus(5,1,0,360,360);
#  Curves(RI_LINEAR, 1, [4], RI_PERIODIC);  # Not implemented in BMRT2.3.6b
  Geometry("complex");
  SolidBegin("xor");
  SolidEnd();
  $val = ObjectBegin();
  if ($val == 1) {print "ok 144\n";} else {print "not ok 144\n";}

  ObjectEnd();
  ObjectInstance(1);
  MotionBegin(6, 0, 0.2, 0.4, 0.6, 0.8, 1);
  MotionEnd();
#  MakeTexture();
#  MakeBump();
#  MakeLatLongEnvironment();
#  MakeCubeFaceEnvironment();
#  MakeShadow();
#  ErrorHandler();
#  ErrorIgnore();
#  ErrorPrint();
#  ErrorAbort();
#  ArchiveRecord();
  ReadArchive("file.rib");
End();

open TESTFILE, "<./foo";
$bar = <TESTFILE>;
if ($bar eq "##RenderMan RIB-Structure 1.0\n") {print "ok 145\n";} else {print "not ok 145\n";}
$bar = <TESTFILE>;
if ($bar eq "version 3.03\n") {print "ok 146\n";} else {print "not ok 146\n";}
$bar = <TESTFILE>;
if ($bar eq "Declare \"Howdy\" \"float\"\n") {print "ok 147\n";} else {print "not ok 147\n";}
$bar = <TESTFILE>;
if ($bar eq "FrameBegin 27\n") {print "ok 148\n";} else {print "not ok 148\n";}
$bar = <TESTFILE>;
if ($bar eq "FrameEnd\n") {print "ok 149\n";} else {print "not ok 149\n";}
$bar = <TESTFILE>;
if ($bar eq "WorldBegin\n") {print "ok 150\n";} else {print "not ok 150\n";}
$bar = <TESTFILE>;
if ($bar eq "WorldEnd\n") {print "ok 151\n";} else {print "not ok 151\n";}
$bar = <TESTFILE>;
if ($bar eq "Format 600 400 1\n") {print "ok 152\n";} else {print "not ok 152\n";}
$bar = <TESTFILE>;
if ($bar eq "FrameAspectRatio 1\n") {print "ok 153\n";} else {print "not ok 153\n";}
$bar = <TESTFILE>;
if ($bar eq "ScreenWindow 0 1 0.1 0.9\n") {print "ok 154\n";} else {print "not ok 154\n";}
$bar = <TESTFILE>;
if ($bar eq "CropWindow 0.1 0.9 0.2 0.8\n") {print "ok 155\n";} else {print "not ok 155\n";}
$bar = <TESTFILE>;
if ($bar eq "Projection \"perspective\"\n") {print "ok 156\n";} else {print "not ok 156\n";}
$bar = <TESTFILE>;
if ($bar eq "Clipping 0.5 0.8\n") {print "ok 157\n";} else {print "not ok 157\n";}
$bar = <TESTFILE>;
if ($bar eq "DepthOfField 2 20 40\n") {print "ok 158\n";} else {print "not ok 158\n";}
$bar = <TESTFILE>;
if ($bar eq "Shutter 0.1 0.2\n") {print "ok 159\n";} else {print "not ok 159\n";}
$bar = <TESTFILE>;
if ($bar eq "PixelVariance 0.5\n") {print "ok 160\n";} else {print "not ok 160\n";}
$bar = <TESTFILE>;
if ($bar eq "PixelSamples 3 3\n") {print "ok 161\n";} else {print "not ok 161\n";}
$bar = <TESTFILE>;
if ($bar eq "Exposure 4 0.7\n") {print "ok 162\n";} else {print "not ok 162\n";}
$bar = <TESTFILE>;
if ($bar eq "Imager \"imager\"\n") {print "ok 163\n";} else {print "not ok 163\n";}
$bar = <TESTFILE>;
if ($bar eq "Quantize \"quantize\" 1 2 3 4\n") {print "ok 164\n";} else {print "not ok 164\n";}
$bar = <TESTFILE>;
if ($bar eq "Display \"perltest.tif\" \"framebuffer\" \"rgba\"\n") {print "ok 165\n";} else {print "not ok 165\n";}
$bar = <TESTFILE>;
if ($bar eq "Hider \"hider\"\n") {print "ok 166\n";} else {print "not ok 166\n";}
$bar = <TESTFILE>;
if ($bar eq "RelativeDetail 5\n") {print "ok 167\n";} else {print "not ok 167\n";}
$bar = <TESTFILE>;
if ($bar eq "Option \"testme\"\n") {print "ok 168\n";} else {print "not ok 168\n";}
$bar = <TESTFILE>;
if ($bar eq "AttributeBegin\n") {print "ok 169\n";} else {print "not ok 169\n";}
$bar = <TESTFILE>;
if ($bar eq "AttributeEnd\n") {print "ok 170\n";} else {print "not ok 170\n";}
$bar = <TESTFILE>;
if ($bar eq "Color [1 2 3]\n") {print "ok 171\n";} else {print "not ok 171\n";}
$bar = <TESTFILE>;
if ($bar eq "Color [1 2 3]\n") {print "ok 172\n";} else {print "not ok 172\n";}
$bar = <TESTFILE>;
if ($bar eq "Opacity [4 5 6]\n") {print "ok 173\n";} else {print "not ok 173\n";}
$bar = <TESTFILE>;
if ($bar eq "Opacity [4 5 6]\n") {print "ok 174\n";} else {print "not ok 174\n";}
$bar = <TESTFILE>;
if ($bar eq "TextureCoordinates [ 1 2 3 4 5 6 7 8 ]\n") {print "ok 175\n";} else {print "not ok 175\n";}
$bar = <TESTFILE>;
if ($bar eq "LightSource \"distantlight\" 1\n") {print "ok 176\n";} else {print "not ok 176\n";}
$bar = <TESTFILE>;
if ($bar eq "AreaLightSource \"arealight\" 2\n") {print "ok 177\n";} else {print "not ok 177\n";}
$bar = <TESTFILE>;
if ($bar eq "Illuminate 1 0\n") {print "ok 178\n";} else {print "not ok 178\n";}
$bar = <TESTFILE>;
if ($bar eq "Surface \"yo\"\n") {print "ok 179\n";} else {print "not ok 179\n";}
$bar = <TESTFILE>;
if ($bar eq "Atmosphere \"yep\"\n") {print "ok 180\n";} else {print "not ok 180\n";}
$bar = <TESTFILE>;
if ($bar eq "Interior \"uh_huh\"\n") {print "ok 181\n";} else {print "not ok 181\n";}
$bar = <TESTFILE>;
if ($bar eq "Exterior \"yessirreeLarry\"\n") {print "ok 182\n";} else {print "not ok 182\n";}
$bar = <TESTFILE>;
if ($bar eq "ShadingRate 2\n") {print "ok 183\n";} else {print "not ok 183\n";}
$bar = <TESTFILE>;
if ($bar eq "ShadingInterpolation \"wave\"\n") {print "ok 184\n";} else {print "not ok 184\n";}
$bar = <TESTFILE>;
if ($bar eq "Matte 1\n") {print "ok 185\n";} else {print "not ok 185\n";}
$bar = <TESTFILE>;
if ($bar eq "Bound [1 2 3 4 5 6]\n") {print "ok 186\n";} else {print "not ok 186\n";}
$bar = <TESTFILE>;
if ($bar eq "Detail [7 8 9 1 2 3]\n") {print "ok 187\n";} else {print "not ok 187\n";}
$bar = <TESTFILE>;
if ($bar eq "DetailRange 1 2 3 4\n") {print "ok 188\n";} else {print "not ok 188\n";}
$bar = <TESTFILE>;
if ($bar eq "GeometricApproximation \"itsybitsy\" 4\n") {print "ok 189\n";} else {print "not ok 189\n";}
$bar = <TESTFILE>;
if ($bar eq "GeometricRepresentation \"tiny\"\n") {print "ok 190\n";} else {print "not ok 190\n";}
$bar = <TESTFILE>;
if ($bar eq "Orientation \"upsidedown\"\n") {print "ok 191\n";} else {print "not ok 191\n";}
$bar = <TESTFILE>;
if ($bar eq "ReverseOrientation\n") {print "ok 192\n";} else {print "not ok 192\n";}
$bar = <TESTFILE>;
if ($bar eq "Sides 2\n") {print "ok 193\n";} else {print "not ok 193\n";}
$bar = <TESTFILE>;
if ($bar eq "Identity\n") {print "ok 194\n";} else {print "not ok 194\n";}
$bar = <TESTFILE>;
if ($bar eq "Transform [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]\n") {print "ok 195\n";} else {print "not ok 195\n";}
$bar = <TESTFILE>;
if ($bar eq "ConcatTransform [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]\n") {print "ok 196\n";} else {print "not ok 196\n";}
$bar = <TESTFILE>;
if ($bar eq "Perspective 40\n") {print "ok 197\n";} else {print "not ok 197\n";}
$bar = <TESTFILE>;
if ($bar eq "Translate 1 2 3 \n") {print "ok 198\n";} else {print "not ok 198\n";}
$bar = <TESTFILE>;
if ($bar eq "Rotate 90 1 1 1 \n") {print "ok 199\n";} else {print "not ok 199\n";}
$bar = <TESTFILE>;
if ($bar eq "Scale 2 4 6\n") {print "ok 200\n";} else {print "not ok 200\n";}
$bar = <TESTFILE>;
if ($bar eq "Skew 30   1 2 3   4 5 6\n") {print "ok 201\n";} else {print "not ok 201\n";}
$bar = <TESTFILE>;
if ($bar eq "Deformation \"deform\"\n") {print "ok 202\n";} else {print "not ok 202\n";}
$bar = <TESTFILE>;
if ($bar eq "Displacement \"displace\"\n") {print "ok 203\n";} else {print "not ok 203\n";}
$bar = <TESTFILE>;
if ($bar eq "CoordinateSystem \"mine\"\n") {print "ok 204\n";} else {print "not ok 204\n";}
$bar = <TESTFILE>;
if ($bar eq "TransformBegin\n") {print "ok 205\n";} else {print "not ok 205\n";}
$bar = <TESTFILE>;
if ($bar eq "TransformEnd\n") {print "ok 206\n";} else {print "not ok 206\n";}
$bar = <TESTFILE>;
if ($bar eq "Attribute \"feo\"\n") {print "ok 207\n";} else {print "not ok 207\n";}
$bar = <TESTFILE>;
if ($bar eq "Attribute \"light\" \"integer nsamples\" [4 ]\n") {print "ok 207.5\n";} else {print "not ok 207.5\n";}
$bar = <TESTFILE>;
if ($bar eq "Attribute \"light\" \"string shadows\" [\"on\"]\n") {print "ok 207.6\n";} else {print "not ok 207.6\n";}
$bar = <TESTFILE>;
if ($bar eq "Polygon \"P\" [1 2 3 4 5 6]\n") {print "ok 208\n";} else {print "not ok 208\n";}
$bar = <TESTFILE>;
if ($bar eq "GeneralPolygon[2 2 ]  \"P\" [1 2 3 4 5 6 7 8 9 10 11 12]\n") {print "ok 209\n";} else {print "not ok 209\n";}
$bar = <TESTFILE>;
if ($bar eq "PointsPolygons[2 ] [0 1 ]  \"P\" [1 2 3 4 5 6]\n") {print "ok 210\n";} else {print "not ok 210\n";}
$bar = <TESTFILE>;
if ($bar eq "PointsGeneralPolygons[1 ] [2 ] [0 1 ]  \"P\" [1 2 3 4 5 6]\n") {print "ok 211\n";} else {print "not ok 211\n";}
$bar = <TESTFILE>;
if ($bar eq "Basis [2 1 -2 1 -3 -2 3 -1 0 1 0 0 1 0 0 0] 2 [-1 3 -3 1 3 -6 3 0 -3 3 0 0 1 0 0 0] 3\n") {print "ok 212\n";} else {print "not ok 212\n";}
$bar = <TESTFILE>;
if ($bar eq "Patch \"bicubic\"\n") {print "ok 213\n";} else {print "not ok 213\n";}
$bar = <TESTFILE>;
if ($bar eq "PatchMesh \"bilinear\" 1 \"yo\" 2 \"yow\"\n") {print "ok 214\n";} else {print "not ok 214\n";}
$bar = <TESTFILE>;
if ($bar eq "TrimCurve [4 ][2 2 2 2 ][0 0 1 1 0 0 30.9472 30.9472 0 0 1 1 -30.9472 -30.9472 0 0] [0 0 0 -30.9472] [1 30.9472 1 0] [2 2 2 2 ][0 1 1 1 1 0 0 0] [0 0 0 1 1 1 1 0] [1 1 1 1 1 1 1 1]\n") {print "ok 215\n";} else {print "not ok 215\n";}
$bar = <TESTFILE>;
if ($bar eq "NuPatch 9 3 [0 0 0 0.25 0.25 0.5 0.5 0.75 0.75 1 1 1] 0.000000 1.000000 5 3 [0 0 0 0.5 0.5 1 1 1] 0.000000 1.000000  \"Pw\" [0.0730667 0.146111 10.1086 1 0.051666 0.103316 7.14788 0.707107 0.0730667 0.146111 10.1086 1 0.051666 0.103316 7.14788 0.707107 0.0730667 0.146111 10.1086 1 0.051666 0.103316 7.14788 0.707107 0.0730667 0.146111 10.1086 1 0.051666 0.103316 7.14788 0.707107 0.0730667 0.146111 10.1086 1 7.19955 0.103316 7.14788 0.707107 5.09085 -4.98126 5.05432 0.5 0.051666 -7.04457 7.14788 0.707107 -5.01778 -4.98126 5.05432 0.5 -7.09622 0.103316 7.14788 0.707107 -5.01778 5.12737 5.05432 0.5 0.051666 7.2512 7.14788 0.707107 5.09085 5.12737 5.05432 0.5 7.19955 0.103316 7.14788 0.707107 10.1817 0.146111 -8.74301e-016 1 7.19955 -7.04457 -6.18224e-016 0.707107 0.0730667 -9.96252 -8.74301e-016 1 -7.09622 -7.04457 -6.18224e-016 0.707107 -10.0356 0.146111 -8.74301e-016 1 -7.09622 7.2512 -6.18224e-016 0.707107 0.0730667 10.2547 -8.74301e-016 1 7.19955 7.2512 -6.18224e-016 0.707107 10.1817 0.146111 -8.74301e-016 1 7.19955 0.103316 -7.14788 0.707107 5.09085 -4.98126 -5.05432 0.5 0.051666 -7.04457 -7.14788 0.707107 -5.01778 -4.98126 -5.05432 0.5 -7.09622 0.103316 -7.14788 0.707107 -5.01778 5.12737 -5.05432 0.5 0.051666 7.2512 -7.14788 0.707107 5.09085 5.12737 -5.05432 0.5 7.19955 0.103316 -7.14788 0.707107 0.0730667 0.146111 -10.1086 1 0.051666 0.103316 -7.14788 0.707107 0.0730667 0.146111 -10.1086 1 0.051666 0.103316 -7.14788 0.707107 0.0730667 0.146111 -10.1086 1 0.051666 0.103316 -7.14788 0.707107 0.0730667 0.146111 -10.1086 1 0.051666 0.103316 -7.14788 0.707107 0.0730667 0.146111 -10.1086 1]\n") {print "ok 216\n";} else {print "not ok 216\n";}
$bar = <TESTFILE>;
if ($bar eq "Sphere 1 -1 1 360\n") {print "ok 217\n";} else {print "not ok 217\n";}
$bar = <TESTFILE>;
if ($bar eq "Cone 5 2 180\n") {print "ok 218\n";} else {print "not ok 218\n";}
$bar = <TESTFILE>;
if ($bar eq "Cylinder 2 -2 2 90\n") {print "ok 219\n";} else {print "not ok 219\n";}
$bar = <TESTFILE>;
if ($bar eq "Hyperboloid 1 2 3 4 5 6 360\n") {print "ok 220\n";} else {print "not ok 220\n";}
$bar = <TESTFILE>;
if ($bar eq "Paraboloid 2 4 7 120\n") {print "ok 221\n";} else {print "not ok 221\n";}
$bar = <TESTFILE>;
if ($bar eq "Disk 0 3 260\n") {print "ok 222\n";} else {print "not ok 222\n";}
$bar = <TESTFILE>;
if ($bar eq "Torus 5 1 0 360 360\n") {print "ok 223\n";} else {print "not ok 223\n";}
$bar = <TESTFILE>;
if ($bar eq "Geometry \"complex\"\n") {print "ok 224\n";} else {print "not ok 224\n";}
$bar = <TESTFILE>;
if ($bar eq "SolidBegin \"xor\"\n") {print "ok 225\n";} else {print "not ok 225\n";}
$bar = <TESTFILE>;
if ($bar eq "SolidEnd\n") {print "ok 226\n";} else {print "not ok 226\n";}
$bar = <TESTFILE>;
if ($bar eq "ObjectBegin 1\n") {print "ok 227\n";} else {print "not ok 227\n";}
$bar = <TESTFILE>;
if ($bar eq "ObjectEnd\n") {print "ok 228\n";} else {print "not ok 228\n";}
$bar = <TESTFILE>;
if ($bar eq "ObjectInstance 1\n") {print "ok 229\n";} else {print "not ok 229\n";}
$bar = <TESTFILE>;
if ($bar eq "MotionBegin [0 0.2 0.4 0.6 0.8 1]\n") {print "ok 230\n";} else {print "not ok 230\n";}
$bar = <TESTFILE>;
if ($bar eq "MotionEnd\n") {print "ok 231\n";} else {print "not ok 231\n";}
$bar = <TESTFILE>;
if ($bar eq "ReadArchive \"file.rib\"\n") {print "ok 232\n";} else {print "not ok 232\n";}

close(TESTFILE);
unlink "./foo";

print RenderMan::RI_CURRENT eq "current" ? "ok 233" : "not ok 233", "\n";
print RenderMan::RI_WORLD   eq "world"   ? "ok 234" : "not ok 234", "\n";
print RenderMan::RI_OBJECT  eq "object"  ? "ok 235" : "not ok 235", "\n";
print RenderMan::RI_SHADER  eq "shader"  ? "ok 236" : "not ok 236", "\n";
print RenderMan::RI_RASTER  eq "raster"  ? "ok 237" : "not ok 237", "\n";
print RenderMan::RI_NDC     eq "NDC"     ? "ok 238" : "not ok 238", "\n";
print RenderMan::RI_SCREEN  eq "screen"  ? "ok 239" : "not ok 239", "\n";
print RenderMan::RI_CAMERA  eq "camera"  ? "ok 240" : "not ok 240", "\n";
print RenderMan::RI_EYE     eq "eye"     ? "ok 241" : "not ok 241", "\n";
