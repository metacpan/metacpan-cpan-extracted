#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Server;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $server = Server();
    $server->show();
    srand(Qt::Time(0,0,0)->secsTo(Qt::Time::currentTime()));
    return $server->exec();
}

exit main();
