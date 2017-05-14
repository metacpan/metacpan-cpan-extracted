#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Client;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $client = Client();
    $client->show();
    return $client->exec();
}

exit main();
