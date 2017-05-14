#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Receiver;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $receiver = Receiver();
    $receiver->show();
    return $receiver->exec();
}

exit main();
