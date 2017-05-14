#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Controller;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $controller = Controller();
    $controller->show();
    return $app->exec();
}

exit main();
