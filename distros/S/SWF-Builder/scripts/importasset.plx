#!/usr/bin/perl

use strict;

use SWF::Builder;

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, 400, 200], BackgroundColor => 'ffffff');
$m->compress(1);

my $mc = $m->import_asset('exportasset.swf', 'MC', 'MovieClip');
my $s = $m->import_asset('exportasset.swf', 'BOX', 'Shape');

my $mc_i = $mc->place;
$mc_i->moveto(0,100);
my $si = $s->place;
$si->moveto(0,50);

$mc_i->on('EnterFrame')->compile(<<EOAS);
this._x += 1;
if (this._x > 400) {
    this._x = 0;
}
EOAS

for (0..40) {
    $si->moveto($_ * 10, 50);
}

$m->save('importasset.swf');

