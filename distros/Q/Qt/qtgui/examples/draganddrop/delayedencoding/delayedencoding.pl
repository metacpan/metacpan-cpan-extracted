#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use SourceWidget;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $window = SourceWidget();
    $window->show();
    exit $app->exec();
}

main();
