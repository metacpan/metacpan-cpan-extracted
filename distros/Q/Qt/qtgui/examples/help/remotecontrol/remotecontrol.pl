#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use RemoteControl;
use RemoteControlResources;

sub main
{
    my $a = Qt::Application(\@ARGV);
    my $w = RemoteControl();
    $w->show();
    $a->connect($a, SIGNAL 'lastWindowClosed()', $a, SLOT 'quit()');
    return $a->exec();
}

exit main();
