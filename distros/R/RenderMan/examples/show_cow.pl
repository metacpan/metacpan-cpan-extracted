#!../perl -w
#
#     show_cow.pl
#
# This program demonstrates display of a LightWave3D object using RenderMan
# 


# The following "BEGIN" line is needed so that "use" is 
# able to find the built RenderMan module (the one created by doing
# a "make" in the above directory).
# Comment it out if you are using/testing the "installed" module.
# i.e. if you did a "make install" then you don't need to look in ../blib
#
BEGIN{ unshift(@INC,"../blib"); }
BEGIN{ unshift(@INC,"../blib/arch"); } # 5.002 gamma needs this
BEGIN{ unshift(@INC,"../blib/lib");  } # 5.002 gamma needs this
use RenderMan;

$file = "rgl";
if ($#ARGV >= 0) { $file = $ARGV[0]; }

Begin($file);
  FrameBegin(1);
    Display("cow1.tif", "file", "rgba");
    Format(640, 480, 1);
    LightSource(RI_DISTANTLIGHT, { "intensity" => 2, "lightcolor" => [1,1,1],
                                   "from" => [0,100,-100], "to" => [0,0,0]} );
    Projection(RI_PERSPECTIVE);
    Sides(2);
    Translate(0, 0, 2);
    WorldBegin();
      Translate(0, -0.75, 0);
      AttributeBegin();
	Rotate(110, 0, 1, 0);
	Surface("gmarbtile_polish");
	Color(0, 0.5, 1);
	ReadArchive("cow.rib");
      AttributeEnd();
      AttributeBegin();
	Rotate(90, 1, 0, 0);
	Surface("superplank");
	Disk(0, 5, 360);
      AttributeEnd();
    WorldEnd();
  FrameEnd();
End();
