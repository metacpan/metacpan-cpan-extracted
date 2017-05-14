#!/usr/bin/perl -w

use strict;
use warnings;

package MyWidget;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use LCDRange;

my @widgets;

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("Quit");
    $quit->setFont(Qt::Font("Times", 18, Qt::Font::Bold()));

    this->connect($quit, SIGNAL "clicked()", qApp, SLOT "quit()");

    my $grid = Qt::GridLayout();
    my $previousRange;


    foreach my $row ( 0..2 ) {
        foreach my $column ( 0..2 ) {
            my $lcdRange = LCDRange();
            $grid->addWidget($lcdRange, $row, $column);
            if ($previousRange) {
                this->connect($lcdRange, SIGNAL "valueChanged(int)",
                              $previousRange, SLOT "setValue(int)");
            }
            $previousRange = $lcdRange;
            push @widgets, $lcdRange;
        }
    }

    my $layout = Qt::VBoxLayout;
    $layout->addWidget($quit);
    $layout->addLayout($grid);
    this->setLayout($layout);
}

1;

package main;

use QtCore4;
use QtGui4;
use MyWidget;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $widget = MyWidget();
    $widget->show();
    return $app->exec();
} 

main();
