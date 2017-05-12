#!/usr/bin/perl -w
use strict;
package ConnectWidget;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::attributes qw(
	points
	colors
	count
	down
);
use constant MAXPOINTS => 2000;
use constant MAXCOLORS => 40;

#
# Constructs a ConnectWidget.
#

sub NEW {
    shift->SUPER::NEW(@_[0,1], &WStaticContents);

    setBackgroundColor(&white);
    count = 0;
    down = 0;
    points = [];
    my @colors;
    for(1 .. MAXCOLORS) {
	push @colors, Qt::Color(rand(255), rand(255), rand(255));
    }
    colors = \@colors;
}

sub paintEvent {
    my $paint = Qt::Painter(this);
    for(my $i = 0; $i < count-1; $i++) {
	for(my $j = $i+1; $j < count; $j++) {
	    $paint->setPen(colors->[rand(MAXCOLORS)]);
	    $paint->drawLine(points->[$i], points->[$j]);
	}
    }
}

sub mousePressEvent {
    down = 1;
    count = 0;
    points = [];
    erase();
}

sub mouseReleaseEvent {
    down = 0;
    update();
}

sub mouseMoveEvent {
    my $e = shift;
    if(down && count < MAXPOINTS) {
	my $paint = Qt::Painter(this);
	push @{this->points}, Qt::Point($e->pos);
	count++;
	$paint->drawPoint($e->pos);
    }
}

package main;
use Qt;
use ConnectWidget;

my $a = Qt::Application(\@ARGV);
my $connect = ConnectWidget;
$connect->setCaption("PerlQt Example - Draw lines");
$a->setMainWidget($connect);
$connect->show;
exit $a->exec;
