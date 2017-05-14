package CarInterface;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtDBus4;
use QtCore4::isa qw( Qt::DBusAbstractInterface );

sub staticInterfaceName {
    return 'com.trolltech.Examples.CarInterface';
}

use QtCore4::slots
    accelerate => [],
    decelerate => [],
    turnLeft => [],
    turnRight => [];

use QtCore4::signals
    crashed => [];

sub NEW
{
    my ($class, $service, $path, $connection, $parent) = @_;
    $class->SUPER::NEW($service, $path, staticInterfaceName(), $connection, $parent);
}

sub accelerate
{
    return this->callWithArgumentList(Qt::DBus::Block(), 'accelerate', []);
}

sub decelerate()
{
    return this->callWithArgumentList(Qt::DBus::Block(), 'decelerate', []);
}

sub turnLeft()
{
    return this->callWithArgumentList(Qt::DBus::Block(), 'turnLeft', []);
}

sub turnRight()
{
    return this->callWithArgumentList(Qt::DBus::Block(), 'turnRight', []);
}

1;
