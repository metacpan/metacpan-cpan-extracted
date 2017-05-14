#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use TabDialog;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $fileName;

    if (@ARGV >= 1) {
        $fileName = $ARGV[0];
    }
    else {
        $fileName = '.';
    }

    my $tabdialog = TabDialog($fileName);
    exit $tabdialog->exec();
}

main();
