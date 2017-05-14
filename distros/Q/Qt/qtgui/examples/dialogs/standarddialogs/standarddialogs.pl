#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use Dialog;

sub main {
    my $app = Qt::Application( \@ARGV );

    my $translatorFileName = 'qt_';
    $translatorFileName .= Qt::Locale::system()->name();
    my $translator = Qt::Translator($app);
    if ($translator->load($translatorFileName, Qt::LibraryInfo::location(Qt::LibraryInfo::TranslationsPath()))) {
        $app->installTranslator($translator);
    }

    my $dialog = Dialog();
    exit $dialog->exec();
}

main();
