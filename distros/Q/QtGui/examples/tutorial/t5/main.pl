#!/usr/bin/perl -w

package MyWidget;

# use blib;
use Qt;
use Qt::QString;
use Qt::QApplication;
use Qt::QFont;
use Qt::QLCDNumber;
use Qt::QPushButton;
use Qt::QSlider;
use Qt::QBoxLayout;
use Qt::QWidget;

our @ISA = qw(Qt::QWidget);

sub MyWidget {
    my $class = 'MyWidget';
    my $this = QWidget();
    $this->setObjectName(QString("widget"));
    bless $this, $class;
    
    $this->{quit} = QPushButton(QString("Quit"), $this);
    $this->{quit}->setObjectName(QString("quit"));

    $this->{lcd} = QLCDNumber(2);
    $this->{lcd}->setSegmentStyle(Qt::QLCDNumber::Filled);
    $this->{lcd}->setObjectName(QString("lcd"));

    $this->{slider} = QSlider(Qt::Horizontal);
    $this->{slider}->setRange(0, 99);
    $this->{slider}->setValue(0);
    $this->{slider}->setObjectName(QString("slider"));

    $this->connect($this->{quit}, SIGNAL('clicked()'), $qApp, SLOT('quit()'));
    $this->connect($this->{slider}, SIGNAL('valueChanged(int)'), $this->{lcd}, SLOT('display(int)'));
    
    $this->{layout} = QVBoxLayout();
    $this->{layout}->setObjectName(QString("layout"));
    $this->{layout}->addWidget($this->{quit});
    $this->{layout}->addWidget($this->{lcd});
    $this->{layout}->addWidget($this->{slider});
    $this->setLayout($this->{layout});
    
    return $this;
}


package main;

# use blib;
use Qt::QApplication;
use Qt::QWidget;

unshift @ARGV, 'tutorial_5';

my $app = QApplication(\@ARGV);
my $widget = MyWidget::MyWidget();
$widget->show();
$app->exec();




