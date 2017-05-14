#!/usr/bin/perl -w

use strict;
use warnings;

package MyWidget;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::Widget);
use CannonField;
use LCDRange;

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("Quit");
    $quit->setFont(Qt::Font("Times", 18, Qt::Font::Bold()));

    this->connect($quit, SIGNAL "clicked()", qApp, SLOT "quit()");

    my $angle = LCDRange();
    $angle->setRange(5, 70);

    my $cannonField = CannonField();

    this->connect($angle, SIGNAL 'valueChanged(int)',
                  $cannonField, SLOT 'setAngle(int)');
    this->connect($cannonField, SIGNAL 'angleChanged(int)',
                  $angle, SLOT 'setValue(int)');

    my $gridLayout = Qt::GridLayout();
    $gridLayout->addWidget($quit, 0, 0);
    $gridLayout->addWidget($angle, 1, 0);
    $gridLayout->addWidget($cannonField, 1, 1, 2, 1);
    $gridLayout->setColumnStretch(1, 10);
    this->setLayout($gridLayout);

    $angle->setValue(60);
    $angle->setFocus();
}

1;

package main;

use QtCore4;
use QtGui4;
use MyWidget;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $widget = MyWidget();
    $widget->setGeometry(100, 100, 500, 355);
    $widget->show();
    return $app->exec();
} 

main();
