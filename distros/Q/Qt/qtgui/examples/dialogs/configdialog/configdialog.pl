#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;

use ConfigDialog;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $dialog = ConfigDialog();
    exit $dialog->exec();
}

main();
