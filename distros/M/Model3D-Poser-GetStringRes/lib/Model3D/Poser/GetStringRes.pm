package Model3D::Poser::GetStringRes;
use 5.006;
use strict;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ('all' => [qw(GetStringRes ParseStringRes stringRes)]);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}}, 'stringRes', 'ParseStringRes');
our @EXPORT = qw(GetStringRes);

our $VERSION = '1.00';

our $emulation = 'default';

our $stringRes = [[]];

$stringRes->[1024]->[1] = 'Body';
$stringRes->[1024]->[2] = 'Head';
$stringRes->[1024]->[3] = 'Neck';
$stringRes->[1024]->[4] = 'Chest';
$stringRes->[1024]->[5] = 'Abdomen';
$stringRes->[1024]->[6] = 'Hip';
$stringRes->[1024]->[7] = 'Left Thigh';
$stringRes->[1024]->[8] = 'Left Shin';
$stringRes->[1024]->[9] = 'Left Foot';
$stringRes->[1024]->[10] = 'Right Thigh';
$stringRes->[1024]->[11] = 'Right Shin';
$stringRes->[1024]->[12] = 'Right Foot';
$stringRes->[1024]->[13] = 'Left Shoulder';
$stringRes->[1024]->[14] = 'Left Forearm';
$stringRes->[1024]->[15] = 'Left Hand';
$stringRes->[1024]->[16] = 'Right Shoulder';
$stringRes->[1024]->[17] = 'Right Forearm';
$stringRes->[1024]->[18] = 'Right Hand';
$stringRes->[1024]->[19] = 'Left Collar';
$stringRes->[1024]->[20] = 'Right Collar';
$stringRes->[1024]->[21] = 'Jaw';
$stringRes->[1024]->[22] = 'Left Pinky 1';
$stringRes->[1024]->[23] = 'Left Pinky 2';
$stringRes->[1024]->[24] = 'Left Pinky 3';
$stringRes->[1024]->[25] = 'Right Pinky 1';
$stringRes->[1024]->[26] = 'Right Pinky 2';
$stringRes->[1024]->[27] = 'Right Pinky 3';
$stringRes->[1024]->[28] = 'Left Ring 1';
$stringRes->[1024]->[29] = 'Left Ring 2';
$stringRes->[1024]->[30] = 'Left Ring 3';
$stringRes->[1024]->[31] = 'Right Ring 1';
$stringRes->[1024]->[32] = 'Right Ring 2';
$stringRes->[1024]->[33] = 'Right Ring 3';
$stringRes->[1024]->[34] = 'Left Mid 1';
$stringRes->[1024]->[35] = 'Left Mid 2';
$stringRes->[1024]->[36] = 'Left Mid 3';
$stringRes->[1024]->[37] = 'Right Mid 1';
$stringRes->[1024]->[38] = 'Right Mid 2';
$stringRes->[1024]->[39] = 'Right Mid 3';
$stringRes->[1024]->[40] = 'Left Index 1';
$stringRes->[1024]->[41] = 'Left Index 2';
$stringRes->[1024]->[42] = 'Left Index 3';
$stringRes->[1024]->[43] = 'Right Index 1';
$stringRes->[1024]->[44] = 'Right Index 2';
$stringRes->[1024]->[45] = 'Right Index 3';
$stringRes->[1024]->[46] = 'Left Thumb 1';
$stringRes->[1024]->[47] = 'Left Thumb 2';
$stringRes->[1024]->[48] = 'Left Thumb 3';
$stringRes->[1024]->[49] = 'Right Thumb 1';
$stringRes->[1024]->[50] = 'Right Thumb 2';
$stringRes->[1024]->[51] = 'Right Thumb 3';
$stringRes->[1024]->[52] = 'Left Toe';
$stringRes->[1024]->[53] = 'Right Toe';
$stringRes->[1024]->[54] = 'Neck 1';
$stringRes->[1024]->[55] = 'Neck 2';
$stringRes->[1024]->[56] = 'Right Finger 1';
$stringRes->[1024]->[57] = 'Right Claw 1';
$stringRes->[1024]->[58] = 'Right Finger 2';
$stringRes->[1024]->[59] = 'Right Claw 2';
$stringRes->[1024]->[60] = 'Right Finger 3';
$stringRes->[1024]->[61] = 'Right Claw 3';
$stringRes->[1024]->[62] = 'Left Finger 1';
$stringRes->[1024]->[63] = 'Left Claw 1';
$stringRes->[1024]->[64] = 'Left Finger 2';
$stringRes->[1024]->[65] = 'Left Claw 2';
$stringRes->[1024]->[66] = 'Left Finger 3';
$stringRes->[1024]->[67] = 'Left Claw 3';
$stringRes->[1024]->[68] = 'Right Toe 1';
$stringRes->[1024]->[69] = 'Right Toe 2';
$stringRes->[1024]->[70] = 'Left Toe 1';
$stringRes->[1024]->[71] = 'Left Toe 2';
$stringRes->[1024]->[72] = 'Tail 1';
$stringRes->[1024]->[73] = 'Tail 2';
$stringRes->[1024]->[74] = 'Tail 3';
$stringRes->[1024]->[75] = 'Tail 4';
$stringRes->[1024]->[76] = 'Left Up Arm';
$stringRes->[1024]->[77] = 'Right Up Arm';
$stringRes->[1024]->[78] = 'Left Wrist';
$stringRes->[1024]->[79] = 'Right Wrist';
$stringRes->[1024]->[80] = 'Lower Neck';
$stringRes->[1024]->[81] = 'Upper Neck';
$stringRes->[1024]->[82] = 'Left Leg';
$stringRes->[1024]->[83] = 'Right Leg';
$stringRes->[1024]->[84] = 'Left Ankle';
$stringRes->[1024]->[85] = 'Right Ankle';
$stringRes->[1024]->[86] = 'Waist';
$stringRes->[1024]->[87] = 'Left Ear 1';
$stringRes->[1024]->[88] = 'Right Ear 1';
$stringRes->[1024]->[89] = 'Left Ear 2';
$stringRes->[1024]->[90] = 'Right Ear 2';
$stringRes->[1024]->[91] = 'Left Ear 3';
$stringRes->[1024]->[92] = 'Right Ear 3';
$stringRes->[1024]->[93] = 'Tail Fins';
$stringRes->[1024]->[94] = 'Right Pect Fin';
$stringRes->[1024]->[95] = 'Left Pect Fin';
$stringRes->[1024]->[96] = 'Body 1';
$stringRes->[1024]->[97] = 'Body 2';
$stringRes->[1024]->[98] = 'Body 3';
$stringRes->[1024]->[99] = 'Body 4';
$stringRes->[1024]->[100] = 'Body 5';
$stringRes->[1024]->[101] = 'Left Eye';
$stringRes->[1024]->[102] = 'Right Eye';
$stringRes->[1024]->[103] = 'innerMatSphere';
$stringRes->[1024]->[104] = 'outerMatSphere';
$stringRes->[1024]->[105] = 'nullMatSphere';
$stringRes->[1025]->[1] = 'Main Camera';
$stringRes->[1025]->[2] = 'Side Camera';
$stringRes->[1025]->[3] = 'Top Camera';
$stringRes->[1025]->[4] = 'Front Camera';
$stringRes->[1025]->[5] = 'Posing Camera';
$stringRes->[1025]->[6] = 'Dolly Camera';
$stringRes->[1025]->[7] = 'Shadow Lite1 Cam';
$stringRes->[1025]->[8] = 'Shadow Lite 2 Cam';
$stringRes->[1025]->[9] = 'Shadow Lite 3 Cam';
$stringRes->[1025]->[10] = 'Right Camera';
$stringRes->[1025]->[11] = 'Left Camera';
$stringRes->[1025]->[12] = 'Face Camera';
$stringRes->[1025]->[13] = 'LHand Camera';
$stringRes->[1025]->[14] = 'RHand Camera';
$stringRes->[1025]->[15] = 'Aux Camera';
$stringRes->[1025]->[16] = 'Back Camera';
$stringRes->[1025]->[17] = 'Bottom Camera';
$stringRes->[1025]->[18] = 'Shadow Cam Lite 4';
$stringRes->[1026]->[1] = 'Ball';
$stringRes->[1026]->[2] = 'Box';
$stringRes->[1026]->[3] = 'Cane';
$stringRes->[1026]->[4] = 'Stairs';
$stringRes->[1026]->[5] = 'Torus';
$stringRes->[1026]->[6] = 'Cyl';
$stringRes->[1026]->[7] = 'Cone';
$stringRes->[1026]->[8] = 'Square';
$stringRes->[1026]->[9] = 'GROUND';
$stringRes->[1026]->[10] = 'UNIVERSE';
$stringRes->[1026]->[11] = '%s_%ld';
$stringRes->[1027]->[1] = 'Light 1';
$stringRes->[1027]->[2] = 'Light 2';
$stringRes->[1027]->[3] = 'Light 3';
$stringRes->[1028]->[1] = 'Taper';
$stringRes->[1028]->[2] = 'Twist';
$stringRes->[1028]->[3] = 'Side-Side';
$stringRes->[1028]->[4] = 'Bend';
$stringRes->[1028]->[5] = 'Scale';
$stringRes->[1028]->[6] = 'xScale';
$stringRes->[1028]->[7] = 'yScale';
$stringRes->[1028]->[8] = 'zScale';
$stringRes->[1028]->[9] = 'xRotate';
$stringRes->[1028]->[10] = 'yRotate';
$stringRes->[1028]->[11] = 'zRotate';
$stringRes->[1028]->[12] = 'xTran';
$stringRes->[1028]->[13] = 'yTran';
$stringRes->[1028]->[14] = 'zTran';
$stringRes->[1028]->[15] = 'Focal';
$stringRes->[1028]->[16] = 'Pitch';
$stringRes->[1028]->[17] = 'Yaw';
$stringRes->[1028]->[18] = 'Roll';
$stringRes->[1028]->[19] = 'Red';
$stringRes->[1028]->[20] = 'Green';
$stringRes->[1028]->[21] = 'Blue';
$stringRes->[1028]->[22] = 'Intensity';
$stringRes->[1028]->[23] = 'Turn';
$stringRes->[1028]->[24] = 'Front-Back';
$stringRes->[1028]->[25] = 'DollyX';
$stringRes->[1028]->[26] = 'DollyY';
$stringRes->[1028]->[27] = 'DollyZ';
$stringRes->[1028]->[28] = 'Shadow';
$stringRes->[1028]->[29] = 'Map Size';
$stringRes->[1028]->[30] = 'PanX';
$stringRes->[1028]->[31] = 'PanY';
$stringRes->[1028]->[32] = 'Zoom';
$stringRes->[1028]->[33] = 'xTranB';
$stringRes->[1028]->[34] = 'yTranB';
$stringRes->[1028]->[35] = 'zTranB';
$stringRes->[1028]->[36] = 'xOffset';
$stringRes->[1028]->[37] = 'yOffset';
$stringRes->[1028]->[38] = 'zOffset';
$stringRes->[1028]->[39] = 'xOrbit';
$stringRes->[1028]->[40] = 'yOrbit';
$stringRes->[1028]->[41] = 'zOrbit';
$stringRes->[1028]->[42] = 'Hand Type';
$stringRes->[1028]->[43] = 'BreastSize';
$stringRes->[1028]->[44] = 'OriginX';
$stringRes->[1028]->[45] = 'OriginY';
$stringRes->[1028]->[46] = 'OriginZ';
$stringRes->[1028]->[47] = 'Fatness';
$stringRes->[1028]->[48] = 'Grasp';
$stringRes->[1028]->[49] = 'Thumb Grasp';
$stringRes->[1028]->[50] = 'Spread';
$stringRes->[1028]->[51] = 'Curve';
$stringRes->[1028]->[52] = 'curve';
$stringRes->[1028]->[53] = 'Up-Down';
$stringRes->[1029]->[1] = 'No Bump';
$stringRes->[1029]->[2] = 'Male Muscle Bump.bum';
$stringRes->[1029]->[3] = 'Female Muscle Bump.bum';
$stringRes->[1029]->[4] = 'None';
$stringRes->[1029]->[5] = 'Male Muscle Texture.tif';
$stringRes->[1029]->[6] = 'Female Muscle Texture.tif';
$stringRes->[1029]->[7] = 'Ground Default Texture.tif';
$stringRes->[1029]->[8] = 'male casual texture.tif';
$stringRes->[1029]->[9] = 'female casual texture.tif';
$stringRes->[1029]->[10] = 'male nude texture.tif';
$stringRes->[1029]->[11] = 'female nude texture.tif';
$stringRes->[1029]->[12] = 'male business texture.tif';
$stringRes->[1029]->[13] = 'female business texture.tif';
$stringRes->[1029]->[14] = 'child nude texture.tif';
$stringRes->[1029]->[15] = 'child casual texture.tif';
$stringRes->[1029]->[16] = 'ground Default Texture.bum';
$stringRes->[1029]->[17] = 'angelfishmap.tif';
$stringRes->[1029]->[18] = 'biz man texture.tif';
$stringRes->[1029]->[19] = 'biz woman texture.tif';
$stringRes->[1029]->[20] = 'casual child texture.tif';
$stringRes->[1029]->[21] = 'casual man texture.tif';
$stringRes->[1029]->[22] = 'casual woman texture.tif';
$stringRes->[1029]->[23] = 'cat texture.tif';
$stringRes->[1029]->[24] = 'child hair texture.tif';
$stringRes->[1029]->[25] = 'dog texture.tif';
$stringRes->[1029]->[26] = 'dolphin texture.tif';
$stringRes->[1029]->[27] = 'female hair 1 texture.tif';
$stringRes->[1029]->[28] = 'female hair 2 texture.tif';
$stringRes->[1029]->[29] = 'female hair 3 texture.tif';
$stringRes->[1029]->[30] = 'female hair 4 texture.tif';
$stringRes->[1029]->[31] = 'female hair 5 texture.tif';
$stringRes->[1029]->[32] = 'frogmap.tif';
$stringRes->[1029]->[33] = 'hand texture.tif';
$stringRes->[1029]->[34] = 'horse texture.tif';
$stringRes->[1029]->[35] = 'lionmap.tif';
$stringRes->[1029]->[36] = 'male hair 1 texture.tif';
$stringRes->[1029]->[37] = 'male hair 2 texture.tif';
$stringRes->[1029]->[38] = 'male hair 3 texture.tif';
$stringRes->[1029]->[39] = 'male hair 4 texture.tif';
$stringRes->[1029]->[40] = 'male hair 5 texture.tif';
$stringRes->[1029]->[41] = 'nude child texture.tif';
$stringRes->[1029]->[42] = 'nude man texture.tif';
$stringRes->[1029]->[43] = 'nude woman texture.tif';
$stringRes->[1029]->[44] = 'raptor texture.bum';
$stringRes->[1029]->[45] = 'raptor texture.tif';
$stringRes->[1029]->[46] = 'wolfmap.tif';
$stringRes->[1029]->[47] = 'p4 man bump.bum';
$stringRes->[1029]->[48] = 'p4 man bump.tif';
$stringRes->[1029]->[49] = 'p4 man texture.tif';
$stringRes->[1029]->[50] = 'p4 man texture2.tif';
$stringRes->[1029]->[51] = 'p4 woman bump.bum';
$stringRes->[1029]->[52] = 'p4 woman bump.tif';
$stringRes->[1029]->[53] = 'p4 woman texture.tif';
$stringRes->[1029]->[54] = 'p4 woman texture2.tif';
$stringRes->[1029]->[55] = 'p4casboy.tif';
$stringRes->[1029]->[56] = 'p4casgirl.tif';
$stringRes->[1029]->[57] = 'p4infant.tif';
$stringRes->[1029]->[58] = 'p4nudboy.tif';
$stringRes->[1029]->[59] = 'p4nudgirl.tif';
$stringRes->[1029]->[60] = 'snakelo.tif';
$stringRes->[1030]->[1] = 'Figure';
$stringRes->[1030]->[2] = 'Untitled';
$stringRes->[1030]->[3] = 'Render';
$stringRes->[1030]->[4] = 'None';
$stringRes->[1030]->[5] = 'No Figure';
$stringRes->[1030]->[6] = 'No Actor';
$stringRes->[1032]->[1] = 'Pose.plb';
$stringRes->[1032]->[2] = 'Body.blb';
$stringRes->[1032]->[3] = 'Light.llb';
$stringRes->[1032]->[4] = 'Camera.clb';
$stringRes->[1032]->[5] = 'poserTemp.';
$stringRes->[1032]->[6] = 'Poser.ini';
$stringRes->[1032]->[7] = '.bump';
$stringRes->[1032]->[8] = 'Poser Movie';
$stringRes->[1032]->[9] = 'Runtime\\Props\\ball.prp';
$stringRes->[1032]->[10] = 'Runtime\\Props\\box.prp';
$stringRes->[1032]->[11] = 'Runtime\\Props\\cane.prp';
$stringRes->[1032]->[12] = 'Runtime\\Props\\stairs.prp';
$stringRes->[1032]->[13] = 'Runtime\\Textures\\';
$stringRes->[1032]->[14] = 'Runtime\\Props\\cone.prp';
$stringRes->[1032]->[15] = 'Runtime\\Props\\cyl.prp';
$stringRes->[1032]->[16] = 'Runtime\\Props\\square.prp';
$stringRes->[1032]->[17] = 'Runtime\\Props\\torus.prp';
$stringRes->[1032]->[18] = 'Runtime\\Figures\\maleOrig.figure';
$stringRes->[1032]->[19] = 'Runtime\\Figures\\maleNudeHi.figure';
$stringRes->[1032]->[20] = 'Runtime\\Figures\\maleNudeLo.figure';
$stringRes->[1032]->[21] = 'Runtime\\Figures\\maleSuitHi.figure';
$stringRes->[1032]->[22] = 'Runtime\\Figures\\maleSuitLo.figure';
$stringRes->[1032]->[23] = 'Runtime\\Figures\\maleCasHi.figure';
$stringRes->[1032]->[24] = 'Runtime\\Figures\\maleCasLo.figure';
$stringRes->[1032]->[25] = 'Runtime\\Figures\\maleSkeleton.figure';
$stringRes->[1032]->[26] = 'Runtime\\Figures\\maleStick.figure';
$stringRes->[1032]->[27] = 'Runtime\\Figures\\femaleOrig.figure';
$stringRes->[1032]->[28] = 'Runtime\\Figures\\femaleNudeHi.figure';
$stringRes->[1032]->[29] = 'Runtime\\Figures\\femaleNudeLo.figure';
$stringRes->[1032]->[30] = 'Runtime\\Figures\\femaleSuitHi.figure';
$stringRes->[1032]->[31] = 'Runtime\\Figures\\femaleSuitLo.figure';
$stringRes->[1032]->[32] = 'Runtime\\Figures\\femaleCasHi.figure';
$stringRes->[1032]->[33] = 'Runtime\\Figures\\femaleCasLo.figure';
$stringRes->[1032]->[34] = 'Runtime\\Figures\\femaleSkeleton.figure';
$stringRes->[1032]->[35] = 'Runtime\\Figures\\femaleStick.figure';
$stringRes->[1032]->[36] = 'Runtime\\Figures\\childNudeHi.figure';
$stringRes->[1032]->[37] = 'Runtime\\Figures\\childNudeLo.figure';
$stringRes->[1032]->[38] = 'Runtime\\Figures\\childCasHi.figure';
$stringRes->[1032]->[39] = 'Runtime\\Figures\\childCasLo.figure';
$stringRes->[1032]->[40] = 'Runtime\\Figures\\childStick.figure';
$stringRes->[1032]->[41] = 'Runtime\\Figures\\default.figure';
$stringRes->[1032]->[42] = 'Runtime\\Figures\\manikin.figure';
$stringRes->[1032]->[43] = 'Runtime\\Scripts\\poser1SetTemplate';
$stringRes->[1032]->[44] = 'Runtime\\Scripts\\camerasAndLights';
$stringRes->[1032]->[45] = 'Runtime\\Scripts\\status45.MooV';
$stringRes->[1032]->[46] = 'Runtime\\Libraries\\';
$stringRes->[1032]->[47] = 'Runtime\\Libraries\\pose\\';
$stringRes->[1032]->[48] = 'Runtime\\Libraries\\camera\\';
$stringRes->[1032]->[49] = 'Runtime\\Libraries\\light\\';
$stringRes->[1032]->[50] = 'Runtime\\Libraries\\character\\';
$stringRes->[1032]->[51] = 'Runtime\\Figures\\figureLimits.include';
$stringRes->[1032]->[52] = 'poser3.hlp';
$stringRes->[1032]->[53] = 'Runtime\\Figures\\maleCommon.include';
$stringRes->[1032]->[54] = 'Runtime\\Figures\\figureCommon.include';
$stringRes->[1032]->[55] = 'Runtime\\Figures\\defaultMaterial';
$stringRes->[1032]->[56] = 'NewFigures';
$stringRes->[1032]->[57] = 'Runtime\\Libraries\\hand\\';
$stringRes->[1032]->[58] = 'Runtime\\Libraries\\face\\';
$stringRes->[1032]->[59] = 'Runtime\\Libraries\\hair\\';
$stringRes->[1032]->[60] = 'Runtime\\Libraries\\props\\';
$stringRes->[1032]->[61] = 'Hands.plb';
$stringRes->[1032]->[62] = 'Faces.plb';
$stringRes->[1032]->[63] = 'Hair.plb';
$stringRes->[1032]->[64] = 'Props.plb';
$stringRes->[1032]->[65] = 'Runtime\\prefs\\previousState.pz3';
$stringRes->[1032]->[66] = 'Runtime\\prefs\\preferredState.pz3';
$stringRes->[1032]->[67] = 'Runtime\\Prefs\\';
$stringRes->[1032]->[68] = 'Runtime\\textures\\Poser 3 Textures\\';
$stringRes->[1032]->[69] = 'Runtime\\Plugins\\';
$stringRes->[1032]->[70] = 'Runtime\\dots';
$stringRes->[1032]->[71] = 'Runtime\\dots\\cameraDot_%ld.cm2';
$stringRes->[1032]->[72] = 'Runtime\\dots\\poseDot_%ld.pz2';
$stringRes->[1032]->[73] = 'Runtime\\dots\\uiDot_%ld_%dx%d.ui2';
$stringRes->[1032]->[74] = '0 PDF Help File - Not used, See Win String Table ID 3501, 3502';
$stringRes->[1032]->[75] = 'PoserHelp.pdf - Not used, See Win String Table ID 3501, 3502';
$stringRes->[1032]->[76] = 'Runtime\\Reflection Maps\\';
$stringRes->[1032]->[77] = 'Runtime\\Textures\\Poser 4 Textures\\';
$stringRes->[1033]->[1] = '104 width';
$stringRes->[1033]->[2] = '14 height';
$stringRes->[1033]->[3] = '140 pinX';
$stringRes->[1033]->[4] = '17 pinY';
$stringRes->[1033]->[5] = 'Down Arrow';
$stringRes->[1033]->[6] = '124 x';
$stringRes->[1033]->[7] = '12 y';
$stringRes->[1034]->[1] = '80 width';
$stringRes->[1034]->[2] = '20 height';
$stringRes->[1034]->[3] = '40 pinX';
$stringRes->[1034]->[4] = '22 pinY';
$stringRes->[1034]->[5] = 'Down Arrow';
$stringRes->[1034]->[6] = '24 x';
$stringRes->[1034]->[7] = '12 y';
$stringRes->[1035]->[1] = 'Rendering shadow map for Light 1 ...';
$stringRes->[1035]->[2] = 'Rendering shadow map for Light 2 ...';
$stringRes->[1035]->[3] = 'Rendering shadow map for Light 3 ...';
$stringRes->[1035]->[4] = 'Rendering scene ...';
$stringRes->[1035]->[5] = 'Writing Quicktime Movie: Frame';
$stringRes->[1035]->[6] = 'Writing image file: Frame';
$stringRes->[1035]->[7] = 'Writing AVI Movie: Frame';
$stringRes->[1035]->[8] = 'Writing TIFF file: Frame';
$stringRes->[1035]->[9] = 'Writing Bitmap file: Frame';
$stringRes->[1035]->[10] = 'Rendering shadow map for';
$stringRes->[1035]->[11] = 'Heirarchy Conversion';
$stringRes->[1036]->[1] = 'Right Leg';
$stringRes->[1036]->[2] = 'Left Leg';
$stringRes->[1036]->[3] = 'Right Arm';
$stringRes->[1036]->[4] = 'Left Arm';
$stringRes->[1037]->[1] = 'Relaxed';
$stringRes->[1037]->[2] = 'Cupped';
$stringRes->[1037]->[3] = 'Limp';
$stringRes->[1037]->[4] = 'Quirky relaxed';
$stringRes->[1037]->[5] = 'Greetings';
$stringRes->[1037]->[6] = 'Flat';
$stringRes->[1037]->[7] = 'Coupled';
$stringRes->[1037]->[8] = 'Reach';
$stringRes->[1037]->[9] = 'Taut';
$stringRes->[1037]->[10] = 'Spread';
$stringRes->[1037]->[11] = 'Push';
$stringRes->[1037]->[12] = 'Scratch';
$stringRes->[1037]->[13] = 'Scrape';
$stringRes->[1037]->[14] = 'Gnarled';
$stringRes->[1037]->[15] = 'Fist';
$stringRes->[1037]->[16] = 'Point';
$stringRes->[1037]->[17] = 'Gun Point';
$stringRes->[1037]->[18] = 'Peace';
$stringRes->[1037]->[19] = 'Pinky Point';
$stringRes->[1037]->[20] = 'OK';
$stringRes->[1038]->[1] = 'Pose Sets';
$stringRes->[1038]->[2] = 'Male Figures';
$stringRes->[1038]->[3] = 'Light Sets';
$stringRes->[1038]->[4] = 'Camera Sets';
$stringRes->[1039]->[1] = '1';
$stringRes->[1039]->[2] = '9';
$stringRes->[1039]->[3] = '3';
$stringRes->[1040]->[1] = '°';
$stringRes->[1040]->[2] = '°';
$stringRes->[1041]->[1] = '4';
$stringRes->[1041]->[2] = '9';
$stringRes->[1042]->[1] = '3';
$stringRes->[1042]->[2] = '10';
$stringRes->[1043]->[1] = 'Size:';
$stringRes->[1043]->[2] = 'x';
$stringRes->[1044]->[1] = '102';
$stringRes->[1045]->[1] = '10';
$stringRes->[1046]->[1] = '10';
$stringRes->[1047]->[1] = '8';
$stringRes->[1047]->[2] = '11';
$stringRes->[1048]->[1] = '10';
$stringRes->[1052]->[9] = 'Runtime\\Geometries\\props\\ball.obj';
$stringRes->[1052]->[10] = 'Runtime\\Geometries\\props\\box.obj';
$stringRes->[1052]->[11] = 'Runtime\\Geometries\\props\\cane.obj';
$stringRes->[1052]->[12] = 'Runtime\\Geometries\\props\\stairs.obj';
$stringRes->[1052]->[14] = 'Runtime\\Geometries\\props\\cone.obj';
$stringRes->[1052]->[15] = 'Runtime\\Geometries\\props\\cylTex.obj';
$stringRes->[1052]->[16] = 'Runtime\\Geometries\\props\\square.obj';
$stringRes->[1052]->[17] = 'Runtime\\Geometries\\props\\torusThin.obj';
$stringRes->[1052]->[18] = 'Runtime\\Geometries\\maleOrig\\maleOrig.obj';
$stringRes->[1052]->[19] = 'Runtime\\Geometries\\maleNudeHi\\maleNudeHi.obj';
$stringRes->[1052]->[20] = 'Runtime\\Geometries\\maleNudeLo\\maleNudeLo.obj';
$stringRes->[1052]->[21] = 'Runtime\\Geometries\\maleSuitHi\\maleSuitHi.obj';
$stringRes->[1052]->[22] = 'Runtime\\Geometries\\maleSuitLo\\maleSuitLo.obj';
$stringRes->[1052]->[23] = 'Runtime\\Geometries\\maleCasHi\\maleCasHi.obj';
$stringRes->[1052]->[24] = 'Runtime\\Geometries\\maleCasLo\\maleCasLo.obj';
$stringRes->[1052]->[25] = 'Runtime\\Geometries\\maleSkeleton\\maleSkeleton.obj';
$stringRes->[1052]->[26] = 'Runtime\\Geometries\\maleStick\\maleStick.obj';
$stringRes->[1052]->[27] = 'Runtime\\Geometries\\femaleOrig\\femaleOrig.obj';
$stringRes->[1052]->[28] = 'Runtime\\Geometries\\femaleNudeHi\\femaleNudeHi.obj';
$stringRes->[1052]->[29] = 'Runtime\\Geometries\\femaleNudeLo\\femaleNudeLo.obj';
$stringRes->[1052]->[30] = 'Runtime\\Geometries\\femaleSuitHi\\femaleSuitHi.obj';
$stringRes->[1052]->[31] = 'Runtime\\Geometries\\femaleSuitLo\\femaleSuitLo.obj';
$stringRes->[1052]->[32] = 'Runtime\\Geometries\\femaleCasHi\\femaleCasHi.obj';
$stringRes->[1052]->[33] = 'Runtime\\Geometries\\femaleCasLo\\femaleCasLo.obj';
$stringRes->[1052]->[34] = 'Runtime\\Geometries\\femaleSkeleton\\femaleSkeleton.obj';
$stringRes->[1052]->[35] = 'Runtime\\Geometries\\femaleStick\\femaleStick.obj';
$stringRes->[1052]->[36] = 'Runtime\\Geometries\\childNudeHi\\childNudeHi.obj';
$stringRes->[1052]->[37] = 'Runtime\\Geometries\\childNudeLo\\childNudeLo.obj';
$stringRes->[1052]->[38] = 'Runtime\\Geometries\\childCasHi\\childCasHi.obj';
$stringRes->[1052]->[39] = 'Runtime\\Geometries\\childCasLo\\childCasLo.obj';
$stringRes->[1052]->[40] = 'Runtime\\Geometries\\childStick\\childStick.obj';
$stringRes->[1052]->[42] = 'Runtime\\Geometries\\manikin\\manikin.obj';

sub GetStringRes {
    my ($i1, $i2) = @_;
    if (exists $stringRes->[$i1]) {
        if (exists $stringRes->[$i1]->[$i2]) {
            return $stringRes->[$i1]->[$i2];
        }
        else {
            if (lc $emulation eq 'poser') {
                return '';
            }
            elsif (lc $emulation eq 'verbose') {
                return "No value at subaddress $i2 of address $i1";
            }
            return undef;
        }
    }
    else {
        if (lc $emulation eq 'poser') {
            return "GetStringRes($i1, $i2)";
        }
        elsif (lc $emulation eq 'verbose') {
            return "No values at address $i1";
        }
        return undef;
    }
}

sub ParseStringRes {
    my @strings = @_;
    for my $string (@strings) {
        $string =~ s/GetStringRes\(\s*(\d+)\s*,\s*(\d+)\s*\)/GetStringRes($1, $2)/ge;
    }
    return wantarray ? @strings : "@{[@strings]}";
}

1;
=head1 NAME

Model3D::Poser::GetStringRes - Perl extension to emulate the GetStringRes() function called in the Poser 3d application

=head1 SYNOPSIS

  use Model3D::Poser::GetStringRes;
  my $stringVal = GetStringRes(1024, 1);
  print $stringVal;

  # prints "Body";

  use Model3D::Poser::GetStringRes (':all');
  my $string = "            name GetStringRes(1024, 1)";
  my $converted = ParseStringRes($string);
  print $converted

  # prints "            name Body";

=head1 DESCRIPTION

Model3D::Poser::GetStringRes duplicates as closely as reasonable the
functionality of the GetStringRes function used in the Poser program,
from, depending on when, Aldus, Metacreations, Curious Labs, E-Frontier,
or (at the time of this module being written) Smith Micro.

This is not a locale-sensitive module because I don't know these strings
in any language besides English, so I couldn't fill them in anyway. of
course, this is ironic because the reason this function exists in Poser is
to support multiple languages in source files.

By default, if GetStringRes is called on an address pair that does not
have a definition in the strings matrix, or does not exist at all, it will
return undef.

To modify this behaviour, set $Model3D::Poser::GetStringRes::emulation
to either 'poser' or 'verbose'.

If the variable is set to 'poser' this module will attempt to emulate as
closely as possible the actual behaviour of Poser, which is to return the
entire "GetStringRes(x, y)" string if x is not defined, or to return an
empty string if x is defined but y is not.

The one aspect that cannot be emulated (and you probably don't want it to)
is causing your script to behave erratically if x index 1031 is asked for,
which Poser does (in Poser, using, e.g. GetStringRes(1031, 1) in an actor,
prop, or whatnot will cause that prop to refuse to fully load, but also not
completely not-load, which will lead to the source file being locked, an
actor or prop in the list, and an inability to delete it or completely select
it). The fact that it does not emulate this bug exactly should be understood
to be a good feature, not a shortcoming.

If emulation is se to 'verbose', ReadScript will return a verbose string
explaining the missing value.

Emulation type names are not case sensitive. 'Verbose', 'verbose', 'VERBOSE',
and 'vErBOsE' all work the same.

ParseStringRes uses GetStringRes internally, so changes to the emulation
variable will affect this method as well.

ParseStringRes is not exported by default. GetStringRes is.

This module is not designed to function in an object-oriented manner. It merely
exports functions.

=head2 EXPORT

GetStringRes() -- See above


=head1 SEE ALSO

Lemurtek and  Bloodsong's original GSR Lookup page.

http://www.3dmenagerie.com/goodies/tut/gsr.htm

Rob Whisenant's appears to be offline, but as a Flash page with no
Copy-Paste capacity, it was of limited use anyway.

http://www.whatever3d.com
http://www.xfx3d.net

=head1 AUTHOR

Dodger, E<lt>dodger@whatever3d.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by XFX Publishing, LLC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.006 or,
at your option, any later version of Perl 5 you may have available.

=head1 GOOD INTENTIONS FOR FUTURE DAYS

These will almost definitely never happen because this does all I need it to
right now. However, I recognise that the following things would be nice, and
bid anyone who wants to update this welcome to do so:

* Locale support (or at least the capability thereof)
* DAZ|Studio emulation (if different than Poser -- I'm not sure, really)
* Reverse replacement lookups. However, this would be complicated, because
if a Poser source file can only have these in string areas -- names, files,
and the like. Control directives cannot be replaced with a GetStringRes()
call. On the other hand, they don't have much opportunity to show up in
the wrong places -- except IDs (like GROUND, UNIVERSE, etc) -- which I am
not sure if can be replaced with a GetStringRes() call or not. Haven't
tried it.

=cut
