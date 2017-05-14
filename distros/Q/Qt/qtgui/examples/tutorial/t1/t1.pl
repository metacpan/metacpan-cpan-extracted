#!/usr/bin/perl -w

use strict;
use warnings;

use QtCore4;
use QtGui4;

sub main {
    my $app = Qt::Application(\@ARGV);
    my $hello = Qt::PushButton("Hello world!");
    $hello->show();
    exit $app->exec();
}

main();
