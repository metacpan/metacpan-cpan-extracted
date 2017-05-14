package Connection;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtNetwork4;
use QtCore4::isa qw( Qt::TcpSocket );
use QtCore4::signals
    readyForUse => [],
    newMessage => ['const QString &', 'const QString &'];
use QtCore4::slots
    processReadyRead => [],
    sendPing => [],
    sendGreetingMessage => [];

my $MaxBufferSize = 1024000;

use constant {
    WaitingForGreeting => 0,
    ReadingGreeting => 1,
    ReadyForUse => 2,
};

use constant {
    PlainText => 0,
    Ping => 1,
    Pong => 2,
    Greeting => 3,
    Undefined => 4,
};

sub greetingMessage() {
    return this->{greetingMessage};
}

sub username() {
    return this->{username};
}

sub pingTimer() {
    return this->{pingTimer};
}

sub pongTime() {
    return this->{pongTime};
}

sub buffer() {
    return this->{buffer};
}

sub state() {
    return this->{state};
}

sub currentDataType() {
    return this->{currentDataType};
}

sub numBytesForCurrentDataType() {
    return this->{numBytesForCurrentDataType};
}

sub transferTimerId() {
    return this->{transferTimerId};
}

sub isGreetingMessageSent() {
    return this->{isGreetingMessageSent};
}

my $TransferTimeout = 30 * 1000;
my $PongTimeout = 60 * 1000;
my $PingInterval = 5 * 1000;
my $SeparatorToken = ' ';

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{greetingMessage} = this->tr('undefined');
    this->{username} = this->tr('unknown');
    this->{state} = WaitingForGreeting;
    this->{currentDataType} = Undefined;
    this->{numBytesForCurrentDataType} = -1;
    this->{transferTimerId} = undef;
    this->{isGreetingMessageSent} = 0;
    this->{buffer} = Qt::ByteArray();
    this->{pingTimer} = Qt::Timer();
    this->{pongTime} = Qt::Time();
    pingTimer->setInterval($PingInterval);

    Qt::Object::connect(this, SIGNAL 'readyRead()', this, SLOT 'processReadyRead()');
    Qt::Object::connect(this, SIGNAL 'disconnected()', pingTimer, SLOT 'stop()');
    Qt::Object::connect(pingTimer, SIGNAL 'timeout()', this, SLOT 'sendPing()');
    Qt::Object::connect(this, SIGNAL 'connected()',
                     this, SLOT 'sendGreetingMessage()');
}

sub name
{
    return username;
}

sub setGreetingMessage
{
    my ($message) = @_;
    this->{greetingMessage} = $message->constData();
}

sub sendMessage
{
    my ($message) = @_;
    if (!defined $message) {
        return 0;
    }
    utf8::decode($message);
    my $msg = Qt::ByteArray($message);
    my $data = Qt::ByteArray('MESSAGE ' . $msg->size() . ' ') + $msg;
    return this->write($data) == $data->size();
}

sub timerEvent
{
    my ($timerEvent) = @_;
    if ($timerEvent->timerId() == transferTimerId) {
        abort();
        killTimer(transferTimerId);
        this->{transferTimerId} = undef;
    }
}

sub processReadyRead
{
    if (state() == WaitingForGreeting) {
        if (!readProtocolHeader()) {
            return;
        }
        if (currentDataType() != Greeting) {
            abort();
            return;
        }
        this->{state} = ReadingGreeting;
    }

    if (state() == ReadingGreeting) {
        if (!hasEnoughData()) {
            return;
        }

        this->{buffer} = this->read(numBytesForCurrentDataType);
        if (buffer()->size() != numBytesForCurrentDataType) {
            abort();
            return;
        }

        this->{username} = buffer->constData . '@' . peerAddress()->toString() . ':'
                   . peerPort();
        this->{currentDataType} = Undefined;
        this->{numBytesForCurrentDataType} = 0;
        buffer()->clear();

        if (!isValid()) {
            abort();
            return;
        }

        if (!isGreetingMessageSent()) {
            sendGreetingMessage();
        }

        pingTimer()->start();
        pongTime()->start();
        this->{state} = ReadyForUse;
        emit readyForUse();
    }

    do {
        if (currentDataType() == Undefined) {
            if (!readProtocolHeader()) {
                return;
            }
        }
        if (!hasEnoughData()) {
            return;
        }
        processData();
    } while (bytesAvailable() > 0);
}

sub sendPing
{
    if (pongTime->elapsed() > $PongTimeout) {
        abort();
        return;
    }

    this->write('PING 1 p');
}

sub sendGreetingMessage
{
    my $greeting = greetingMessage();
    utf8::decode($greeting);
    my $data = Qt::ByteArray('GREETING ' . length($greeting) . ' ' . $greeting);
    if (this->write($data) == $data->size()) {
        this->{isGreetingMessageSent} = 1;
    }
}

sub readDataIntoBuffer
{
    my ($maxSize) = @_;
    $maxSize = $MaxBufferSize if !defined $maxSize;
    if ($maxSize > $MaxBufferSize) {
        return 0;
    }

    my $numBytesBeforeRead = buffer()->size();
    if ($numBytesBeforeRead == $MaxBufferSize) {
        abort();
        return 0;
    }

    while (bytesAvailable() > 0 && buffer()->size() < $maxSize) {
        buffer->append(this->read(1));
        if (buffer->endsWith($SeparatorToken)) {
            last;
        }
    }
    return buffer->size() - $numBytesBeforeRead;
}

sub dataLengthForCurrentDataType
{
    if (bytesAvailable() <= 0 || readDataIntoBuffer() <= 0
            || !buffer()->endsWith($SeparatorToken)) {
        return 0;
    }

    buffer()->chop(1);
    my $number = buffer()->toInt();
    buffer()->clear();
    return $number;
}

sub readProtocolHeader
{
    if (transferTimerId()) {
        killTimer(transferTimerId);
        this->{transferTimerId} = undef;
    }

    if (readDataIntoBuffer() <= 0) {
        this->{transferTimerId} = startTimer($TransferTimeout);
        return 0;
    }

    if (buffer() == 'PING ') {
        this->{currentDataType} = Ping;
    } elsif (buffer() == 'PONG ') {
        this->{currentDataType} = Pong;
    } elsif (buffer() == 'MESSAGE ') {
        this->{currentDataType} = PlainText;
    } elsif (buffer() == 'GREETING ') {
        this->{currentDataType} = Greeting;
    } else {
        this->{currentDataType} = Undefined;
        abort();
        return 0;
    }

    buffer()->clear();
    this->{numBytesForCurrentDataType} = dataLengthForCurrentDataType();
    return 1;
}

sub hasEnoughData
{
    if (transferTimerId()) {
        Qt::Object::killTimer(transferTimerId);
        this->{transferTimerId} = undef;
    }

    if (numBytesForCurrentDataType() <= 0) {
        this->{numBytesForCurrentDataType} = dataLengthForCurrentDataType();
    }

    if (bytesAvailable() < numBytesForCurrentDataType()
            || numBytesForCurrentDataType() <= 0) {
        this->{transferTimerId} = startTimer($TransferTimeout);
        return 0;
    }

    return 1;
}

sub processData
{
    this->{buffer} = this->read(numBytesForCurrentDataType());
    if (buffer()->size() != numBytesForCurrentDataType()) {
        abort();
        return;
    }

    if ( currentDataType() == PlainText ) {
        my $message = buffer->data();
        utf8::decode($message);
        emit newMessage(username(), $message);
    }
    elsif ( currentDataType() == Ping ) {
        this->write('PONG 1 p');
    }
    elsif ( currentDataType() == Pong ) {
        pongTime->restart();
    }

    this->{currentDataType} = Undefined;
    this->{numBytesForCurrentDataType} = 0;
    buffer()->clear();
}

1;
