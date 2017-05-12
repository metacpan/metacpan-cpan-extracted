#!/usr/bin/env perl

use strict;
use warnings;
use Pigment;

my $viewport = Pigment::ViewportFactory->make('opengl');
$viewport->set_title('Text');

my $txt = Pigment::Text->new(<<'EOM');
<b>PgmText</b> is a drawable displaying a <u>text</u> with support for
multiple lines, <i><b>markups</b> and several</i> properties.
EOM

$txt->set_font_height(0.12);
$txt->set_size(1, 1);
$txt->set_position(1.5, 1, 0);
$txt->set_fg_color(240, 240, 240, 255);
$txt->set_bg_color(20, 20, 20, 255);
$txt->show;

my $canvas = Pigment::Canvas->new;
$viewport->set_canvas($canvas);
$canvas->add('middle', $txt);

$viewport->signal_connect('delete-event' => sub {
    Pigment->main_quit;
});

$viewport->signal_connect('key-press-event' => sub {
    my ($vp, $event) = @_;
    printf("keyval:0x%x\n", $event->keyval);
});

$viewport->show;

Pigment->main;
