#!/usr/bin/perl -w

# use blib;
use Qt;
use Qt::QString;
use Qt::QApplication;
use Qt::QFont;
use Qt::QPushButton;
use Qt::QWidget;
   
unshift @ARGV, 'tutorial_3';

my $app = QApplication(\@ARGV);

my $window = QWidget();
$window->resize(200, 120);

my $quit = QPushButton(QString("Quit"), $window);
$quit->setFont(QFont(QString("Times"), 18, Qt::QFont::Bold, 1)); # 1 == true, for italic font
$quit->setGeometry(10, 40, 180, 40);
$app->connect($quit, SIGNAL('clicked()'), $app, SLOT('quit()'));

$window->show();
$app->exec();

