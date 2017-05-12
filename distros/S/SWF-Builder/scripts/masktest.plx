#!/usr/bin/perl

use strict;
#use lib '/program/';

use encoding 'shift_jis';

use SWF::Builder;

my $fp = 'c:/winnt/fonts';
#my $fp = 'c:/windows/fonts';

my $m = SWF::Builder->new(FrameRate => 60, BackgroundColor => '000000');

my $font = $m->new_font("$fp/by______.ttf");  # Broadway
my $text = $m->new_static_text
    ->font($font)
    ->size(50)
    ->color('ffffff')
    ->text("SWF::Builder");
    ;
my @bbox = $text->get_bbox;
$m->FrameSize(0,0,$bbox[2]+20, $bbox[3]+20);
my $ti = $text->place_as_mask;
$ti->moveto(10,10);

my $s = $m->new_shape
    ->linestyle('none')
    ->fillstyle('ffffff')
    ->box(0,0,20,$bbox[3]);
my $si = $s->place(clip_with => $ti);
for (-10..$bbox[2]) {
    next unless $_%10 == 0;
    $si->moveto($_,10);
}

$m->save('masktest.swf');
