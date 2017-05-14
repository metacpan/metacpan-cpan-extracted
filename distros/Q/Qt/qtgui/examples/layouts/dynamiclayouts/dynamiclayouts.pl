#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Dialog;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $dialog = Dialog();
    return $dialog->exec();
}

exit main();
