#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use WidgetGallery;

sub main {
    #Q_INIT_RESOURCE(styles);

    print "This example lacks necessary support from the underlying Smoke " .
        "object.  Displaying what I can...\n";
    my $app = Qt::Application( \@ARGV );
    my $gallery = WidgetGallery();
    $gallery->show();
    return $app->exec();
}

exit main();
