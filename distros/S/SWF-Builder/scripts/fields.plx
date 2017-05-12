#!/usr/bin/perl

use strict;
use SWF::Builder;

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, 400, 200], BackgroundColor => 'ffffff');
$m->compress(1);

my $fp = $ENV{SYSTEMROOT}.'/fonts';
my $font = $m->new_font("$fp/arial.ttf");
#$font->add_glyph("\x20", "\x7f");

$m->new_dynamic_text($font, 'login:')
	->place->moveto(20,20);
$m->new_input_field
	->place->moveto(90,20);
$m->new_dynamic_text($font, 'password:')
	->place->moveto(20,60);
$m->new_password_field(8)
	->place->moveto(90,60);
$m->new_dynamic_text($font, 'memo:')
	->place->moveto(20,100);
$m->new_text_area(280,80)
	->place->moveto(90,100);
$m->save('fields.swf');


