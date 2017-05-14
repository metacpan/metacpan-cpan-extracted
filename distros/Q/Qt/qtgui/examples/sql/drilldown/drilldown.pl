#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use lib '../';
use Connection;
use View;

sub main
{
    my $app = Qt::Application(\@ARGV);

    if (!Connection::createConnection()) {
        return 1;
    }

    my $view = View('offices', 'images');
    $view->show();
    #Qt::Application::setNavigationMode(Qt::NavigationModeCursorAuto());
    return $app->exec();
}

exit main();
