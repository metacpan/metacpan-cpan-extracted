#!/usr/bin/perl

use strict;

use SWF::Builder;

my $m = SWF::Builder->new(FrameRate => 15, FrameSize => [0, 0, 400, 200], BackgroundColor => 'ffffff');
$m->compress(1);

my $fp = $ENV{SYSTEMROOT}.'/fonts';

my $fontt = $m->new_font("$fp/times.ttf");
$fontt->add_glyph("\x20", "\x7f");

my $fontti = $m->new_font("$fp/timesi.ttf");
$fontti->add_glyph("\x20", "\x7f");

my $fonta = $m->new_font("$fp/arial.ttf");
$fonta->add_glyph("\x20", "\x7f");

my $ht = $m->new_html_text;

$ht->text(<<HTMLEND);
<p align="center"><font face="times new roman" size="30">Test <i>string</i>.</font></p>
<p><font face="arial">This is a dynamic <font color="#ff0000">HTML</font> text object sample.</font></p>
HTMLEND

$ht->use_font($fontt, $fontti, $fonta);
$ht->place->moveto(20,50);
$m->save('htmltest.swf');

