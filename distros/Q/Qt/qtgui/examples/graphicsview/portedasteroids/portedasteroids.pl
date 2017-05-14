#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use Qt::GlobalSpace qw(qsrand);

use PortedAsteroidsResources;
use KAstTopLevel;

sub main
{
    my $app = Qt::Application(\@ARGV);

    qsrand(Qt::Time(0,0,0)->secsTo(Qt::Time::currentTime()));
    
    my $topLevel = KAstTopLevel();
    $topLevel->setWindowTitle('Ported Asteroids Game');
    $topLevel->show();

    $app->setQuitOnLastWindowClosed(1);
    return $app->exec();
}

exit main();
