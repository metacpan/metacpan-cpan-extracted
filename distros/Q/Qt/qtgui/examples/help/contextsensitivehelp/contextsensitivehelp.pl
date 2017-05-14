#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use WateringConfigDialog;

sub main
{
    my $a = Qt::Application(\@ARGV);
    my $dia = WateringConfigDialog();
    return $dia->exec();
}

exit main();
