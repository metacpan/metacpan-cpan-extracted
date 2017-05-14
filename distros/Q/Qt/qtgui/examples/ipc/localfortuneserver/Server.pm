package Server;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    sendFortune => [];
use constant { RAND_MAX => 2147483647 };

sub statusLabel() {
    return this->{statusLabel};
}

sub quitButton() {
    return this->{quitButton};
}

sub server() {
    return this->{server};
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
    quitButton->setAutoDefault(0);

    this->{server} = Qt::LocalServer(this);
    if (!server->listen('fortune')) {
        Qt::MessageBox::critical(this, this->tr('Fortune Server'),
                      sprintf this->tr('Unable to start the server: %s.'),
                              server->errorString());
        this->close();
        return;
    }

    statusLabel->setText(this->tr("The server is running.\n" .
                            'Run the Fortune Client example now.'));

    this->{fortunes} = [
             this->tr('You\'ve been leading a dog\'s life. Stay off the furniture.'),
             this->tr('You\'ve got to think about tomorrow.'),
             this->tr('You will be surprised by a loud noise.'),
             this->tr('You will feel hungry again in another hour.'),
             this->tr('You might have mail.'),
             this->tr('You cannot kill time without injuring eternity.'),
             this->tr('Computers are not intelligent. They only think they are.')
     ];

    this->connect(quitButton, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect(server, SIGNAL 'newConnection()', this, SLOT 'sendFortune()');

    my $buttonLayout = Qt::HBoxLayout();
    $buttonLayout->addStretch(1);
    $buttonLayout->addWidget(quitButton);
    $buttonLayout->addStretch(1);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(statusLabel);
    $mainLayout->addLayout($buttonLayout);
    this->setLayout($mainLayout);

    setWindowTitle(this->tr('Fortune Server'));
}

sub sendFortune
{
    my $block = Qt::ByteArray();
    my $out = Qt::DataStream($block, Qt::IODevice::WriteOnly());
    $out->setVersion(Qt::DataStream::Qt_4_0());
    $out << Qt::Ushort(0);
    $out << Qt::String(fortunes->[rand(RAND_MAX) % scalar @{fortunes()}]);
    $out->device()->seek(0);
    $out << Qt::Ushort($block->size() - length(pack('S',0)));

    my $clientConnection = server->nextPendingConnection();

    $clientConnection->write($block);
    $clientConnection->flush();
    $clientConnection->disconnectFromServer();
}

1;
