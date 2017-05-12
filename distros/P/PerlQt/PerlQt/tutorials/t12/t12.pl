#!/usr/bin/perl -w
use strict;
use blib;

package MyWidget;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);

use LCDRange;
use CannonField;

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("&Quit", this, "quit");
    $quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    Qt::app->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

    my $angle = LCDRange("ANGLE", this, "angle");
    $angle->setRange(5, 70);

    my $force = LCDRange("FORCE", this, "force");
    $force->setRange(10, 50);

    my $cannonField = CannonField(this, "cannonField");

    $cannonField->connect($angle, SIGNAL('valueChanged(int)'), SLOT('setAngle(int)'));
    $angle->connect($cannonField, SIGNAL('angleChanged(int)'), SLOT('setValue(int)'));

    $cannonField->connect($force, SIGNAL('valueChanged(int)'), SLOT('setForce(int)'));
    $force->connect($cannonField, SIGNAL('forceChanged(int)'), SLOT('setValue(int)'));

    my $shoot = Qt::PushButton('&Shoot', this, "shoot");
    $shoot->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    $cannonField->connect($shoot, SIGNAL('clicked()'), SLOT('shoot()'));

    my $grid = Qt::GridLayout(this, 2, 2, 10);
    $grid->addWidget($quit, 0, 0);
    $grid->addWidget($cannonField, 1, 1);
    $grid->setColStretch(1, 10);

    my $leftBox = Qt::VBoxLayout;
    $grid->addLayout($leftBox, 1, 0);
    $leftBox->addWidget($angle);
    $leftBox->addWidget($force);

    my $topBox = Qt::HBoxLayout;
    $grid->addLayout($topBox, 0, 1);
    $topBox->addWidget($shoot);
    $topBox->addStretch(1);

    $angle->setValue(60);
    $force->setValue(25);
    $angle->setFocus();
}

package main;
use Qt;
use MyWidget;

Qt::Application::setColorSpec(&Qt::Application::CustomColor);
my $a = Qt::Application(\@ARGV);

my $w = MyWidget;
$w->setGeometry(100, 100, 500, 355);
$a->setMainWidget($w);
$w->show;
exit $a->exec;
