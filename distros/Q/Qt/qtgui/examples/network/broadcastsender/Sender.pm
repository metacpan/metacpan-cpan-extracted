package Sender;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    startBroadcasting => [],
    broadcastDatagram => [];

sub statusLabel() {
    return this->{statusLabel};
}

sub startButton() {
    return this->{startButton};
}

sub quitButton() {
    return this->{quitButton};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub udpSocket() {
    return this->{udpSocket};
}

sub timer() {
    return this->{timer};
}

sub messageNo() {
    return this->{messageNo};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{statusLabel} = Qt::Label(this->tr('Ready to broadcast datagrams on port 45454'));

    this->{startButton} = Qt::PushButton(this->tr('&Start'));
    this->{quitButton} = Qt::PushButton(this->tr('&Quit'));

    this->{buttonBox} = Qt::DialogButtonBox();
    this->buttonBox->addButton(this->startButton, Qt::DialogButtonBox::ActionRole());
    this->buttonBox->addButton(this->quitButton, Qt::DialogButtonBox::RejectRole());

    this->{timer} = Qt::Timer(this);
# [0]
    this->{udpSocket} = Qt::UdpSocket(this);
# [0]
    this->{messageNo} = 1;

    this->connect(this->startButton, SIGNAL 'clicked()', this, SLOT 'startBroadcasting()');
    this->connect(this->quitButton, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect(this->timer, SIGNAL 'timeout()', this, SLOT 'broadcastDatagram()');

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->statusLabel);
    $mainLayout->addWidget(this->buttonBox);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Broadcast Sender'));
}

sub startBroadcasting
{
    this->startButton->setEnabled(0);
    timer->start(1000);
}

sub broadcastDatagram
{
    this->statusLabel->setText(sprintf this->tr('Now broadcasting datagram %s'), this->messageNo);
# [1]
    my $datagram = Qt::ByteArray('Broadcast message ' . this->messageNo);
    udpSocket->writeDatagram($datagram->data(), $datagram->size(),
                             Qt::HostAddress(Qt::HostAddress::Broadcast()), 45454);
# [1]
    ++this->{messageNo};
}

1;
