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
    return $server->exec();
}

exit main();
