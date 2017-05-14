#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;

use DragWidget;

sub main {
    my $app = Qt::Application( \@ARGV );

    my $mainWidget = Qt::Widget();
    my $horizontalLayout = Qt::HBoxLayout();
    my $drag1=DragWidget();
    my $drag2=DragWidget();
    $horizontalLayout->addWidget($drag1);
    $horizontalLayout->addWidget($drag2);

    $mainWidget->setLayout($horizontalLayout);
    $mainWidget->setWindowTitle(Qt::Object::tr('Draggable Icons'));
    $mainWidget->show();

    exit $app->exec();
}

main();
