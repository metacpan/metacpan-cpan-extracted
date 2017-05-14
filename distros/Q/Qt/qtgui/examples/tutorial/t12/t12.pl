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

    my $quit = Qt::PushButton("&Quit");
    $quit->setFont(Qt::Font("Times", 18, Qt::Font::Bold()));

    this->connect($quit, SIGNAL "clicked()", qApp, SLOT "quit()");

    my $angle = LCDRange(undef, "ANGLE");
    $angle->setRange(5, 70);

    my $force = LCDRange(undef, "FORCE");
    $force->setRange(10, 50);

    my $cannonField = CannonField();

    this->connect($angle, SIGNAL 'valueChanged(int)',
                  $cannonField, SLOT 'setAngle(int)');
    this->connect($cannonField, SIGNAL 'angleChanged(int)',
                  $angle, SLOT 'setValue(int)');

    this->connect($force, SIGNAL 'valueChanged(int)',
                  $cannonField, SLOT 'setForce(int)');
    this->connect($cannonField, SIGNAL 'forceChanged(int)',
                  $force, SLOT 'setValue(int)');

    my $shoot = Qt::PushButton("&Shoot");
    $shoot->setFont(Qt::Font("Times", 18, Qt::Font::Bold()));

    this->connect($shoot, SIGNAL 'clicked()', $cannonField, SLOT 'shoot()');

    my $topLayout = Qt::HBoxLayout();
    $topLayout->addWidget($shoot);
    $topLayout->addStretch(1);

    my $leftLayout = Qt::VBoxLayout();
    $leftLayout->addWidget($angle);
    $leftLayout->addWidget($force);

    my $gridLayout = Qt::GridLayout();
    $gridLayout->addWidget($quit, 0, 0);
    $gridLayout->addLayout($topLayout, 0, 1);
    $gridLayout->addLayout($leftLayout, 1, 0);
    $gridLayout->addWidget($cannonField, 1, 1, 2, 1);
    $gridLayout->setColumnStretch(1, 10);
    this->setLayout($gridLayout);

    $angle->setValue(60);
    $force->setValue(25);
    $angle->setFocus();
}

1;

package main;

use QtCore4;
use QtGui4;
use MyWidget;

sub main {
    my $app = Qt::Application();
    my $widget = MyWidget();
    $widget->setGeometry(100, 100, 500, 355);
    $widget->show();
    return $app->exec();
} 

main();
