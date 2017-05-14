package Server;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
# [0]
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    sendFortune => [];

sub statusLabel() {
    return this->{statusLabel};
}

sub quitButton() {
    return this->{quitButton};
}

sub tcpServer() {
    return this->{tcpServer};
}

sub fortunes() {
    return this->{fortunes};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{statusLabel} = Qt::Label();
    this->{quitButton} = Qt::PushButton(this->tr('Quit'));
    this->quitButton->setAutoDefault(0);

# [0] //! [1]
    this->{tcpServer} = Qt::TcpServer(this);
    if (!tcpServer->listen()) {
        Qt::MessageBox::critical(this, this->tr('Fortune Server'),
                         sprintf this->tr('Unable to start the server: %s.'),
                                 this->tcpServer->errorString());
        this->close();
        return;
    }
# [0]

    this->statusLabel->setText(sprintf this->tr("The server is running on port %s.\n" .
                               'Run the Fortune Client example now.'),
                               this->tcpServer->serverPort());
# [1]

# [2]
    this->{fortunes} = [
        this->tr('You\'ve been leading a dog\'s life. Stay off the furniture.'),
        this->tr('You\'ve got to think about tomorrow.'),
        this->tr('You will be surprised by a loud noise.'),
        this->tr('You will feel hungry again in another hour.'),
        this->tr('You might have mail.'),
        this->tr('You cannot kill time without injuring eternity.'),
        this->tr('Computers are not intelligent. They only think they are.'),
    ];
# [2]

    this->connect(this->quitButton, SIGNAL 'clicked()', this, SLOT 'close()');
# [3]
    this->connect(this->tcpServer, SIGNAL 'newConnection()', this, SLOT 'sendFortune()');
# [3]

    my $buttonLayout = Qt::HBoxLayout();
    $buttonLayout->addStretch(1);
    $buttonLayout->addWidget(this->quitButton);
    $buttonLayout->addStretch(1);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->statusLabel);
    $mainLayout->addLayout($buttonLayout);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Fortune Server'));
}

# [4]
sub sendFortune
{
# [5]
    my $block = Qt::ByteArray();
    my $out = Qt::DataStream($block, Qt::IODevice::WriteOnly());
    $out->setVersion(Qt::DataStream::Qt_4_0());
    my $shortSize = length( pack 'S', 0 );
# [4] //! [6]
    no warnings qw(void);
    $out << Qt::Ushort(0);
    $out << Qt::String(this->fortunes->[rand($#{this->fortunes})]);
    $out->device()->seek(0);
    $out << Qt::Ushort($block->size() - $shortSize);
    use warnings;
# [6] //! [7]

    my $clientConnection = this->tcpServer->nextPendingConnection();
    this->connect($clientConnection, SIGNAL 'disconnected()',
            $clientConnection, SLOT 'deleteLater()');
# [7] //! [8]

    $clientConnection->write($block);
    $clientConnection->disconnectFromHost();
# [5]
}
# [8]

1;
