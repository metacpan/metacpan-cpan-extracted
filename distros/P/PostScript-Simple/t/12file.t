#!/usr/bin/perl -w

use strict;
use lib qw(./lib ../lib t/lib);
use Test::Simple tests => 3;
#use Data::Dumper;
use PostScript::Simple;

my $f = "xtest-c.ps";
my $p = new PostScript::Simple(papersize => "a4",
            colour => 1,
            units => "in",
            eps => 0,
            reencode => undef);

ok( $p );

# create a new page
$p->newpage;
    
# draw some lines and other shapes
$p->line(1,1, 1,4);
$p->linextend(2,4);
$p->box(1.5,1, 2,3.5);
$p->circle(2,2, 1);
    
# draw a rotated polygon in a different colour
$p->setcolour(0,100,200);
$p->polygon({rotate=>45}, 1,1, 1,2, 2,2, 2,1, 1,1);
    
# add some text in red
$p->setcolour("red", "blue");
$p->setcolour(255,0,0);
$p->setfont("Times-Roman", 20);
$p->text({rotate=>-37.5}, 1,1, "Hello");
    
# write the output to a file
$p->output( $f );

ok( -e $f );

open( FILE, $f ) or die("Can't open $f: $!");
my $lines;
while (<FILE>) {
	next if m/^%%/;
	$lines .= $_;
}
close FILE;

ok( $lines eq CANNED() );
#print STDERR "\n>>>$lines<<<\n";

###

sub CANNED {
return q[%!PS-Adobe-3.0
/ll 1 def systemdict /languagelevel known {
/ll languagelevel def } if
/box {
  newpath 3 copy pop exch 4 copy pop pop
  8 copy pop pop pop pop exch pop exch
  3 copy pop pop exch moveto lineto
  lineto lineto pop pop pop pop closepath
} bind def
/circle {newpath 0 360 arc closepath} bind def
/rotabout {
  3 copy pop translate rotate exch
  0 exch sub exch 0 exch sub translate
} def
/uin {72 mul} def
ll 2 ge { << /PageSize [ 595.27559 841.88976 ] /ImagingBBox null >> setpagedevice } if
/pagelevel save def
newpath
1 uin 1 uin moveto
1 uin 4 uin lineto
2 uin 4 uin lineto stroke
1.5 uin 1 uin 2 uin 3.5 uin box stroke
2 uin 2 uin 1 uin circle stroke
0 0.39216 0.78431 setrgbcolor
gsave 1 uin 1 uin 45 rotabout
newpath
1 uin 1 uin moveto
1 uin 2 uin lineto 2 uin 2 uin lineto 2 uin 1 uin lineto 1 uin 1 uin lineto stroke
grestore
(error: setcolour given invalid arguments: red, blue, undef
) print flush
1 0 0 setrgbcolor
/Times-Roman findfont 20 scalefont setfont
newpath
1 uin 1 uin moveto
(Hello)  -37.5 rotate   show stroke  37.5 rotate 
pagelevel restore
showpage
];
}

