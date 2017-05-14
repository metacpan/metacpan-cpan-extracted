#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use ControllerWindow;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $controller = ControllerWindow();
    $controller->show();
    return $app->exec();
}

exit main();
