package RemoteControl;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use Ui_RemoteControlClass;

use QtCore4::isa qw( Qt::MainWindow );

use QtCore4::slots
    on_launchButton_clicked => [],
    on_actionQuit_triggered => [],
    on_indexButton_clicked => [],
    on_identifierButton_clicked => [],
    on_urlButton_clicked => [],
    on_syncContentsButton_clicked => [],
    on_contentsCheckBox_toggled => ['bool'],
    on_indexCheckBox_toggled => ['bool'],
    on_bookmarksCheckBox_toggled => ['bool'],
    helpViewerClosed => [],
    sendCommand => ['const QString &'];

sub NEW
{
    my ($class, $parent, $flags) = @_;
    $class->SUPER::NEW($parent, $flags);

    this->{ui} = Ui_RemoteControlClass->setupUi(this);
    this->connect(this->{ui}->indexLineEdit, SIGNAL 'returnPressed()',
        this, SLOT 'on_indexButton_clicked()');
    this->connect(this->{ui}->identifierLineEdit, SIGNAL 'returnPressed()',
        this, SLOT 'on_identifierButton_clicked()');
    this->connect(this->{ui}->urlLineEdit, SIGNAL 'returnPressed()',
        this, SLOT 'on_urlButton_clicked()');

    my $rc = 'qthelp://com.trolltech.qt.' .
             451 .
             '/qdoc/index.html';
                     #<< (QT_VERSION >> 16) << ((QT_VERSION >> 8) & 0xFF)
                     #<< (QT_VERSION & 0xFF)

    this->{ui}->startUrlLineEdit->setText($rc);

    this->{process} = Qt::Process(this);
    this->connect(this->{process}, SIGNAL 'finished(int, QProcess::ExitStatus)',
        this, SLOT 'helpViewerClosed()');
}

sub ON_DESTROY
{
    if (this->{process}->state() == Qt::Process::Running()) {
        this->{process}->terminate();
        this->{process}->waitForFinished(3000);
    }
}

sub on_actionQuit_triggered()
{
    this->close();
}

sub on_launchButton_clicked
{
    if (this->{process}->state() == Qt::Process::Running()) {
        return;
    }

    my $app = Qt::LibraryInfo::location(Qt::LibraryInfo::BinariesPath())
            . chr Qt::Dir::separator()->toLatin1();
    $app .= 'assistant';


    this->{ui}->contentsCheckBox->setChecked(1);
    this->{ui}->indexCheckBox->setChecked(1);
    this->{ui}->bookmarksCheckBox->setChecked(1);

    my @args = ('-enableRemoteControl');
    this->{process}->start($app, \@args);
    if (!this->{process}->waitForStarted()) {
        Qt::MessageBox::critical(this, this->tr('Remote Control'),
            sprintf this->tr('Could not start Qt Assistant from %s.'), $app);
        return;
    }

    if (this->{ui}->startUrlLineEdit->text()) {
        this->sendCommand('SetSource '
            . this->{ui}->startUrlLineEdit->text());
    }
        
    this->{ui}->launchButton->setEnabled(0);
    this->{ui}->startUrlLineEdit->setEnabled(0);
    this->{ui}->actionGroupBox->setEnabled(1);
}

sub sendCommand
{
    my ($cmd) = @_;
    if (this->{process}->state() != Qt::Process::Running()) {
        return;
    }
    $cmd = Qt::ByteArray( $cmd );
    $cmd->append( "\0", 1 );
    this->{process}->write($cmd);
}

sub on_indexButton_clicked
{
    this->sendCommand('ActivateKeyword '
        . this->{ui}->indexLineEdit->text());
}

sub on_identifierButton_clicked
{
    this->sendCommand('ActivateIdentifier '
        . this->{ui}->identifierLineEdit->text());
}

sub on_urlButton_clicked
{
    this->sendCommand('SetSource '
        . this->{ui}->urlLineEdit->text());
}

sub on_syncContentsButton_clicked
{
    this->sendCommand('SyncContents');
}

sub on_contentsCheckBox_toggled
{
    my ($checked) = @_;
    this->sendCommand($checked ?
        'Show Contents' : 'Hide Contents');
}

sub on_indexCheckBox_toggled
{
    my ($checked) = @_;
    this->sendCommand($checked ?
        'Show Index' : 'Hide Index');
}

sub on_bookmarksCheckBox_toggled
{
    my ($checked) = @_;
    this->sendCommand($checked ?
        'Show Bookmarks' : 'Hide Bookmarks');
}

sub helpViewerClosed
{
    this->{ui}->launchButton->setEnabled(1);
    this->{ui}->startUrlLineEdit->setEnabled(1);
    this->{ui}->actionGroupBox->setEnabled(0);
}

1;
