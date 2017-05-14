#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use ImageComposer;

# [0]
sub main
{
    my $app = Qt::Application(\@ARGV);
    my $composer = ImageComposer();
    $composer->show();
    return $app->exec();
}
# [0]

exit main();
