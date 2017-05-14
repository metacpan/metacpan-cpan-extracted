package Assistant;

use strict;
use warnings;
use QtCore4;
use QtGui4;

sub proc() {
    return shift->{proc};
}

sub new
{
    my ($class) = @_;
    my $self = {
        proc => undef
    };
    return bless $self, $class;
}

# [0]
sub DESTROY
{
    my ($self) = @_;
    if (defined $self->proc() && $self->proc()->state() == Qt::Process::Running()) {
        $self->proc()->terminate();
        $self->proc()->waitForFinished(3000);
    }
    $self->{proc} = undef;
}
# [0]

# [1]
sub showDocumentation
{
    my ($self, $page) = @_;
    if (!$self->startAssistant()) {
        return;
    }

    my $ba = Qt::ByteArray('SetSource ');
    $ba->append('qthelp://com.trolltech.examples.simpletextviewer/doc/');
    $ba->append($page);
    $ba->append("\0", 1);

    $self->proc->write($ba);
}
# [1]

# [2]
sub startAssistant
{
    my ($self) = @_;
    if (!defined $self->proc) {
        $self->{proc} = Qt::Process();
    }

    if ($self->proc->state() != Qt::Process::Running()) {
        my $app = Qt::LibraryInfo::location(Qt::LibraryInfo::BinariesPath()) . chr(Qt::Dir::separator()->toAscii());
#if !defined(Q_OS_MAC)
        $app .= 'assistant';
#else
        # TODO
        #app += Qt::Latin1String('Assistant.app/Contents/MacOS/Assistant');
#endif

        my $args = [
            '-collectionFile',
            Qt::LibraryInfo::location(Qt::LibraryInfo::ExamplesPath())
            . '/help/simpletextviewer/documentation/simpletextviewer.qhc',
            '-enableRemoteControl' ];

        $self->proc->start($app, $args);

        if (!$self->proc->waitForStarted()) {
            Qt::MessageBox::critical(undef, Qt::Object::tr('Simple Text Viewer'),
                sprintf Qt::Object::tr('Unable to launch Qt Assistant (%s)'), $app);
            return 0;
        }
    }
    return 1;
}
# [2]

1;
