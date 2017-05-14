#!/usr/bin/perl -w

package MyWidget;

#use blib;
use Qt;
use Qt::QString;
use Qt::QApplication;
use Qt::QFont;
use Qt::QGridLayout;
use Qt::QPushButton;
use Qt::QWidget;

use CanonField;
use LCDRange;

our @ISA = qw(Qt::QWidget);


sub new {
    my $class = 'MyWidget';
    my $this = QWidget();
    bless $this, $class;
    
    $this->{quit} = QPushButton(QString("Quit"));
    $this->{quit}->setFont(QFont(QString("Times"), 18, Qt::QFont::Bold));
    
    $this->connect($this->{quit}, SIGNAL('clicked()'), $qApp, SLOT('quit()'));
    
    $this->{angle} = LCDRange();
    $this->{angle}->setRange(5,70);
    
    $this->{canonField} = CanonField();
    
    $this->connect($this->{angle}, SIGNAL('valueChanged(int)'), $this->{canonField}, SLOT('setAngle(int)'));
    $this->connect($this->{canonField}, SIGNAL('angleChanged(int)'), $this->{angle}, SLOT('setValue(int)'));
    
    $this->{gridLayout} = QGridLayout();
    $this->{gridLayout}->addWidget($this->{quit}, 0, 0);
    $this->{gridLayout}->addWidget($this->{angle}, 1, 0);
    $this->{gridLayout}->addWidget($this->{canonField}, 1, 1, 2, 1);
    $this->{gridLayout}->setColumnStretch(1, 10);
    $this->setLayout($this->{gridLayout});
    
    $this->{angle}->setValue(60);
    $this->{angle}->setFocus();

    return $this;
}

1;

package main;

#use blib;
use Qt;
use Qt::QApplication;
use Qt::QWidget;

unshift @ARGV, 'tutorial_8';

my $app = QApplication(\@ARGV);
my $widget = new MyWidget;
$widget->setGeometry(10, 100, 500, 355);
$widget->show();
$app->exec();

