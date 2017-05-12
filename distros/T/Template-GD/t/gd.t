#============================================================= -*-perl-*-
#
# t/gd.t
#
# Test the GD plugin.  Tests are based on the GD module tests.
#
# Written by Craig Barratt <craig@arraycomm.com>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: gd.t 6 2006-02-03 13:40:35Z abw $
# 
#========================================================================

use strict;
use lib qw( ../lib );
use Template;
use Template::Test;
$^W = 1;

eval "use GD;";

if ( $@ || $GD::VERSION < 1.20 ) {
    skip_all('GD module(s) not installed');
}

test_expect(\*DATA, { 
    FILTERS => {
        hex => \&hex_filter,
    }
});

#
# write text out in hex format.
#
sub hex_filter {
    my $text = shift;
    $text =~ s/(.)/sprintf("%02x", ord($1))/esg;
    $text =~ s/(.{70})/$1\n/g;
    return $text;
}

__END__

-- test --
[% FILTER replace('.');
    #
    # This is test2 from GD-1.xx/t/GD.t
    #
    USE gd_c = GD.Constants;
    USE im = GD.Image(300,300);
    white = im.colorAllocate(255, 255, 255);
    black = im.colorAllocate(0, 0, 0);
    red = im.colorAllocate(255, 0, 0);
    blue = im.colorAllocate(0,0,255);
    yellow = im.colorAllocate(255,250,205);
    USE brush = GD.Image(10,10);
    brush.colorAllocate(255,255,255); # white
    brush.colorAllocate(0,0,0);       # black
    brush.transparent(white);        # white is transparent
    brush.filledRectangle(0,0,5,2,black); # a black rectangle
    im.setBrush(brush);
    im.arc(100,100,100,150,0,360,gd_c.gdBrushed);
    USE poly = GD::Polygon;
    poly.addPt(30,30);
    poly.addPt(100,10);
    poly.addPt(190,290);
    poly.addPt(30,290);
    im.polygon(poly,gd_c.gdBrushed);
    im.fill(132,62,blue);
    im.fill(100,70,red);
    im.fill(40,40,yellow);
    im.interlaced(1);
    im.copy(im,150,150,20,20,50,50);
    im.copyResized(im,10,200,20,20,100,100,50,50);
   END; 
   out = im.png | hex;
   out.length > 6000 ? 'ok' : 'not ok'
-%]
-- expect --
ok

-- test --
[% FILTER replace('.');
    #
    # This is test3 from GD-1.xx/t/GD.t
    #
    USE im = GD.Image(100,50);
    black = im.colorAllocate(0, 0, 0);
    white = im.colorAllocate(255, 255, 255);
    red   = im.colorAllocate(255, 0, 0);
    blue  = im.colorAllocate(0,0,255);
    im.arc(50, 25, 98, 48, 0, 360, white);
    im.fill(50, 21, red);
   END;
    out = im.png | hex;
    out.length > 500 ? 'ok' : 'not ok'
-%]
-- expect --
ok

-- test --
[% FILTER replace('.');
    #
    # This is test4 from GD-1.xx/t/GD.t
    #
    USE im = GD.Image(225,180);
    black   = im.colorAllocate(0, 0, 0);
    white   = im.colorAllocate(255, 255, 255);
    red     = im.colorAllocate(255, 0, 0);
    blue    = im.colorAllocate(0,0,255);
    yellow  = im.colorAllocate(255,250,205);
    USE poly = GD.Polygon;
    poly.addPt(0,50);
    poly.addPt(25,25);
    poly.addPt(50,50);
    im.filledPolygon(poly,blue);
    poly.offset(100,100);
    im.filledPolygon(poly,red);
    poly.map(50,50,100,100,10,10,110,60);
    im.filledPolygon(poly,yellow);
    b = poly.bounds; b0 = b.0; b1 = b.1; b2 = b.2; b3 = b.3;
    poly.map(b0,b1,b2,b3,50,20,80,160);
    im.filledPolygon(poly,white);
   END; 
   out = im.png | hex;
   out.length > 1250 ? "ok" : "not ok"
-%]
-- expect --
ok
-- test --
[% FILTER replace('.');
    #
    # This is test5 from GD-1.xx/t/GD.t
    #
    USE gd_c = GD.Constants;
    USE im = GD.Image(300,300);
    white   = im.colorAllocate(255, 255, 255);
    black   = im.colorAllocate(0, 0, 0);
    red     = im.colorAllocate(255, 0, 0);
    blue    = im.colorAllocate(0,0,255);
    yellow  = im.colorAllocate(255,250,205);
    im.transparent(white);
    im.interlaced(1);
    USE brush = GD.Image(10,10);
    brush.colorAllocate(255,255,255);
    brush.colorAllocate(0,0,0);
    brush.transparent(white);
    brush.filledRectangle(0,0,5,2,black);
    im.string(gd_c.gdLargeFont,150,10,"Hello world!",red);
    im.string(gd_c.gdSmallFont,150,28,"Goodbye cruel world!",blue);
    im.stringUp(gd_c.gdTinyFont,280,250,"I'm climbing the wall!",black);
    im.charUp(gd_c.gdMediumBoldFont,280,280,"Q",black);
    im.setBrush(brush);
    im.arc(100,100,100,150,0,360,gd_c.gdBrushed);
    USE poly = GD.Polygon;
    poly.addPt(30,30);
    poly.addPt(100,10);
    poly.addPt(190,290);
    poly.addPt(30,290);
    im.polygon(poly,gd_c.gdBrushed);
    im.fill(132,62,blue);
    im.fill(100,70,red);
    im.fill(40,40,yellow);
  END;
  out = im.png | hex;
  out.length > 6500 ? 'ok' : 'not ok'
-%]
-- expect --
ok
