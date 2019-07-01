#!/usr/bin/env perl

# test of PDF::Cairo::Layout methods

use utf8;
use strict;
use warnings;
use PDF::Cairo qw(in);
use PDF::Cairo::Layout;

my $pdf = PDF::Cairo->new(
	paper => "letter",
	landscape => 1,
	file => "layout.pdf",
);

my $layout = PDF::Cairo::Layout->new($pdf);

my $markup = <<EOF;
This is a test of the <b>Emergency Broadcast System</b>. The
broadcasters of <tt>your area</tt>, in <i>voluntary cooperation</i>
with the Federal, State, and Local authorities, have developed this
system to keep you informed in the event of an emergency. If this had
been an actual emergency, the Attention Signal you just heard would
have been followed by official information, news or instructions. This
station serves the <span face='sans'>Arkham</span> area.

This concludes this test of the Emergency Broadcast System.
EOF

# strip EOL but preserve paragraph separator
$markup =~ s/\n(?!\n)/ /g;
$markup =~ s/\n /\n/g;

$layout->markup($markup);
$layout->width(in(5));
$layout->spacing(5);
$layout->justify(1);

# *upper* left corner
#
$pdf->move(in(1), in(8));
$layout->show;

# draw a box around the text extents
#
my $ink = $layout->ink;
$pdf->strokecolor('black');
$pdf->linewidth(0.1);
$pdf->linedash(4);
$pdf->move(in(1), in(8));
$pdf->rel_rect($ink->bbox);
$pdf->stroke;
$pdf->linedash;

# draw a line at the first line's baseline position
#
my $baseline = $layout->baseline;
$pdf->move(in(1), in(8) + $baseline);
$pdf->rel_line(in(5), 0);
$pdf->strokecolor('blue');
$pdf->linewidth(0.1);
$pdf->stroke;
$pdf->strokecolor('black');

# change the width and justification, add a paragraph indent,
# rotate it, scale it, and show it again in a different location.
#
$pdf->move(in(2) + $ink->width, in(8));
$pdf->save;
$pdf->rotate(10);
$pdf->scale(0.9, 0.9);
$layout->width(in(3));
$layout->justify(0);
$layout->indent(in(0.25));
$layout->show;
$pdf->restore;

# add the glyph outlines to the path so Cairo can stroke/fill them
#
$pdf->move(in(1), in(4));
$pdf->linewidth(3);
$pdf->fillcolor('red');
$layout->markup(qq(<span font='Courier Bold Italic 72'>xyzzy</span>));
$layout->path;
$pdf->fillstroke;
$pdf->write;
exit;

