package Client;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
# [0]
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    requestNewFortune => [],
    readFortune => [],
    displayError => ['QAbstractSocket::SocketError'],
    enableGetFortuneButton => [];

sub hostLabel() {
    return this->{hostLabel};
}

sub portLabel() {
    return this->{portLabel};
}

sub hostLineEdit() {
    return this->{hostLineEdit};
}

sub portLineEdit() {
    return this->{portLineEdit};
}

sub statusLabel() {
    return this->{statusLabel};
}

sub getFortuneButton() {
    return this->{getFortuneButton};
}

sub quitButton() {
    return this->{quitButton};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub tcpSocket() {
    return this->{tcpSocket};
}

sub currentFortune() {
    return this->{currentFortune};
}

sub blockSize() {
    return this->{blockSize};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
# [0]
    $class->SUPER::NEW($parent);
    this->{hostLabel} = Qt::Label(this->tr('&Server name:'));
    this->{portLabel} = Qt::Label(this->tr('S&erver port:'));

    this->{hostLineEdit} = Qt::LineEdit('Localhost');
    this->{portLineEdit} = Qt::LineEdit();
    this->portLineEdit->setValidator(Qt::IntValidator(1, 65535, this));

    this->hostLabel->setBuddy(this->hostLineEdit);
    this->portLabel->setBuddy(this->portLineEdit);

    this->{statusLabel} = Qt::Label(this->tr('This examples requires that you run the ' .
                                'Fortune Server example as well.'));

    this->{getFortuneButton} = Qt::PushButton(this->tr('Get Fortune'));
    getFortuneButton->setDefault(1);
    getFortuneButton->setEnabled(0);

    this->{quitButton} = Qt::PushButton(this->tr('Quit'));

    this->{buttonBox} = Qt::DialogButtonBox();
    this->buttonBox->addButton(this->getFortuneButton, Qt::DialogButtonBox::ActionRole());
    this->buttonBox->addButton(this->quitButton, Qt::DialogButtonBox::RejectRole());

# [1]
    this->{tcpSocket} = Qt::TcpSocket(this);
# [1]

    this->connect(this->hostLineEdit, SIGNAL 'textChanged(const QString &)',
            this, SLOT 'enableGetFortuneButton()');
    this->connect(this->portLineEdit, SIGNAL 'textChanged(const QString &)',
            this, SLOT 'enableGetFortuneButton()');
    this->connect(this->getFortuneButton, SIGNAL 'clicked()',
            this, SLOT 'requestNewFortune()');
    this->connect(this->quitButton, SIGNAL 'clicked()', this, SLOT 'close()');
# [2] //! [3]
    this->connect(this->tcpSocket, SIGNAL 'readyRead()', this, SLOT 'readFortune()');
# [2] //! [4]
    this->connect(this->tcpSocket, SIGNAL 'error(QAbstractSocket::SocketError)',
# [3]
            this, SLOT 'displayError(QAbstractSocket::SocketError)');
# [4]

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(this->hostLabel, 0, 0);
    $mainLayout->addWidget(this->hostLineEdit, 0, 1);
    $mainLayout->addWidget(this->portLabel, 1, 0);
    $mainLayout->addWidget(this->portLineEdit, 1, 1);
    $mainLayout->addWidget(this->statusLabel, 2, 0, 1, 2);
    $mainLayout->addWidget(this->buttonBox, 3, 0, 1, 2);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Fortune Client'));
    this->portLineEdit->setFocus();

    this->{currentFortune} = '';
# [5]
}
# [5]

# [6]
sub requestNewFortune
{
    this->getFortuneButton->setEnabled(0);
    this->{blockSize} = 0;
    this->tcpSocket->abort();
# [7]
    this->tcpSocket->connectToHost(this->hostLineEdit->text(),
                                   this->portLineEdit->text());
# [7]
}
# [6]

# [8]
sub readFortune
{
# [9]
    my $in = Qt::DataStream(this->tcpSocket);
    $in->setVersion(Qt::DataStream::Qt_4_0());

    if (this->blockSize == 0) {
        my $shortSize = length( pack 'S', 0 );
        if (this->tcpSocket->bytesAvailable() < $shortSize) {
            return;
        }
# [8]

# [10]
        no warnings qw(void);
        $in >> Qt::Ushort(this->{blockSize});
        use warnings;
    }

    if (this->tcpSocket->bytesAvailable() < this->blockSize) {
        return;
    }
# [10] //! [11]

    my $nextFortune;
    no warnings qw(void);
    $in >> Qt::String($nextFortune);
    use warnings;

    if ($nextFortune eq this->currentFortune) {
        Qt::Timer::singleShot(0, this, SLOT 'requestNewFortune()');
        return;
    }
# [11]

# [12]
    this->{currentFortune} = $nextFortune;
# [9]
    this->statusLabel->setText(this->currentFortune);
    this->getFortuneButton->setEnabled(1);
}
# [12]

# [13]
sub displayError
{
    my ($socketError) = @_;
    if ($socketError == Qt::AbstractSocket::RemoteHostClosedError()) {
    }
    elsif ($socketError == Qt::AbstractSocket::HostNotFoundError()) {
        Qt::MessageBox::information(this, this->tr('Fortune Client'),
                                 this->tr('The host was not found. Please check the ' .
                                    'host name and port settings.'));
    }
    elsif ($socketError == Qt::AbstractSocket::ConnectionRefusedError()) {
        Qt::MessageBox::information(this, this->tr('Fortune Client'),
                                 this->tr('The connection was refused by the peer. ' .
                                    'Make sure the fortune server is running, ' .
                                    'and check that the host name and port ' .
                                    'settings are correct.'));
    }
    else {
        Qt::MessageBox::information(this, this->tr('Fortune Client'),
                            sprintf this->tr('The following error occurred: %s.'),
                                    this->tcpSocket->errorString());
    }

    this->getFortuneButton->setEnabled(1);
}
# [13]

sub enableGetFortuneButton
{
    this->getFortuneButton->setEnabled(this->hostLineEdit->text()
                                    && this->portLineEdit->text());
}

1;
