#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use Panel;

sub main
{
    my $app = Qt::Application(\@ARGV);

    my $panel = Panel(3, 3);
    $panel->setFocus();
    $panel->show();

    return $app->exec();
}

exit main();
