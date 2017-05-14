package SslClient;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    updateEnabledState => [],
    secureConnect => [],
    socketStateChanged => ['QAbstractSocket::SocketState'],
    socketEncrypted => [],
    socketReadyRead => [],
    sendData => [],
    sslErrors => ['const QList<QSslError> &'],
    displayCertificateInfo => [];
use CertificateInfo;
use Ui_Form;
use Ui_SslErrors;

sub socket() {
    return this->{socket};
}

sub padLock() {
    return this->{padLock};
}

sub form() {
    return this->{form};
}

sub executingDialog() {
    return this->{executingDialog};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{executingDialog} = 0;
    this->{form} = Ui_Form->setupUi(this);
    form->hostNameEdit->setSelection(0, length form->hostNameEdit->text());
    form->sessionOutput->setHtml(this->tr('&lt;not connected&gt;'));

    this->connect(form->hostNameEdit, SIGNAL 'textChanged(QString)',
            this, SLOT 'updateEnabledState()');
    this->connect(form->connectButton, SIGNAL 'clicked()',
            this, SLOT 'secureConnect()');
    this->connect(form->sendButton, SIGNAL 'clicked()',
            this, SLOT 'sendData()');
}

sub updateEnabledState
{
    my $unconnected = !defined this->socket() || this->socket()->state() == Qt::AbstractSocket::UnconnectedState();

    form->hostNameEdit->setReadOnly(!$unconnected);
    form->hostNameEdit->setFocusPolicy($unconnected ? Qt::StrongFocus() : Qt::NoFocus());

    form->hostNameLabel->setEnabled($unconnected);
    form->portBox->setEnabled($unconnected);
    form->portLabel->setEnabled($unconnected);
    form->connectButton->setEnabled($unconnected && form->hostNameEdit->text());

    my $connected = defined this->socket() && this->socket->state() == Qt::AbstractSocket::ConnectedState();
    form->sessionBox->setEnabled($connected);
    form->sessionOutput->setEnabled($connected);
    form->sessionInput->setEnabled($connected);
    form->sessionInputLabel->setEnabled($connected);
    form->sendButton->setEnabled($connected);
}

sub secureConnect
{
    if (!defined this->socket()) {
        this->{socket} = Qt::SslSocket(this);
        this->connect(this->socket, SIGNAL 'stateChanged(QAbstractSocket::SocketState)',
                this, SLOT 'socketStateChanged(QAbstractSocket::SocketState)');
        this->connect(this->socket, SIGNAL 'encrypted()',
                this, SLOT 'socketEncrypted()');
        this->connect(this->socket, SIGNAL 'sslErrors(QList<QSslError>)',
                this, SLOT 'sslErrors(QList<QSslError>)');
        this->connect(this->socket, SIGNAL 'readyRead()',
                this, SLOT 'socketReadyRead()');
    }

    this->socket()->connectToHostEncrypted(form->hostNameEdit->text(), form->portBox->value());
    updateEnabledState();
}

sub socketStateChanged
{
    my ($state) = @_;
    if (executingDialog) {
        return;
    }

    updateEnabledState();
    if ($state == Qt::AbstractSocket::UnconnectedState()) {
        form->hostNameEdit->setPalette(Qt::Palette());
        form->hostNameEdit->setFocus();
        form->cipherLabel->setText(this->tr('<none>'));
        if (defined padLock()) {
            padLock->hide();
        }
        this->socket->deleteLater();
        this->{socket} = undef;
    }
}

sub socketEncrypted
{
    if (!defined this->socket) {
        return;                 # might have disconnected already
    }

    form->sessionOutput->clear();
    form->sessionInput->setFocus();

    my $palette = Qt::Palette();
    $palette->setColor(Qt::Palette::Base(), Qt::Color(255, 255, 192));
    form->hostNameEdit->setPalette($palette);

    my $ciph = this->socket->sessionCipher();
    my $cipher = sprintf '%s, %s (%s/%s)', $ciph->authenticationMethod(),
                     $ciph->name(), $ciph->usedBits(), $ciph->supportedBits();
    form->cipherLabel->setText($cipher);

    if (!defined padLock) {
        this->{padLock} = Qt::ToolButton();
        padLock->setIcon(Qt::Icon(':/encrypted.png'));
        padLock->setCursor(Qt::Cursor(Qt::ArrowCursor()));
        padLock->setToolTip(this->tr('Display encryption details.'));

        my $extent = form->hostNameEdit->height() - 2;
        padLock->resize($extent, $extent);
        padLock->setSizePolicy(Qt::SizePolicy::Fixed(), Qt::SizePolicy::Ignored());

        my $layout = Qt::HBoxLayout(form->hostNameEdit);
        $layout->setMargin(form->hostNameEdit->style()->pixelMetric(Qt::Style::PM_DefaultFrameWidth()));
        $layout->setSpacing(0);
        $layout->addStretch();
        $layout->addWidget(padLock);

        form->hostNameEdit->setLayout($layout);

        this->connect(padLock, SIGNAL 'clicked()',
                this, SLOT 'displayCertificateInfo()');
    } else {
        padLock->show();
    }
}

sub socketReadyRead
{
    my $readAll = this->socket()->readAll();
    utf8::encode($readAll);
    appendString($readAll);
}

sub sendData
{
    my $input = form->sessionInput->text();
    appendString($input . "\n");
    utf8::decode($input);
    this->socket->write($input . "\r\n");
    form->sessionInput->clear();
}

sub sslErrors
{
    my ($errors) = @_;
    my $errorDialog = Qt::Dialog(this);
    my $ui = Ui_SslErrors->setupUi($errorDialog);
    this->connect($ui->certificateChainButton, SIGNAL 'clicked()',
            this, SLOT 'displayCertificateInfo()');

    foreach my $error ( @{$errors} ) {
        $ui->sslErrorList->addItem($error->errorString());
    }

    this->{executingDialog} = 1;
    if ($errorDialog->exec() == Qt::Dialog::Accepted()) {
        this->socket->ignoreSslErrors();
    }
    this->{executingDialog} = 0;

    # did the socket state change?
    if (this->socket->state() != Qt::AbstractSocket::ConnectedState()) {
        socketStateChanged(this->socket->state());
    }
}

sub displayCertificateInfo
{
    my $info = CertificateInfo(this);
    $info->setCertificateChain(this->socket->peerCertificateChain());
    $info->exec();
    #$info->deleteLater();
}

sub appendString
{
    my ($line) = @_;
    my $cursor = Qt::TextCursor(form->sessionOutput->textCursor());
    $cursor->movePosition(Qt::TextCursor::End());
    $cursor->insertText($line);
    form->sessionOutput->verticalScrollBar()->setValue(form->sessionOutput->verticalScrollBar()->maximum());
}

1;
