#!/usr/bin/perl -w

use Qt;
#use Qt::QByteArray;
use Qt::QString;
use Qt::QApplication;
use Qt::QTranslator;
use Qt::QLocale;
use Qt::QLibraryInfo;

use Dialog;

unshift @ARGV, 'standarddialogs';

my $app = QApplication(\@ARGV);
my $translatorFileName = QString("qt_");
$translatorFileName += Qt::QLocale::system()->name();
#print $translatorFileName->toLatin1()->data(), "\n";
my $translator = QTranslator($app);
if ($translator->load($translatorFileName, Qt::QLibraryInfo::location(Qt::QLibraryInfo::TranslationsPath))) {
    $app->installTranslator($translator);
}
my $dialog = Dialog();
$dialog->exec();


