#!/usr/bin/perl -w

use strict;
use lib qw(./lib ../lib t/lib);
use Test::Simple tests => 11;
#use Data::Dumper;
use PostScript::Simple;

my $f = "xtest-b.ps";
my $t = new PostScript::Simple(landscape => 0,
            eps => 0,
            papersize => "a4",
            colour => 1,
            clip => 0,
            units => "mm");

ok( $t );

$t->newpage(-1);

$t->line(10,10, 10,50);
$t->setlinewidth(8);
$t->line(90,10, 90,50);
$t->linextend(40,90);
$t->setcolour("brightred");
$t->circle({filled=>1}, 40, 90, 30);
$t->setcolour("darkgreen");
$t->setlinewidth(0.1);
for (my $i = 0; $i < 360; $i += 20) {
  $t->polygon({offset=>[0,0], rotate=>[$i,70,90], filled=>0}, 40,90, 69,92, 75,84);
}

$t->setlinewidth("thin");
$t->setcolour("darkgreen");
$t->box(20, 10, 80, 20);
$t->setcolour("grey30");
$t->box({filled=>1}, 20, 30, 80, 40);
$t->setcolour("grey10");
$t->setfont("Bookman", 12);
$t->text(5,5, "Matthew");

$t->newpage;
$t->line((10, 20), (30, 40));
$t->linextend(60, 50);

$t->line(10,12, 20,12);
$t->polygon(10,10, 20,10);

$t->setcolour("grey90");
$t->polygon({offset=>[5,5], filled=>1}, 10,10, 15,20, 25,20, 30,10, 15,15, 10,10, 0);
$t->setcolour("black");
$t->polygon({offset=>[10,10], rotate=>[45,20,20]}, 10,10, 15,20, 25,20, 30,10, 15,15, 10,10, 1);

$t->line((0, 100), (100, 0), (255, 0, 0));

$t->newpage(30);

for (my $i = 12; $i < 80; $i += 2) {
  $t->setcolour($i*3, 0, 0);
  $t->box({filled=>1}, $i - 2, 10, $i, 40);
}

$t->line((40, 30), (30, 10));
$t->linextend(60, 0);
$t->line((0, 100), (100, 0),(0, 255, 0));

$t->output( $f );
#$t->output( "x" );

ok( -e $f );

open( FILE, $f ) or die("Can't open $f: $!");
$/ = undef;
my $lines = <FILE>;
close FILE;

ok( $lines =~ m/%%LanguageLevel: 1/s );
ok( $lines =~ m/%%DocumentMedia: A4 595.27559 841.88976 0 \( \) \( \)/s );
ok( $lines =~ m/%%Orientation: Portrait/s );
ok( $lines =~ m/%%Pages: 3/s );

ok( index($lines, "%!PS-Adobe-3.0\n") == 0 );
my ( $prolog ) = ( $lines =~ m/%%BeginResource: PostScript::Simple-REENCODEFONT\n(.*)%%EndResource/s );
#print STDERR "\n>>>$prolog<<<\n";

ok( $prolog );
ok( $prolog eq PROLOG());

my ( $body ) = ( $lines =~ m/%%EndProlog\n(.*)%%EOF/s );
ok( $body );
ok( $body eq BODY());

#print STDERR "\n>>>$body<<<\n";

### Subs

sub PROLOG {
	return q[/STARTDIFFENC { mark } bind def
/ENDDIFFENC { 

% /NewEnc BaseEnc STARTDIFFENC number or glyphname ... ENDDIFFENC -
	counttomark 2 add -1 roll 256 array copy
	/TempEncode exch def

	% pointer for sequential encodings
	/EncodePointer 0 def
	{
		% Get the bottom object
		counttomark -1 roll
		% Is it a mark?
		dup type dup /marktype eq {
			% End of encoding
			pop pop exit
		} {
			/nametype eq {
			% Insert the name at EncodePointer 

			% and increment the pointer.
			TempEncode EncodePointer 3 -1 roll put
			/EncodePointer EncodePointer 1 add def
			} {
			% Set the EncodePointer to the number
			/EncodePointer exch def
			} ifelse
		} ifelse
	} loop

	TempEncode def
} bind def

% Define ISO Latin1 encoding if it doesnt exist
/ISOLatin1Encoding where {
%	(ISOLatin1 exists!) =
	pop
} {
	(ISOLatin1 does not exist, creating...) =
	/ISOLatin1Encoding StandardEncoding STARTDIFFENC
		144 /dotlessi /grave /acute /circumflex /tilde 
		/macron /breve /dotaccent /dieresis /.notdef /ring 
		/cedilla /.notdef /hungarumlaut /ogonek /caron /space 
		/exclamdown /cent /sterling /currency /yen /brokenbar 
		/section /dieresis /copyright /ordfeminine 
		/guillemotleft /logicalnot /hyphen /registered 
		/macron /degree /plusminus /twosuperior 
		/threesuperior /acute /mu /paragraph /periodcentered 
		/cedilla /onesuperior /ordmasculine /guillemotright 
		/onequarter /onehalf /threequarters /questiondown 
		/Agrave /Aacute /Acircumflex /Atilde /Adieresis 
		/Aring /AE /Ccedilla /Egrave /Eacute /Ecircumflex 
		/Edieresis /Igrave /Iacute /Icircumflex /Idieresis 
		/Eth /Ntilde /Ograve /Oacute /Ocircumflex /Otilde 
		/Odieresis /multiply /Oslash /Ugrave /Uacute 
		/Ucircumflex /Udieresis /Yacute /Thorn /germandbls 
		/agrave /aacute /acircumflex /atilde /adieresis 
		/aring /ae /ccedilla /egrave /eacute /ecircumflex 
		/edieresis /igrave /iacute /icircumflex /idieresis 
		/eth /ntilde /ograve /oacute /ocircumflex /otilde 
		/odieresis /divide /oslash /ugrave /uacute 
		/ucircumflex /udieresis /yacute /thorn /ydieresis
	ENDDIFFENC
} ifelse

% Name: Re-encode Font
% Description: Creates a new font using the named encoding. 

/REENCODEFONT { % /Newfont NewEncoding /Oldfont
	findfont dup length 4 add dict
	begin
		{ % forall
			1 index /FID ne 
			2 index /UniqueID ne and
			2 index /XUID ne and
			{ def } { pop pop } ifelse
		} forall
		/Encoding exch def
		% defs for DPS
		/BitmapWidths false def
		/ExactSize 0 def
		/InBetweenSize 0 def
		/TransformedChar 0 def
		currentdict
	end
	definefont pop
} bind def

% Reencode the std fonts: 
/Courier-iso ISOLatin1Encoding /Courier REENCODEFONT
/Courier-Bold-iso ISOLatin1Encoding /Courier-Bold REENCODEFONT
/Courier-BoldOblique-iso ISOLatin1Encoding /Courier-BoldOblique REENCODEFONT
/Courier-Oblique-iso ISOLatin1Encoding /Courier-Oblique REENCODEFONT
/Helvetica-iso ISOLatin1Encoding /Helvetica REENCODEFONT
/Helvetica-Bold-iso ISOLatin1Encoding /Helvetica-Bold REENCODEFONT
/Helvetica-BoldOblique-iso ISOLatin1Encoding /Helvetica-BoldOblique REENCODEFONT
/Helvetica-Oblique-iso ISOLatin1Encoding /Helvetica-Oblique REENCODEFONT
/Times-Roman-iso ISOLatin1Encoding /Times-Roman REENCODEFONT
/Times-Bold-iso ISOLatin1Encoding /Times-Bold REENCODEFONT
/Times-BoldItalic-iso ISOLatin1Encoding /Times-BoldItalic REENCODEFONT
/Times-Italic-iso ISOLatin1Encoding /Times-Italic REENCODEFONT
/Symbol-iso ISOLatin1Encoding /Symbol REENCODEFONT
%%EndResource
%%BeginResource: PostScript::Simple-box
/box {
  newpath 3 copy pop exch 4 copy pop pop
  8 copy pop pop pop pop exch pop exch
  3 copy pop pop exch moveto lineto
  lineto lineto pop pop pop pop closepath
} bind def
%%EndResource
%%BeginResource: PostScript::Simple-circle
/circle {newpath 0 360 arc closepath} bind def
%%EndResource
%%BeginResource: PostScript::Simple-rotabout
/rotabout {
  3 copy pop translate rotate exch
  0 exch sub exch 0 exch sub translate
} def
];
}

sub BODY {
	return q[%%BeginSetup
/ubp {} def
/umm {72 mul 25.4 div} def
ll 2 ge { << /PageSize [ 595.27559 841.88976 ] /ImagingBBox null >> setpagedevice } if
%%EndSetup
%%Page: -1 1
%%BeginPageSetup
/pagelevel save def
%%EndPageSetup
newpath
10 umm 10 umm moveto
10 umm 50 umm lineto stroke
8 umm setlinewidth
newpath
90 umm 10 umm moveto
90 umm 50 umm lineto
40 umm 90 umm lineto stroke
1 0 0 setrgbcolor
40 umm 90 umm 30 umm circle fill
0 0.49804 0 setrgbcolor
0.1 umm setlinewidth
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
gsave 70 umm 90 umm 20 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 40 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 60 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 80 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 100 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 120 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 140 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 160 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 180 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 200 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 220 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 240 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 260 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 280 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 300 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 320 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
gsave 70 umm 90 umm 340 rotabout
newpath
40 umm 90 umm moveto
69 umm 92 umm lineto 75 umm 84 umm lineto stroke
grestore
0.4 ubp setlinewidth
0 0.49804 0 setrgbcolor
20 umm 10 umm 80 umm 20 umm box stroke
0.29804 0.29804 0.29804 setrgbcolor
20 umm 30 umm 80 umm 40 umm box fill
0.09804 0.09804 0.09804 setrgbcolor
/Bookman findfont 12 scalefont setfont
newpath
5 umm 5 umm moveto
(Matthew)   show stroke 
%%PageTrailer
pagelevel restore
showpage
%%Page: -2 2
%%BeginPageSetup
/pagelevel save def
%%EndPageSetup
newpath
10 umm 20 umm moveto
30 umm 40 umm lineto
60 umm 50 umm lineto stroke
newpath
10 umm 12 umm moveto
20 umm 12 umm lineto stroke
newpath
10 umm 10 umm moveto
20 umm 10 umm lineto stroke
0.89804 0.89804 0.89804 setrgbcolor
gsave 5 umm 5 umm translate
newpath
10 umm 10 umm moveto
15 umm 20 umm lineto 25 umm 20 umm lineto 30 umm 10 umm lineto 15 umm 15 umm lineto 10 umm 10 umm lineto fill
grestore
0 0 0 setrgbcolor
gsave 10 umm 10 umm translate
20 umm 20 umm 45 rotabout
newpath
10 umm 10 umm moveto
15 umm 20 umm lineto 25 umm 20 umm lineto 30 umm 10 umm lineto 15 umm 15 umm lineto 10 umm 10 umm lineto stroke
grestore
1 0 0 setrgbcolor
newpath
0 umm 100 umm moveto
100 umm 0 umm lineto stroke
%%PageTrailer
pagelevel restore
showpage
%%Page: 30 3
%%BeginPageSetup
/pagelevel save def
%%EndPageSetup
0.14118 0 0 setrgbcolor
10 umm 10 umm 12 umm 40 umm box fill
0.16471 0 0 setrgbcolor
12 umm 10 umm 14 umm 40 umm box fill
0.18824 0 0 setrgbcolor
14 umm 10 umm 16 umm 40 umm box fill
0.21176 0 0 setrgbcolor
16 umm 10 umm 18 umm 40 umm box fill
0.23529 0 0 setrgbcolor
18 umm 10 umm 20 umm 40 umm box fill
0.25882 0 0 setrgbcolor
20 umm 10 umm 22 umm 40 umm box fill
0.28235 0 0 setrgbcolor
22 umm 10 umm 24 umm 40 umm box fill
0.30588 0 0 setrgbcolor
24 umm 10 umm 26 umm 40 umm box fill
0.32941 0 0 setrgbcolor
26 umm 10 umm 28 umm 40 umm box fill
0.35294 0 0 setrgbcolor
28 umm 10 umm 30 umm 40 umm box fill
0.37647 0 0 setrgbcolor
30 umm 10 umm 32 umm 40 umm box fill
0.4 0 0 setrgbcolor
32 umm 10 umm 34 umm 40 umm box fill
0.42353 0 0 setrgbcolor
34 umm 10 umm 36 umm 40 umm box fill
0.44706 0 0 setrgbcolor
36 umm 10 umm 38 umm 40 umm box fill
0.47059 0 0 setrgbcolor
38 umm 10 umm 40 umm 40 umm box fill
0.49412 0 0 setrgbcolor
40 umm 10 umm 42 umm 40 umm box fill
0.51765 0 0 setrgbcolor
42 umm 10 umm 44 umm 40 umm box fill
0.54118 0 0 setrgbcolor
44 umm 10 umm 46 umm 40 umm box fill
0.56471 0 0 setrgbcolor
46 umm 10 umm 48 umm 40 umm box fill
0.58824 0 0 setrgbcolor
48 umm 10 umm 50 umm 40 umm box fill
0.61176 0 0 setrgbcolor
50 umm 10 umm 52 umm 40 umm box fill
0.63529 0 0 setrgbcolor
52 umm 10 umm 54 umm 40 umm box fill
0.65882 0 0 setrgbcolor
54 umm 10 umm 56 umm 40 umm box fill
0.68235 0 0 setrgbcolor
56 umm 10 umm 58 umm 40 umm box fill
0.70588 0 0 setrgbcolor
58 umm 10 umm 60 umm 40 umm box fill
0.72941 0 0 setrgbcolor
60 umm 10 umm 62 umm 40 umm box fill
0.75294 0 0 setrgbcolor
62 umm 10 umm 64 umm 40 umm box fill
0.77647 0 0 setrgbcolor
64 umm 10 umm 66 umm 40 umm box fill
0.8 0 0 setrgbcolor
66 umm 10 umm 68 umm 40 umm box fill
0.82353 0 0 setrgbcolor
68 umm 10 umm 70 umm 40 umm box fill
0.84706 0 0 setrgbcolor
70 umm 10 umm 72 umm 40 umm box fill
0.87059 0 0 setrgbcolor
72 umm 10 umm 74 umm 40 umm box fill
0.89412 0 0 setrgbcolor
74 umm 10 umm 76 umm 40 umm box fill
0.91765 0 0 setrgbcolor
76 umm 10 umm 78 umm 40 umm box fill
newpath
40 umm 30 umm moveto
30 umm 10 umm lineto
60 umm 0 umm lineto stroke
0 1 0 setrgbcolor
newpath
0 umm 100 umm moveto
100 umm 0 umm lineto stroke
%%PageTrailer
pagelevel restore
showpage
];
}


