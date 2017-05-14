package Server;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::TcpServer );
use QtCore4::signals
    newConnection => ['QTcpSocket*'];
use Connection;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->listen(Qt::HostAddress(Qt::HostAddress::Any()));
}

sub incomingConnection
{
    my ($socketDescriptor) = @_;
    my $connection = Connection(this);
    $connection->setSocketDescriptor($socketDescriptor);
    emit newConnection($connection);
}

1;
