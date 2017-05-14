package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    updateLog => ['int'];
use FileListModel;
    #Qt::TextBrowser *logViewer;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW( $parent );
    my $model = FileListModel(this);
    $model->setDirPath(Qt::LibraryInfo::location(Qt::LibraryInfo::PrefixPath()));

    my $label = Qt::Label(this->tr('&Directory:'));
    my $lineEdit = Qt::LineEdit();
    $label->setBuddy($lineEdit);

    my $view = Qt::ListView();
    $view->setModel($model);

    my $logViewer = Qt::TextBrowser();
    this->{logViewer} = $logViewer;
    $logViewer->setSizePolicy(Qt::SizePolicy(Qt::SizePolicy::Preferred(), Qt::SizePolicy::Preferred()));

    this->connect($lineEdit, SIGNAL 'textChanged(QString)',
            $model, SLOT 'setDirPath(QString)');
    this->connect($lineEdit, SIGNAL 'textChanged(QString)',
            $logViewer, SLOT 'clear()');
    this->connect($model, SIGNAL 'numberPopulated(int)',
            this, SLOT 'updateLog(int)');
    
    my $layout = Qt::GridLayout();
    $layout->addWidget($label, 0, 0);
    $layout->addWidget($lineEdit, 0, 1);
    $layout->addWidget($view, 1, 0, 1, 2);
    $layout->addWidget($logViewer, 2, 0, 1, 2);

    this->setLayout($layout);
    this->setWindowTitle(this->tr('Fetch More Example'));
}

sub updateLog
{
    my ($number) = @_;
    this->{logViewer}->append(sprintf this->tr('%d items added.'), $number);
}

1;
