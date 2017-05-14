#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;

use FindDialog;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $dialog = FindDialog();
    exit $dialog->exec();
}

main();
