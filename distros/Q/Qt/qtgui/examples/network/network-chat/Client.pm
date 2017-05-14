package Client;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Server;
use PeerManager;
use Connection;

use QtCore4::isa qw( Qt::Object );
use QtCore4::signals
    newMessage => ['const QString &', 'const QString &'],
    newParticipant => ['const QString &'],
    participantLeft => ['const QString &'];

use QtCore4::slots
    newConnection => ['QTcpSocket*'],
    connectionError => ['QAbstractSocket::SocketError'],
    disconnected => [],
    readyForUse => [];

sub peerManager() {
    return this->{peerManager};
}

sub server() {
    return this->{server};
}

sub peers() {
    return this->{peers};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{peerManager} = PeerManager(this);
    this->{server} = Server();
    this->{peers} = {};
    peerManager->setServerPort(server->serverPort());
    peerManager->startBroadcasting();

    Qt::Object::connect(peerManager, SIGNAL 'newConnection(QTcpSocket*)',
                     this, SLOT 'newConnection(QTcpSocket*)');
    Qt::Object::connect(server, SIGNAL 'newConnection(QTcpSocket*)',
                     this, SLOT 'newConnection(QTcpSocket*)');
}

sub sendMessage
{
    my ($message) = @_;
    if (!defined $message) {
        return;
    }

    my @connections = values %{peers()};
    foreach my $connection ( @connections ) {
        $connection->sendMessage($message);
    }
}

sub nickName
{
    return peerManager->userName()->constData() . '@' . Qt::HostInfo::localHostName()
           . ':' . server->serverPort();
}

sub hasConnection
{
    my ($senderIp, $senderPort) = @_;
    if (!defined $senderPort) {
        return exists peers()->{$senderIp->toString()};
    }

    if (!exists peers()->{$senderIp->toString()}) {
        return 0;
    }

    my @connections = values %{peers()};
    foreach my $connection ( @connections ) {
        if ($connection->peerPort() == $senderPort) {
            return 1;
        }
    }

    return 0;
}

sub newConnection
{
    my ($connection) = @_;
    $connection->setGreetingMessage(peerManager->userName());

    this->connect($connection, SIGNAL 'error(QAbstractSocket::SocketError)',
            this, SLOT 'connectionError(QAbstractSocket::SocketError)');
    this->connect($connection, SIGNAL 'disconnected()', this, SLOT 'disconnected()');
    this->connect($connection, SIGNAL 'readyForUse()', this, SLOT 'readyForUse()');
}

sub readyForUse
{
    my $connection = sender();
    if (!defined $connection || hasConnection($connection->peerAddress(),
                                     $connection->peerPort())) {
        return;
    }

    this->connect($connection, SIGNAL 'newMessage(QString,QString)',
            this, SIGNAL 'newMessage(QString,QString)');

    peers()->{$connection->peerAddress()->toString()} = $connection;
    my $nick = $connection->name();
    if (defined $nick) {
        emit newParticipant($nick);
    }
}

sub disconnected
{
    my $connection = sender();
    if ($connection->isa('Connection')) {
        removeConnection($connection);
    }
}

sub connectionError
{
    my $connection = sender();
    if ($connection->isa('Connection')) {
        removeConnection($connection);
    }
}

sub removeConnection
{
    my ($connection) = @_;
    if (exists peers()->{$connection->peerAddress()->toString()}) {
        delete peers()->{$connection->peerAddress()->toString()};
        my $nick = $connection->name();
        if (defined $nick) {
            emit participantLeft($nick);
        }
    }
    #$connection->deleteLater();
}

1;
