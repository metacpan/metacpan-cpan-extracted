#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use MainWindow;

sub main
{
    my $app = Qt::Application(\@ARGV);

    my $locale = Qt::Locale::system()->name();

# [0]
    my $translator = Qt::Translator();
    $translator->load('trollprint_' . $locale);
    $app->installTranslator($translator);
# [0]

    my $mainWindow = MainWindow();
    $mainWindow->show();
    return $app->exec();
}

exit main();
