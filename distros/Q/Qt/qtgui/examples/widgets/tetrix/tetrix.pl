#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use TetrixWindow;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $window = TetrixWindow();
    $window->show();
    srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`);
    exit $app->exec();
}

main();
