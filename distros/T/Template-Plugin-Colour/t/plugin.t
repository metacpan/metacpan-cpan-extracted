#============================================================= -*-perl-*-
#
# t/plugin.t
#
# Test the TT plugin modules.
#
# Copyright (C) 2006-2012 Andy Wardley.  All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib ../lib );
use Template::Test;

test_expect(\*DATA, undef, { ttv => $Template::VERSION });

__DATA__

-- test --
[% USE rgb = Colour('#102030') -%]
 src: [% rgb.red %] / [% rgb.green %] / [% rgb.blue %]
[% hsv = rgb.hsv; rgb = hsv.rgb -%]
 rgb: [% rgb.red %] / [% rgb.green %] / [% rgb.blue %]
 hsv: [% hsv.hue %] / [% hsv.sat %] / [% hsv.val %]
 rgb.join: [% rgb.join(', ') %]
 hsv.join: [% hsv.join(', ') %]
-- expect --
 src: 16 / 32 / 48
 rgb: 16 / 32 / 48
 hsv: 210 / 170 / 48
 rgb.join: 16, 32, 48
 hsv.join: 210, 170, 48

-- test --
[% USE rgb = Colour('#007f3f'); hsv = rgb.hsv -%]
 rgb: [% rgb.red %] / [% rgb.green %] / [% rgb.blue %]
 hsv: [% hsv.hue %] / [% hsv.sat %] / [% hsv.val %]
-- expect --
 rgb: 0 / 127 / 63
 hsv: 150 / 255 / 127


-- test -- 
[% USE col = Colour(17, 34, 51); "col: $col.hex" %]
-- expect --
col: 112233

-- test -- 
[% USE col = Colour('112233'); "col: $col.hex" %]
-- expect --
col: 112233

-- test -- 
[% USE col = Colour(17, 34, 51) -%]
[% col.0 %]/[% col.1 %]/[% col.2 %]
-- expect --
-- process --
[% IF ttv.match('^2\.14\w') or ttv > 2.14 -%]
17/34/51
[% ELSE -%]
//
[% END %]

-- test --
-- name Colour exception --
[% TRY;
     USE Colour(10, 20, 30, 40, 50, "I don't know", "what I am doing");
   CATCH;
     error;
   END
%]
-- expect --
Colour.RGB error - invalid rgb parameter(s): 10, 20, 30, 40, 50, I don't know, what I am doing

-- test --
-- name orange --
[% USE Colour;
   Colour.RGB('#FF7F00').hsv.join('/')
%]
-- expect --
30/255/255

-- test --
-- name orange --
[% USE Colour;
   Colour.HSV(30, 255, 255).rgb.hex
%]
-- expect --
ff7f00

-- test --
-- name none more black hsv --
[% USE hsv = Colour.HSV(0, 0, 0) -%]
hsv: [% hsv.join('/') %]
rgb: [% hsv.rgb.join('/') %]
hex: [% hsv.rgb.hex %]
-- expect --
hsv: 0/0/0
rgb: 0/0/0
hex: 000000

-- test --
-- name none more black rgb --
[% USE col = Colour.RGB(0, 0, 0) -%]
hex: [% col.hex %]
hsv: [% col.hsv.join('/') %]
rgb: [% col.hsv.rgb.join('/') %]
hex: [% col.hsv.rgb.hex %]
-- expect --
hex: 000000
hsv: 0/0/0
rgb: 0/0/0
hex: 000000


-- test --
-- name red and orange --
[% USE Colour;
   red    = Colour.RGB('#C00');
   orange = Colour.HSV(30, 255, 255);

   FOREACH col IN [red, orange] -%]
<span style="background-color: [% col.rgb.html %];">
  Sample Colour: [% col.rgb.html %]
</span>
[% END %]
-- expect --
<span style="background-color: #cc0000;">
  Sample Colour: #cc0000
</span>
<span style="background-color: #ff7f00;">
  Sample Colour: #ff7f00
</span>

-- test --
-- name I like orange --
[% USE Colour;
   orange = Colour.HSV(30, 255, 255);
-%]
<p style="color: [% orange.rgb.HTML %]">
   I like orange!
</p>
-- expect --
<p style="color: #FF7F00">
   I like orange!
</p>


-- test --
[% USE Colour;
   orange = Colour.HSV(30, 255, 255);
   light  = orange.copy( sat => 127 );   # FFBF80
   dark   = orange.copy( val => 127 );   # 7F3F00
   contrast = orange.copy( hue => 210 );   # 7F3F00
-%]
orange: [% orange.join('/') %]  [% orange.rgb.HTML %]
 light: [% light.join('/') %]  [% light.rgb.HTML %]
  dark: [% dark.join('/') %]  [% dark.rgb.HTML %]
  cont: [% contrast.join('/') %]  [% contrast.rgb.HTML %]
-- expect --
orange: 30/255/255  #FF7F00
 light: 30/127/255  #FFBF80
  dark: 30/255/127  #7F3F00
  cont: 210/255/255  #007FFF

-- test --
-- name sat to rgb --
[% USE hsv = Colour.HSV(210, 170, 48) -%]
 hsv: [% hsv.join('/') %]
 rgb: [% hsv.rgb.join('/') %]
 hex: [% hsv.rgb.hex %]
-- expect --
 hsv: 210/170/48
 rgb: 16/32/48
 hex: 102030

-- test --
-- name rgb to sat --
[% USE rgb = Colour.RGB(16, 32, 48) -%]
 rgb: [% rgb.join('/') %]
 hsv: [% rgb.hsv.join('/') %]
-- expect --
 rgb: 16/32/48
 hsv: 210/170/48

#-----------------------------------------------------------------------
# test American spelling of 'color'
#-----------------------------------------------------------------------

-- test --
[% USE Color( rgb => '#123456' ) -%]
col: [% Color.hex %]
-- expect --
col: 123456

-- test --
[% USE rgb = Color( rgb => '#0066b3' ) -%]
  red: [% rgb.red %]
green: [% rgb.green %]
 blue: [% rgb.blue %]
 grey: [% rgb.grey %]
  red: [% rgb.red(100) %]
  hex: [% rgb.hex %]
 html: [% rgb.html %]
-- expect --
  red: 0
green: 102
 blue: 179
 grey: 84
  red: 100
  hex: 6466b3
 html: #6466b3

-- test --
[% USE hsv = Color( hsv => [50, 100, 150] ) -%]
  hue: [% hsv.hue %]
  sat: [% hsv.sat %] / [% hsv.saturation %]
  val: [% hsv.val %] / [% hsv.value %]
-- expect --
  hue: 50
  sat: 100 / 100
  val: 150 / 150

-- test --
[% USE rgb = Color('#102030');
   hsv = rgb.hsv; rgb = hsv.rgb
-%]
 rgb: [% rgb.red %] / [% rgb.green %] / [% rgb.blue %]
 hsv: [% hsv.hue %] / [% hsv.sat %] / [% hsv.val %]
 rgb.join: [% rgb.join(', ') %]
 hsv.join: [% hsv.join(', ') %]
-- expect --
 rgb: 16 / 32 / 48
 hsv: 210 / 170 / 48
 rgb.join: 16, 32, 48
 hsv.join: 210, 170, 48

-- test -- 
[% USE col = Color(17, 34, 51); "col: $col.hex" %]
-- expect --
col: 112233

-- test -- 
[% USE col = Color('112233'); "col: $col.hex" %]
-- expect --
col: 112233

-- test -- 
[% USE col = Color(17, 34, 51) -%]
[% col.0 %]/[% col.1 %]/[% col.2 %]
-- expect --
-- process --
[% IF ttv.match('^2\.14\w') or ttv > 2.14 -%]
17/34/51
[% ELSE -%]
//
[% END %]

-- test --
-- name Color exception --
[% TRY;
     USE Color(10, 20, 30, 40, 50, "I do not know", "what I am doing");
   CATCH;
     error;
   END
%]
-- expect --
Colour.RGB error - invalid rgb parameter(s): 10, 20, 30, 40, 50, I do not know, what I am doing

-- test --
[% USE Colour;
   hsv = Colour.HSV(210, 170, 48) -%]
col: [% hsv.rgb.hex %]
-- expect --
col: 102030

-- test --
[% USE hsv = Colour( hsv = [210, 170, 48] ) -%]
col: [% hsv.rgb.hex %]
-- expect --
col: 102030

-- test --
[% USE hsv = Colour.HSV(210, 170, 48) -%]
col: [% hsv.rgb.hex %]
-- expect --
col: 102030

-- test --
[% USE hsv = Colour.HSV(hue=210, saturation=170, value=48) -%]
col: [% hsv.rgb.hex %]
-- expect --
col: 102030

-- test --
[% USE Colour -%]
  red: [% Colour.RGB('#c00').hsv.join('/') %]
green: [% Colour.RGB('#0c0').hsv.join('/') %]
 blue: [% Colour.RGB('#00c').hsv.join('/') %]
-- expect --
  red: 0/255/204
green: 120/255/204
 blue: 240/255/204


-- test --
-- name Colour.HSV exception --
[% TRY;
     USE Colour.HSV('I should not', 'be allowed to', 'operate a', 'computer');
   CATCH;
     error;
   END
%]
-- expect --
Colour.HSV error - invalid hsv parameter(s): I should not, be allowed to, operate a, computer



#------------------------------------------------------------------------
# Check 'Color' works as 'Colour' for y'all out there in the US of A.
#------------------------------------------------------------------------
-- test --

[% USE Color;
   hsv = Color.HSV(210, 170, 48) -%]
col: [% hsv.rgb.hex %]
-- expect --
col: 102030


-- test --
-- name Color.HSV exception --
[% TRY;
     USE Color.HSV('I should not', 'be allowed to', 'operate a', 'computer');
   CATCH;
     error;
   END
%]
-- expect --
Color.HSV error - invalid hsv parameter(s): I should not, be allowed to, operate a, computer



-- stop --
-- test --
-- name there and back again --
#------------------------------------------------------------------------
# NOTE: This test fails because the algorithm used to convert 
#       between RGB and HSV is not symmetrical.  That is, 
#       going RGB->HSV->RGB doesn not always return the colour
#       that you started with.  This is because we round components
#       to integers rather than floating point values.
#------------------------------------------------------------------------

[% USE Colour;
   numbers = [0, 15, 16, 47, 48, 63, 64, 127, 128, 191, 192, 255];
   numbers = [0, 63, 127, 255];
   failed = 0;
   FOREACH red IN numbers;
     FOREACH green IN numbers;
       FOREACH blue IN numbers;
         rgb = Colour.RGB(red, green, blue);
         hsv = rgb.hsv;
         out = hsv.rgb;
         hex = hsv.rgb.hex;
         UNLESS rgb.hex == hex; failed = 
           failed + 1;
           FILTER stderr;%]
[RGB:[% rgb.html %]] => [HSV:[% hsv.join('/') %]] => [RGB:[% hsv.rgb.html %]]
[%-        END;
         END;
       END;
     END;
   END
%]
[% failed ? "$failed tests failed" : 'all ok' %]
-- expect --
all ok


       
