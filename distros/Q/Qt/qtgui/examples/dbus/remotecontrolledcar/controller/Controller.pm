package Controller;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtDBus4;
use Ui_Controller;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    on_accelerate_clicked => [],
    on_decelerate_clicked => [],
    on_left_clicked => [],
    on_right_clicked => [];
use CarInterface;

sub ui() {
    return this->{ui};
}

sub car() {
    return this->{car};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{ui} = Ui_Controller->setupUi(this);
    this->{car} = CarInterface('com.trolltech.CarExample', '/Car',
                           Qt::DBusConnection::sessionBus(), this);
    this->startTimer(1000);
}

sub timerEvent
{
    if (this->car->isValid()) {
        this->ui->label->setText('connected');
    }
    else {
        this->ui->label->setText('disconnected');
    }
}

sub on_accelerate_clicked
{
    this->car->accelerate();
}

sub on_decelerate_clicked
{
    this->car->decelerate();
}

sub on_left_clicked
{
    this->car->turnLeft();
}

sub on_right_clicked
{
    this->car->turnRight();
}

1;
