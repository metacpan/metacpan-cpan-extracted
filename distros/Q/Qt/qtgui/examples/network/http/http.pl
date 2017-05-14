#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use HttpWindow;

sub main
{
    my $app = Qt::Application(\@ARGV);
    warn "The usage of Qt::Http is not recommended anymore, please use Qt::NetworkAccessManager.\n";
    my $httpWin = HttpWindow();
    $httpWin->show();
    return $httpWin->exec();
}

exit main();
