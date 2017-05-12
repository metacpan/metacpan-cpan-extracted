#!/usr/bin/perl

use strict;

use SWF::Builder;

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, 400, 200], BackgroundColor => 'ffffff');
$m->compress(1);

my $mc = $m->new_mc;

my $s = $mc->new_shape
    ->linestyle(3, '000000')
    ->fillstyle('ff0000')
    ->box(0,0,50,50);
$s->export_asset('BOX');
$s->place->moveto(-25,-25);

$mc->export_asset('MC');

$mc->init_action->compile(<<EOAS, Trace => 'lcwin');

if (_global.ysas == undefined) {
    _global.ysas = new Object();
}

ysas.Square = function() {
    trace('Square constructer is called.');
    this.onEnterFrame = this.rot;
};

ysas.Square.prototype = new MovieClip();
Object.registerClass("MC", ysas.Square);
ysas.Square.prototype.rot = function() {
	this._rotation += 10;
	trace('rot is called.');
    };

EOAS

$m->save('exportasset.swf');
