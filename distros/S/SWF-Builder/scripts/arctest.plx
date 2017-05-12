#!/usr/bin/perl

use strict;

use SWF::Builder;
use Pod::Usage;

my ($sa, $ca, $rx, $ry, $rot) = @ARGV;

pod2usage(2) if ($rx == 0 or $ry == 0);
my $r = ($rx > $ry) ? $rx : $ry;
if ($r < 100) {
    $rx = $rx / $r * 100;
    $ry = $ry / $r * 100;
    $r = 100;
}

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, $r * 4, $r * 4], BackgroundColor => 'ffffff');

my $font = $m->new_font("$ENV{SYSTEMROOT}/fonts/arial.ttf");  # You may need to change it.

$m->new_shape->fillstyle('none')->linestyle(4, '0000ff')->ellipse($rx, $ry, $rot)->place->moveto($r*2, $r*2);
$m->new_shape->fillstyle('none')->linestyle(4, '88888888')->circle($rx)->moveto(0,0)->circle($ry)->place->moveto($r*2, $r*2);
$m->new_shape->fillstyle('none')->linestyle(1, '88888888')->starshape($r, 12, 0)->place->moveto($r*2, $r*2);
$m->new_dynamic_text->font($font)->size(15)->color('000000')->text("($sa, $ca, $rx, $ry, $rot)")->place->moveto(10,10);

my $ea1 = $m->new_mc;
$ea1->new_shape->fillstyle('none')->linestyle(4, 'ff000088')->arcto($sa, $ca, $rx, $ry, $rot)->place;
my $ea1i = $ea1->place;
$ea1i->moveto($r, $r);
setdd($ea1i);



sub setdd {
    my $mc = shift;

    $mc->on('MouseMove')->compile(<<END, Trace=>'lcwin');
    if (md) {
	_x = _root._xmouse-mx;
	_y = _root._ymouse-my;
	trace('('+_x+', '+_y+')');
    }
END


    $mc->on('Press')->compile(<<END, Trace=>'lcwin');
    mx = _xmouse;
    my = _ymouse;
    md = 1;
END

    $mc->on('Release')->compile('md = 0;', Trace=>'lcwin');
}

$m->save('arctest.swf');


=head1 NAME

arctest.plx - SWF::Builder sample script for elliptic arc.

=head1 SYNOPSIS

perl arctest.plx startangle centralangle x-radius y-radius rotationangle

=head1 DESCRIPTION

This writes arctest.swf, which contains a red arc you specified and a blue full ellipse.
You can drag the arc to confirm if the arc is really a part of the full ellipse.

=cut
