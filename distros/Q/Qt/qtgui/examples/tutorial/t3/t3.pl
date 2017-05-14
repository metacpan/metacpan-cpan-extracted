#!/usr/bin/perl -w

use strict;
use warnings;

use QtCore4;
use QtGui4;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $window = Qt::Widget();
    $window->resize(200, 120);

    my $quit = Qt::PushButton("Quit", $window);
    $quit->setFont(Qt::Font("Times", 18, Qt::Font::Bold()));
    $quit->setGeometry(10, 40, 180, 40);
    Qt::Object::connect($quit, SIGNAL "clicked()", $app, SLOT "quit()");

    $window->show();
    return $app->exec();
} 

main();
