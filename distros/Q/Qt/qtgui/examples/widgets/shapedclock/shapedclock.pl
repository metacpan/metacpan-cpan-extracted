#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use ShapedClock;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $clock = ShapedClock();
    $clock->show();
    return $app->exec();
}

exit main();
