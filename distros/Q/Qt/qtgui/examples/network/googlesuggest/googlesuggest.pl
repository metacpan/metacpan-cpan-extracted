#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use SearchBox;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $searchEdit = SearchBox();
    $searchEdit->show();
    return $app->exec();
}

exit main();
