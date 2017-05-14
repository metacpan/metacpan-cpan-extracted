#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Screenshot;

sub main
{
    my $app = Qt::Application( \@ARGV );
    my $screenshot = Screenshot();
    $screenshot->show();
    return $app->exec();
}

exit main();
