#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use DigitalClock;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $clock = DigitalClock();
    $clock->show();
    exit $app->exec();
}

main();
