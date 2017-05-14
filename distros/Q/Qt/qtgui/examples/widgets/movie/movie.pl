#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;

use MoviePlayer;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $player = MoviePlayer();
    $player->show();
    exit $app->exec();
}

main();
