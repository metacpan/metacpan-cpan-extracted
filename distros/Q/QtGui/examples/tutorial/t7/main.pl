#!/usr/bin/perl -w

package MyWidget;

# use blib;
use Qt;
use Qt::QString;
use Qt::QApplication;
use Qt::QFont;
use Qt::QGridLayout;
use Qt::QPushButton;
use Qt::QBoxLayout;
use Qt::QWidget;

use LCDRange;

our @ISA = qw(Qt::QWidget);

sub MyWidget {
    my $class = 'MyWidget';
    my $this = QWidget();
    bless $this, $class;
    
    $this->{quit} = QPushButton(QString("Quit"));
    $this->{quit}->setFont(QFont(QString("Times"), 18, Qt::QFont::Bold));
    
    $this->connect($this->{quit}, SIGNAL('clicked()'), $qApp, SLOT('quit()'));
    
    $this->{grid} = QGridLayout();
    
    for ( my $row = 0 ; $row < 3 ; ++$row ) {
	for ( my $col = 0 ; $col < 3 ; ++$col ) {
	    $this->{lcdRange}[$row*3+$col] = LCDRange();
	    $this->{grid}->addWidget($this->{lcdRange}[$row*3+$col], $row, $col);
	    $this->connect($this->{lcdRange}[$row*3+$col], SIGNAL('valueChanged(int)'), 
		$this->{lcdRange}[$row*3+$col-1], SLOT('setValue(int)')) if ($row+$col) > 0;
	}
    }
    
    $this->{layout} = QVBoxLayout();
    $this->{layout}->addWidget($this->{quit});
    $this->{layout}->addLayout($this->{grid});
    $this->setLayout($this->{layout});
    
    return $this;
}

1;

package main;

# use blib;
use Qt;
use Qt::QApplication;
use Qt::QWidget;

unshift @ARGV, 'tutorial_7';

my $app = QApplication(\@ARGV);
my $widget = MyWidget::MyWidget();
$widget->show();
$app->exec();

