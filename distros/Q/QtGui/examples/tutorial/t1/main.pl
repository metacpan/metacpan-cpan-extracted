#!/usr/bin/perl -w

# use blib;
use Qt::QApplication;
use Qt::QString;
use Qt::QPushButton;

unshift @ARGV, 'tutorial_1';

my $app = QApplication(\@ARGV);

my $hello = QPushButton(QString("Hello world!"));
$hello->resize(100,30);
$hello->show();

$app->exec();

1;
