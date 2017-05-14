#!/usr/bin/perl -w

# use blib;
use Qt;
use Qt::QString;
use Qt::QApplication;
use Qt::QFont;
use Qt::QPushButton;
 
unshift @ARGV, 'tutorial_2';  

my $app = QApplication(\@ARGV);

my $quit = QPushButton(QString("Quit"));
$quit->resize(75,30);
$quit->setFont(QFont(QString("Times"), 18, Qt::QFont::Bold));

$app->connect($quit, SIGNAL('clicked()'), $app, SLOT('quit()'));

$quit->show();
$app->exec();
