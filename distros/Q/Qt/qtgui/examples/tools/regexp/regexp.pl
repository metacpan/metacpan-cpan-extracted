#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use RegExpDialog;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $dialog = RegExpDialog();
    $dialog->show();
    return $dialog->exec();
}

exit main();
