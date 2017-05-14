package Dialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    start => [],
    acceptConnection => [],
    startTransfer => [],
    updateServerProgress => [],
    updateClientProgress => ['qint64'],
    displayError => ['QAbstractSocket::SocketError'];
use List::Util qw( min );

sub clientProgressBar() {
    return this->{clientProgressBar};
}

sub serverProgressBar() {
    return this->{serverProgressBar};
}

sub clientStatusLabel() {
    return this->{clientStatusLabel};
}

sub serverStatusLabel() {
    return this->{serverStatusLabel};
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

sub tcpServer() {
    return this->{tcpServer};
}

sub tcpClient() {
    return this->{tcpClient};
}

sub tcpServerConnection() {
    return this->{tcpServerConnection};
}

sub bytesToWrite() {
    return this->{bytesToWrite};
}

sub bytesWritten() {
    return this->{bytesWritten};
}

sub bytesReceived() {
    return this->{bytesReceived};
}
    #Qt::TcpServer tcpServer;
    #Qt::TcpSocket tcpClient;
    #int bytesToWrite;
    #int bytesWritten;
    #int bytesReceived;

my $TotalBytes = 50 * 1024 * 1024;
my $PayloadSize = 65536;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{tcpServer} = Qt::TcpServer(undef);
    this->{tcpClient} = Qt::TcpSocket(undef);
    this->{clientProgressBar} = Qt::ProgressBar();
    this->{clientStatusLabel} = Qt::Label(this->tr('Client ready'));
    this->{serverProgressBar} = Qt::ProgressBar();
    this->{serverStatusLabel} = Qt::Label(this->tr('Server ready'));

    this->{startButton} = Qt::PushButton(this->tr('&Start'));
    this->{quitButton} = Qt::PushButton(this->tr('&Quit'));

    this->{buttonBox} = Qt::DialogButtonBox();
    buttonBox->addButton(startButton, Qt::DialogButtonBox::ActionRole());
    buttonBox->addButton(quitButton, Qt::DialogButtonBox::RejectRole());

    this->connect(startButton, SIGNAL 'clicked()', this, SLOT 'start()');
    this->connect(quitButton, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect(tcpServer, SIGNAL 'newConnection()',
            this, SLOT 'acceptConnection()');
    this->connect(tcpClient, SIGNAL 'connected()', this, SLOT 'startTransfer()');
    this->connect(tcpClient, SIGNAL 'bytesWritten(qint64)',
            this, SLOT 'updateClientProgress(qint64)');
    this->connect(tcpClient, SIGNAL 'error(QAbstractSocket::SocketError)',
            this, SLOT 'displayError(QAbstractSocket::SocketError)');

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(clientProgressBar);
    $mainLayout->addWidget(clientStatusLabel);
    $mainLayout->addWidget(serverProgressBar);
    $mainLayout->addWidget(serverStatusLabel);
    $mainLayout->addStretch(1);
    $mainLayout->addSpacing(10);
    $mainLayout->addWidget(buttonBox);
    this->setLayout($mainLayout);

    setWindowTitle(this->tr('Loopback'));
}

sub start
{
    startButton->setEnabled(0);

#ifndef QT_NO_CURSOR
    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
#endif

    this->{bytesWritten} = 0;
    this->{bytesReceived} = 0;

    while (!tcpServer->isListening() && !tcpServer->listen()) {
        my $ret = Qt::MessageBox::critical(this,
                                        this->tr('Loopback'),
                               sprintf( this->tr('Unable to start the test: %s.'),
					tcpServer->errorString() ),
                                        Qt::MessageBox::Retry()
					| Qt::MessageBox::Cancel());
        if ($ret == Qt::MessageBox::Cancel()) {
            return;
        }
    }

    serverStatusLabel->setText(this->tr('Listening'));
    clientStatusLabel->setText(this->tr('Connecting'));
    tcpClient->connectToHost(Qt::HostAddress(Qt::HostAddress::LocalHost()), tcpServer->serverPort());
}

sub acceptConnection
{
    this->{tcpServerConnection} = tcpServer->nextPendingConnection();
    this->connect(tcpServerConnection, SIGNAL 'readyRead()',
            this, SLOT 'updateServerProgress()');
    this->connect(tcpServerConnection, SIGNAL 'error(QAbstractSocket::SocketError)',
            this, SLOT 'displayError(QAbstractSocket::SocketError)');

    serverStatusLabel->setText(this->tr('Accepted connection'));
    tcpServer->close();
}

sub startTransfer
{
    this->{bytesToWrite} = $TotalBytes - sprintf '%d', tcpClient->write(Qt::ByteArray($PayloadSize, '@'));
    clientStatusLabel->setText(this->tr('Connected'));
}

sub updateServerProgress
{
    this->{bytesReceived} += sprintf '%d', tcpServerConnection->bytesAvailable();
    tcpServerConnection->readAll();

    serverProgressBar->setMaximum($TotalBytes);
    serverProgressBar->setValue(bytesReceived);
    serverStatusLabel->setText(sprintf this->tr('Received %dMB'),
                               (bytesReceived / (1024 * 1024)));

    if (bytesReceived == $TotalBytes) {
        tcpServerConnection->close();
        startButton->setEnabled(1);
#ifndef QT_NO_CURSOR
        Qt::Application::restoreOverrideCursor();
#endif
    }
}

sub updateClientProgress
{
    my ($numBytes) = @_;
    this->{bytesWritten} += sprintf '%d', $numBytes;
    if (bytesToWrite > 0) {
        this->{bytesToWrite} -= sprintf '%d', tcpClient->write(Qt::ByteArray(min(bytesToWrite, $PayloadSize), '@'));
    }

    clientProgressBar->setMaximum($TotalBytes);
    clientProgressBar->setValue(bytesWritten);
    clientStatusLabel->setText(sprintf this->tr('Sent %dMB'),
                               bytesWritten / (1024 * 1024));
}

sub displayError
{
    my ($socketError) = @_;
    if ($socketError == Qt::TcpSocket::RemoteHostClosedError()) {
        return;
    }

    Qt::MessageBox::information(this, this->tr('Network error'),
                     sprintf this->tr('The following error occurred: %s.'),
                             tcpClient->errorString());

    tcpClient->close();
    tcpServer->close();
    clientProgressBar->reset();
    serverProgressBar->reset();
    clientStatusLabel->setText(this->tr('Client ready'));
    serverStatusLabel->setText(this->tr('Server ready'));
    startButton->setEnabled(1);
#ifndef QT_NO_CURSOR
    Qt::Application::restoreOverrideCursor();
#endif
}

1;
