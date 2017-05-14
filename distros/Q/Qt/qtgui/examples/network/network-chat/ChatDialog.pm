package ChatDialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Ui_ChatDialog;
use Client;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    appendMessage => ['const QString &', 'const QString &'],
    returnPressed => [],
    newParticipant => ['const QString &'],
    participantLeft => ['const QString &'],
    showInformation => [];

sub client() {
    return this->{client};
}

sub myNickName() {
    return this->{myNickName};
}

sub tableFormat() {
    return this->{tableFormat};
}

sub ui() {
    return this->{ui};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{client} = Client();
    this->{tableFormat} = Qt::TextTableFormat();
    this->{ui} = Ui_ChatDialog->setupUi(this);

    ui->lineEdit->setFocusPolicy(Qt::StrongFocus());
    ui->textEdit->setFocusPolicy(Qt::NoFocus());
    ui->textEdit->setReadOnly(1);
    ui->listWidget->setFocusPolicy(Qt::NoFocus());

    this->connect(ui->lineEdit, SIGNAL 'returnPressed()', this, SLOT 'returnPressed()');
    this->connect(client, SIGNAL 'newMessage(QString,QString)',
            this, SLOT 'appendMessage(QString,QString)');
    this->connect(client, SIGNAL 'newParticipant(QString)',
            this, SLOT 'newParticipant(QString)');
    this->connect(client, SIGNAL 'participantLeft(QString)',
            this, SLOT 'participantLeft(QString)');

    this->{myNickName} = client->nickName();
    newParticipant(myNickName);
    tableFormat->setBorder(0);
    Qt::Timer::singleShot(10 * 1000, this, SLOT 'showInformation()');
}

sub appendMessage
{
    my ($from, $message) = @_;
    if (!defined $from || !defined $message) {
        return;
    }

    my $cursor = Qt::TextCursor(ui->textEdit->textCursor());
    $cursor->movePosition(Qt::TextCursor::End());
    my $table = $cursor->insertTable(1, 2, tableFormat);
    $table->cellAt(0, 0)->firstCursorPosition()->insertText('<' . $from . '> ');
    $table->cellAt(0, 1)->firstCursorPosition()->insertText($message);
    my $bar = ui->textEdit->verticalScrollBar();
    $bar->setValue($bar->maximum());
}

sub returnPressed
{
    my $text = ui->lineEdit->text();
    if (!defined $text) {
        return;
    }

    if ($text =~ m#^/#) {
        my $color = ui->textEdit->textColor();
        ui->textEdit->setTextColor(Qt::Color(Qt::red()));
        $text =~ s/ .*//g;
        ui->textEdit->append(this->tr('! Unknown command: ') . $text);
        ui->textEdit->setTextColor($color);
    } else {
        client->sendMessage($text);
        appendMessage(myNickName, $text);
    }

    ui->lineEdit->clear();
}

sub newParticipant
{
    my ($nick) = @_;
    if (!defined $nick) {
        return;
    }

    my $color = ui->textEdit->textColor();
    ui->textEdit->setTextColor(Qt::Color(Qt::gray()));
    ui->textEdit->append( '* ' . $nick . this->tr('has joined'));
    ui->textEdit->setTextColor($color);
    ui->listWidget->addItem($nick);
}

sub participantLeft
{
    my ($nick) = @_;
    if (!defined $nick) {
        return;
    }

    my $items = ui->listWidget->findItems($nick, Qt::MatchExactly());
    if (!defined $items) {
        return;
    }

    ui->listWidget->removeItemWidget( $items->[0] );
    my $color = ui->textEdit->textColor();
    ui->textEdit->setTextColor(Qt::Color(Qt::gray()));
    ui->textEdit->append( '* ' . $nick . this->tr('has left'));
    ui->textEdit->setTextColor($color);
}

sub showInformation
{
    if (ui->listWidget->count() == 1) {
        Qt::MessageBox::information(this, this->tr('Chat'),
                                 this->tr('Launch several instances of this ' .
                                    'program on your local network and ' .
                                    'start chatting!'));
    }
}

1;
