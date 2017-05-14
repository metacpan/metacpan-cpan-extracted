package PeerManager;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Object );
use QtCore4::signals
    newConnection => ['QTcpSocket*'];
use QtCore4::slots
    sendBroadcastDatagram => [],
    readBroadcastDatagram => [];
use Client;
use Connection;
use List::MoreUtils qw( first_index );

sub client() {
    return this->{client};
}

sub broadcastAddresses() {
    return this->{broadcastAddresses};
}

sub ipAddresses() {
    return this->{ipAddresses};
}

sub broadcastSocket() {
    return this->{broadcastSocket};
}

sub broadcastTimer() {
    return this->{broadcastTimer};
}

sub username() {
    return this->{username};
}

sub serverPort() {
    return this->{serverPort};
}

    #Client *client;
    #Qt::List<Qt::HostAddress> broadcastAddresses;
    #Qt::List<Qt::HostAddress> ipAddresses;
    #Qt::UdpSocket broadcastSocket;
    #Qt::Timer broadcastTimer;
    #Qt::ByteArray username;
    #int serverPort;

my $BroadcastInterval = 2000;
my $broadcastPort = 45000;

sub NEW
{
    my ($class, $client) = @_;
    $class->SUPER::NEW($client);
    this->{client} = $client;

    my @envVariables = qw( USERNAME.* USER.* USERDOMAIN.*
                 HOSTNAME.* DOMAINNAME.* );

    my $environment = Qt::Process::systemEnvironment();
    foreach my $string ( @envVariables ) {
        my $index = first_index{ $_ =~ m/$string/ } @{$environment};
        if ($index != -1) {
            my @stringList = split m/=/, $environment->[$index];
            if (scalar @stringList == 2) {
                utf8::decode($stringList[1]);
                this->{username} = Qt::ByteArray($stringList[1]);
                last;
            }
        }
    }

    if (!defined username()) {
        this->{username} = Qt::ByteArray('unknown');
    }

    updateAddresses();
    this->{serverPort} = 0;

    this->{broadcastSocket} = Qt::UdpSocket();
    broadcastSocket()->bind(Qt::HostAddress(Qt::HostAddress::Any()), $broadcastPort, Qt::UdpSocket::ShareAddress()
                         | Qt::UdpSocket::ReuseAddressHint());
    this->connect(broadcastSocket, SIGNAL 'readyRead()',
            this, SLOT 'readBroadcastDatagram()');

    this->{broadcastTimer} = Qt::Timer(this);
    broadcastTimer()->setInterval($BroadcastInterval);
    this->connect(broadcastTimer(), SIGNAL 'timeout()',
            this, SLOT 'sendBroadcastDatagram()');
}

sub setServerPort
{
    my ($port) = @_;
    this->{serverPort} = $port;
}

sub userName
{
    return username();
}

sub startBroadcasting
{
    broadcastTimer()->start();
}

sub isLocalHostAddress
{
    my ($address) = @_;
    foreach my $localAddress ( @{ipAddresses()} ) {
        if ($address == $localAddress) {
            return 1;
        }
    }
    return 0;
}

sub sendBroadcastDatagram
{
    my $datagram = Qt::ByteArray(username);
    $datagram->append('@');
    $datagram->append(Qt::CString(serverPort()));

    my $validBroadcastAddresses = 1;
    foreach my $address ( @{broadcastAddresses()} ) {
        if (broadcastSocket()->writeDatagram($datagram, $address,
                                          $broadcastPort) == -1) {
            $validBroadcastAddresses = 0;
        }
    }

    if (!$validBroadcastAddresses) {
        updateAddresses();
    }
}

sub readBroadcastDatagram
{
    while (broadcastSocket()->hasPendingDatagrams()) {
        my $senderIp = Qt::HostAddress();
        my $senderPort;
        my $datagram = '';
        my $datagramSize = broadcastSocket()->pendingDatagramSize();
        if (broadcastSocket()->readDatagram(\$datagram, $datagramSize,
                                         $senderIp, \$senderPort) == -1) {
            next;
        }

        my @list = split m/@/, $datagram;
        if (scalar @list != 2) {
            next;
        }

        my $senderServerPort = $list[1];
        if (isLocalHostAddress($senderIp) && $senderServerPort == serverPort()) {
            next;
        }

        if (!client->hasConnection($senderIp)) {
            my $connection = Connection(this);
            emit newConnection($connection);
            $connection->connectToHost($senderIp, $senderServerPort);
        }
    }
}

sub updateAddresses
{
    this->{broadcastAddresses} = [];
    this->{ipAddresses} = [];
    foreach my $interface ( @{Qt::NetworkInterface::allInterfaces()} ) {
        foreach my $entry ( @{$interface->addressEntries()} ) {
            my $broadcastAddress = $entry->broadcast();
            if ($broadcastAddress != Qt::HostAddress::Null() && $entry->ip() != Qt::HostAddress::LocalHost()) {
                push @{this->{broadcastAddresses}}, $broadcastAddress;
                push @{this->{ipAddresses}}, $entry->ip();
            }
        }
    }
}

1;
