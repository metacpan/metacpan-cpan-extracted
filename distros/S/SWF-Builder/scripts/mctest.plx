#!/usr/bin/perl

use strict;

use SWF::Builder;

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, 400, 400], BackgroundColor => 'ffffff');
my $mc = $m->new_movie_clip;

my $font = $mc->new_font("c:/windows/fonts/arial.ttf");  # You may need to change it.
my $text = $mc->new_static_text
    ->font($font)
    ->size(20)
    ->color('ffffffaa')
    ->text('Click me!')
    ;
my ($x1, $y1, $x2, $y2) = $text->get_bbox;
my $ti = $text->place->moveto(-($x1+$x2)/2, -($y1+$y2)/2);
$x1-=10;
$y1-=10;
$x2+=10;
$y2+=10;

my $gr = $mc->new_gradient;
$gr->add_color(   0 => '000000',
		 98 => '0000ff',
		128 => 'ff0000',
		158 => '0000ff',
		255 => '000000',
		);
my $gm = $gr->matrix;

my $border = $mc->new_shape
    ->fillstyle($gr, 'linear', $gm)
    ->linestyle(1, '000000')
    ->moveto($x1,$y1)
    ->lineto($x2,$y1)
    ->lineto($x2,$y2)
    ->lineto($x1,$y2)
    ->lineto($x1,$y1);



$gm->fit_to_rect(longer => ($x1,$y1,$x2,$y2))->rotate(60);
my $bi = $border->place(below=>$ti)->moveto(-($x1+$x2)/2, -($y1+$y2)/2);

my $mci = $mc->place;
$mci->moveto(200,200);
$mci->on('EnterFrame')->r_rotate(5);
$mci->on('RollOver')->compile(<<END, Trace=>'lcwin');
    trace('_x:'+_x+', _y:'+_y);
    _x = Math.floor(Math.random()*300)+50;
    _y = Math.floor(Math.random()*300)+50;
END

$mci->on('Press')->compile(<<END, Trace=>'lcwin');
    trace('Clicked');
    _xscale *= 0.8;
    _yscale *= 0.8;
    _x = 200;
    _y = 200;
END

$m->save('mctest.swf');
