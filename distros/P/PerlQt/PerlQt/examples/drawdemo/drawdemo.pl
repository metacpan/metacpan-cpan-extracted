#!/usr/bin/perl -w
use strict;
package DrawView;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::slots
	updateIt => ['int'],
	printIt => [];
use Qt::attributes qw(
	printer
	bgroup
	_print
	drawindex
	maxindex
);

#
# First we define the functionality our demo should present
# to the user. You might add different demo-modes if you wish so
#

#
# This function draws a color wheel.
# The coordinate system x=(0..500), y=(0..500) spans the paint device.
#

sub drawColorWheel {
    my $p = shift;
    my $f = Qt::Font("times", 18, &Qt::Font::Bold);
    $p->setFont($f);
    $p->setPen(&black);
    $p->setWindow(0, 0, 500, 500);		# defines coordinate system

    for my $i (0..35) {
	my $matrix = Qt::WMatrix;
	$matrix->translate(250.0, 250.0);	# move to center
	$matrix->shear(0.0, 0.3);		# twist it
	$matrix->rotate($i*10.0);		# rotate 0,10,20,.. degrees
	$p->setWorldMatrix($matrix);    	# use this world matrix

	my $c = Qt::Color;
	$c->setHsv($i*10, 255, 255);		# rainbow effect
	$p->setBrush($c);			# solid fill with color $c
	$p->drawRect(70, -10, 80, 10);		# draw the rectangle

	my $n = sprintf "H=%d", $i*10;
	$p->drawText(80+70+5, 0, $n);		# draw the hue number
    }
}

#
# This function draws a few lines of text using different fonts.
#

sub drawFonts {
    my $p = shift;
    my @fonts = qw(Helvetica Courier Times);
    my @sizes = (10, 12, 18, 24, 36);
    my $y = 0;
    for my $f (@fonts) {
	for my $s (@sizes) {
	    my $font = Qt::Font($f, $s);
	    $p->setFont($font);
	    my $fm = $p->fontMetrics;
	    $y += $fm->ascent;
	    $p->drawText(10, $y, "Quartz Glyph Job Vex'd Cwm Finks");
	    $y += $fm->descent;
	}
    }
}

#
# This function draws some shapes
#

sub drawShapes {
    my $p = shift;
    my $b1 = Qt::Brush(&blue);
    my $b2 = Qt::Brush(&green, &Dense6Pattern);		# green 12% fill
    my $b3 = Qt::Brush(&NoBrush);			# void brush
    my $b4 = Qt::Brush(&CrossPattern);			# black cross pattern

    $p->setPen(&red);
    $p->setBrush($b1);
    $p->drawRect(10, 10, 200, 100);
    $p->setBrush($b2);
    $p->drawRoundRect(10, 150, 200, 100, 20, 20);
    $p->setBrush($b3);
    $p->drawEllipse(250, 10, 200, 100);
    $p->setBrush($b4);
    $p->drawPie(250, 150, 200, 100, 45*16, 90*16);
}

our @drawFunctions = (
# title presented to user,  reference to the function
    { name => "Draw color wheel", f => \&drawColorWheel },
    { name => "Draw fonts"      , f => \&drawFonts      },
    { name => "Draw shapes"     , f => \&drawShapes     },
);

#
# Construct the DrawView with buttons.
#

sub NEW {
    shift->SUPER::NEW(@_);

    setCaption("PerlQt Draw Demo Application");
    setBackgroundColor(&white);

    # Create a button group to contain all buttons
    bgroup = Qt::ButtonGroup(this);
    bgroup->resize(200, 200);
    this->connect(bgroup, SIGNAL('clicked(int)'), SLOT('updateIt(int)'));

    # Calculate the size for the radio buttons
    my $maxwidth = 80;
    my $maxheight = 10;
    my $fm = bgroup->fontMetrics;

    for my $i (0 .. $#drawFunctions) {
	my $n = $drawFunctions[$i]{name};
	my $w = $fm->width($n);
	$maxwidth = max($w, $maxwidth);
    }

    $maxwidth += 30;

    for my $i (0 .. $#drawFunctions) {
	my $n = $drawFunctions[$i]{name};
	my $rb = Qt::RadioButton($n, bgroup);
	$rb->setGeometry(10, $i*30+10, $maxwidth, 30);

	$maxheight += 30;

	$rb->setChecked(1) unless $i;
	$i++;
    }

    $maxheight += 10;

    drawindex = 0;
    maxindex  = scalar @drawFunctions;
    $maxwidth += 20;

    bgroup->resize($maxwidth, $maxheight);

    printer = Qt::Printer;

    _print = Qt::PushButton("Print...", bgroup);
    _print->resize(80, 30);
    _print->move($maxwidth/2 - _print->width/2, maxindex*30+20);
    this->connect(_print, SIGNAL('clicked()'), SLOT('printIt()'));

    bgroup->resize($maxwidth, _print->y+_print->height+10);

    resize(640,300);
}

sub updateIt {
    my $index = shift;
    if($index < maxindex) {
	drawindex = $index;
	update();
    }
}

sub drawIt {
    my $p = shift;
    $drawFunctions[drawindex]{f}->($p);
}

sub printIt {
    if(printer->setup(this)) {
	my $paint = Qt::Painter(printer);
	drawIt($paint);
    }
}

sub paintEvent {
    my $paint = Qt::Painter(this);
    drawIt($paint);
}

sub resizeEvent {
    bgroup->move(int(width() - bgroup->width), int(0));
}

package main;
use Qt;
use DrawView;

my $app = Qt::Application(\@ARGV);
my $draw = DrawView;
$app->setMainWidget($draw);
$draw->setCaption("PerlQt Example - Drawdemo");
$draw->show;
exit $app->exec;
