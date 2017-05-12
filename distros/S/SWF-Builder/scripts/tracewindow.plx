#!/usr/bin/perl

use strict;

use SWF::Builder;

my $m = SWF::Builder->new(FrameRate=>12, FrameSize=>[0, 0, 300, 270], BackgroundColor => 'ffffff');
$m->compress(1);

$m->frame_action(1)->compile(<<EOAS);
    lc = new LocalConnection();
    lc.trace = function (msg) {
      tracewin.text += msg + '\n';
      tracewin.scroll = tracewin.maxscroll;
    };

    lc.connect('__trace');
EOAS

$m->new_dynamic_text->text('Trace window')->place->moveto(16, 13);
my $trwin = $m->new_text_area(266, 227)->place;
$trwin->moveto(16, 35);
$trwin->name('tracewin');

$m->save('tracewindow.swf');