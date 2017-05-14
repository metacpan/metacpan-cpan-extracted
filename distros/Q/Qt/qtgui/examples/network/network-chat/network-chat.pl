#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use ChatDialog;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $dialog = ChatDialog();
    $dialog->show();
    return $app->exec();
}

exit main();
