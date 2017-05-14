#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;

use Window;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $window = Window();
    $window->show();
    exit $app->exec();
}

main();
