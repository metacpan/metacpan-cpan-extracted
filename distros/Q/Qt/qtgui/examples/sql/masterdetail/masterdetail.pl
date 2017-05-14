#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use Database;
use MainWindow;

sub main
{
    my $app = Qt::Application(\@ARGV);

    if (!Database::createConnection()) {
        return 1;
    }

    my $albumDetails = Qt::File('albumdetails.xml');
    my $window = MainWindow('artists', 'albums', $albumDetails);
    $window->show();
    return $app->exec();
}

exit main();
