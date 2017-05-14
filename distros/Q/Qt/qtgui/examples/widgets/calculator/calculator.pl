#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use Calculator;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $calc = Calculator();
    $calc->show();
    exit $app->exec();
}

main();
