package Client;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;

use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    requestNewFortune => [],
    readFortune => [],
    displayError => ['QLocalSocket::LocalSocketError'],
    enableGetFortuneButton => [];

sub hostLabel() {
    return this->{hostLabel};
}

sub hostLineEdit() {
    return this->{hostLineEdit};
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

sub socket() {
    return this->{socket};
}

sub currentFortune() {
    return this->{currentFortune};
}

sub blockSize() {
    return this->{blockSize};
}

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{currentFortune} = '';
    this->{hostLabel} = Qt::Label(this->tr('&Server name:'));
    this->{hostLineEdit} = Qt::LineEdit('fortune');

    hostLabel->setBuddy(hostLineEdit);

    this->{statusLabel} = Qt::Label(this->tr('This examples requires that you run the ' .
                                'Fortune Server example as well.'));

    this->{getFortuneButton} = Qt::PushButton(this->tr('Get Fortune'));
    getFortuneButton->setDefault(1);

    this->{quitButton} = Qt::PushButton(this->tr('Quit'));

    this->{buttonBox} = Qt::DialogButtonBox();
    buttonBox->addButton(getFortuneButton, Qt::DialogButtonBox::ActionRole());
    buttonBox->addButton(quitButton, Qt::DialogButtonBox::RejectRole());

    this->{socket} = Qt::LocalSocket(this);

    this->connect(hostLineEdit, SIGNAL 'textChanged(QString)',
            this, SLOT 'enableGetFortuneButton()');
    this->connect(getFortuneButton, SIGNAL 'clicked()',
            this, SLOT 'requestNewFortune()');
    this->connect(quitButton, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect(this->socket(), SIGNAL 'readyRead()', this, SLOT 'readFortune()');
    this->connect(this->socket(), SIGNAL 'error(QLocalSocket::LocalSocketError)',
            this, SLOT 'displayError(QLocalSocket::LocalSocketError)');

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(hostLabel(), 0, 0);
    $mainLayout->addWidget(hostLineEdit(), 0, 1);
    $mainLayout->addWidget(statusLabel(), 2, 0, 1, 2);
    $mainLayout->addWidget(buttonBox(), 3, 0, 1, 2);
    this->setLayout($mainLayout);

    setWindowTitle(this->tr('Fortune Client'));
    hostLineEdit()->setFocus();
}

sub requestNewFortune
{
    getFortuneButton->setEnabled(0);
    this->{blockSize} = 0;
    this->socket()->abort();
    this->socket()->connectToServer(hostLineEdit->text());
}

sub readFortune
{
    my $in = Qt::DataStream(this->socket());
    $in->setVersion(Qt::DataStream::Qt_4_0());

    if (this->{blockSize} == 0) {
        my $uint16size = length( pack 'S', 0 );
        if (this->socket()->bytesAvailable() < $uint16size) {
            return;
        }
        no warnings qw( void );
        $in >> Qt::Ushort(this->{blockSize});
        use warnings;
    }

    if ($in->atEnd()) {
        return;
    }

    my $nextFortune;
    no warnings qw( void );
    $in >> Qt::String($nextFortune);
    use warnings;

    if ($nextFortune eq currentFortune()) {
        Qt::Timer::singleShot(0, this, SLOT 'requestNewFortune()');
        return;
    }

    this->{currentFortune} = $nextFortune;
    statusLabel->setText(currentFortune());
    getFortuneButton()->setEnabled(1);
}

sub displayError
{
    my ($socketError) = @_;
    if ($socketError == Qt::LocalSocket::ServerNotFoundError()) {
        Qt::MessageBox::information(this, this->tr('Fortune Client'),
                                 this->tr('The host was not found. Please check the '.
                                    'host name and port settings.'));
    }
    elsif ($socketError == Qt::LocalSocket::ConnectionRefusedError()) {
        Qt::MessageBox::information(this, this->tr('Fortune Client'),
                                 this->tr('The connection was refused by the peer. '.
                                    'Make sure the fortune server is running, '.
                                    'and check that the host name and port '.
                                    'settings are correct.'));
    }
    elsif ($socketError == Qt::LocalSocket::PeerClosedError()) {
    }
    else {
        Qt::MessageBox::information(this, this->tr('Fortune Client'),
                                 sprintf this->tr('The following error occurred: %s.'),
                                 this->socket()->errorString());
    }

    getFortuneButton->setEnabled(1);
}

sub enableGetFortuneButton
{
    getFortuneButton->setEnabled(defined hostLineEdit->text());
}

1;
