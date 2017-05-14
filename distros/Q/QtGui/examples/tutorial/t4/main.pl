#!/usr/bin/perl -w

package MyWidget;

# use blib;
use Qt;
use Qt::QString;
use Qt::QApplication;
use Qt::QFont;
use Qt::QPushButton;
use Qt::QWidget;

our @ISA = qw(Qt::QWidget);

sub MyWidget {
    my $class = 'MyWidget';
    my $this = QWidget();
    bless $this, $class;
    $this->setObjectName(QString("widget"));
    $this->setFixedSize(200, 100);
    
    $this->{quit} = QPushButton(QString("Quit"), $this);
    $this->{quit}->setObjectName(QString("quit"));
    $this->{quit}->setGeometry(62, 40, 75, 30);
    $this->{quit}->setFont(QFont(QString("Times"), 18, Qt::QFont::Bold));
    
    $this->connect($this->{quit}, SIGNAL('clicked()'), $qApp, SLOT('quit()'));
    return $this;
}


package main;

# use blib;
use Qt;
use Qt::QApplication;
use Qt::QWidget;

unshift @ARGV, 'tutorial_4';

my $app = QApplication(\@ARGV);
my $widget = MyWidget::MyWidget();
$widget->show();
$app->exec();


