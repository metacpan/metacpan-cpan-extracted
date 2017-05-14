package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    about => [],
    changeCase => ['int'],
    changeMode => ['int'],
    highlight => ['const QModelIndex&'],
    updateContentsLabel => ['const QString&'];
# [0]
use TreeModelCompleter;

# [1]
sub treeView() {
    return this->{treeView};
}

sub caseCombo() {
    return this->{caseCombo};
}

sub modeCombo() {
    return this->{modeCombo};
}

sub contentsLabel() {
    return this->{contentsLabel};
}

sub completer() {
    return this->{completer};
}

sub lineEdit() {
    return this->{lineEdit};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    createMenu();

    this->{completer} = TreeModelCompleter(this);
    completer->setModel(modelFromFile(':/resources/treemodel.txt'));
    completer->setSeparator('.');
    Qt::Object::connect(completer, SIGNAL 'highlighted(QModelIndex)',
                     this, SLOT 'highlight(QModelIndex)');

    my $centralWidget = Qt::Widget();

    my $modelLabel = Qt::Label();
    $modelLabel->setText(this->tr('Tree Model<br>(Double click items to edit)'));

    my $modeLabel = Qt::Label();
    $modeLabel->setText(this->tr('Completion Mode'));
    this->{modeCombo} = Qt::ComboBox();
    modeCombo->addItem(this->tr('Inline'));
    modeCombo->addItem(this->tr('Filtered Popup'));
    modeCombo->addItem(this->tr('Unfiltered Popup'));
    modeCombo->setCurrentIndex(1);

    my $caseLabel = Qt::Label();
    $caseLabel->setText(this->tr('Case Sensitivity'));
    this->{caseCombo} = Qt::ComboBox();
    caseCombo->addItem(this->tr('Case Insensitive'));
    caseCombo->addItem(this->tr('Case Sensitive'));
    caseCombo->setCurrentIndex(0);
# [0]

# [1]
    my $separatorLabel = Qt::Label();
    $separatorLabel->setText(this->tr('Tree Separator'));

    my $separatorLineEdit = Qt::LineEdit();
    $separatorLineEdit->setText(completer->separator());
    this->connect($separatorLineEdit, SIGNAL 'textChanged(QString)',
            completer, SLOT 'setSeparator(QString)');

    my $wrapCheckBox = Qt::CheckBox();
    $wrapCheckBox->setText(this->tr('Wrap around completions'));
    $wrapCheckBox->setChecked(completer->wrapAround());
    this->connect($wrapCheckBox, SIGNAL 'clicked(bool)', completer, SLOT 'setWrapAround(bool)');

    this->{contentsLabel} = Qt::Label();
    contentsLabel->setSizePolicy(Qt::SizePolicy::Fixed(), Qt::SizePolicy::Fixed());
    this->connect($separatorLineEdit, SIGNAL 'textChanged(QString)',
            this, SLOT 'updateContentsLabel(QString)');

    this->{treeView} = Qt::TreeView();
    treeView->setModel(completer->model());
    treeView->header()->hide();
    treeView->expandAll();
# [1]

# [2]
    this->connect(modeCombo, SIGNAL 'activated(int)', this, SLOT 'changeMode(int)');
    this->connect(caseCombo, SIGNAL 'activated(int)', this, SLOT 'changeCase(int)');

    this->{lineEdit} = Qt::LineEdit();
    lineEdit->setCompleter(completer);
# [2]

# [3]
    my $layout = Qt::GridLayout();
    $layout->addWidget($modelLabel, 0, 0); $layout->addWidget(treeView, 0, 1);
    $layout->addWidget($modeLabel, 1, 0);  $layout->addWidget(modeCombo, 1, 1);
    $layout->addWidget($caseLabel, 2, 0);  $layout->addWidget(caseCombo, 2, 1);
    $layout->addWidget($separatorLabel, 3, 0); $layout->addWidget($separatorLineEdit, 3, 1);
    $layout->addWidget($wrapCheckBox, 4, 0);
    $layout->addWidget(contentsLabel, 5, 0, 1, 2);
    $layout->addWidget(lineEdit, 6, 0, 1, 2);
    $centralWidget->setLayout($layout);
    setCentralWidget($centralWidget);

    changeCase(caseCombo->currentIndex());
    changeMode(modeCombo->currentIndex());

    setWindowTitle(this->tr('Tree Model Completer'));
    lineEdit->setFocus();
}
# [3]

# [4]
sub createMenu
{
    my $exitAction = Qt::Action(this->tr('Exit'), this);
    my $aboutAct = Qt::Action(this->tr('About'), this);
    my $aboutQtAct = Qt::Action(this->tr('About Qt'), this);

    this->connect($exitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
    this->connect($aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');
    this->connect($aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');

    my $fileMenu = menuBar()->addMenu(this->tr('File'));
    $fileMenu->addAction($exitAction);

    my $helpMenu = menuBar()->addMenu(this->tr('About'));
    $helpMenu->addAction($aboutAct);
    $helpMenu->addAction($aboutQtAct);
}
# [4]

# [5]
sub changeMode
{
    my ($index) = @_;
    my $mode;
    if ($index == 0) {
        $mode = Qt::Completer::InlineCompletion();
    }
    elsif ($index == 1) {
        $mode = Qt::Completer::PopupCompletion();
    }
    else {
        $mode = Qt::Completer::UnfilteredPopupCompletion();
    }

    completer->setCompletionMode($mode);
}
# [5]

sub modelFromFile
{
    my ($fileName) = @_;
    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::ReadOnly())) {
        return Qt::StringListModel(completer);
    }

#ifndef Qt::T_NO_CURSOR
    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
#endif
    my @words;

    my $model = Qt::StandardItemModel(completer);
    my @parents;
    $parents[0] = $model->invisibleRootItem();

    while (!$file->atEnd()) {
        my $line = $file->readLine()->constData();
        my $trimmedLine = $line;
        $trimmedLine =~ s/^[\s]*//;
        $trimmedLine =~ s/[\s]*$//;
        if (!$line || !$trimmedLine) {
            next;
        }

        my $re = Qt::RegExp('^\\s+');
        my $nonws = $re->indexIn($line);
        my $level = 0;
        if ($nonws == -1) {
            $level = 0;
        } else {
            if ( substr( $line, 0, 1 ) eq "\t" ) {
                $level = length $re->cap(0);
            } else {
                $level = length( $re->cap(0) )/4;
            }
        }

        #if ($level+1 >= parents.size())
            #parents.resize(parents.size()*2);

        my $item = Qt::StandardItem();
        $item->setText($trimmedLine);
        $parents[$level]->appendRow($item);
        $parents[$level+1] = $item;
    }

#ifndef Qt::T_NO_CURSOR
    Qt::Application::restoreOverrideCursor();
#endif

    return $model;
}

sub highlight
{
    my ($index) = @_;
    my $completionModel = completer->completionModel();
    my $proxy = $completionModel;
    if (!$proxy->isa('Qt::AbstractProxyModel')) {
        return;
    }
    my $sourceIndex = $proxy->mapToSource($index);
    treeView->selectionModel()->select($sourceIndex, Qt::ItemSelectionModel::ClearAndSelect() | Qt::ItemSelectionModel::Rows());
    treeView->scrollTo($index);
}

# [6]
sub about
{
    Qt::MessageBox::about(this, this->tr('About'), this->tr('This example demonstrates how ' .
        'to use a Qt::Completer with a custom tree model.'));
}
# [6]

# [7]
sub changeCase
{
    my ($cs) = @_;
    completer->setCaseSensitivity($cs ? Qt::CaseSensitive() : Qt::CaseInsensitive());
}
# [7]

sub updateContentsLabel
{
    my ($sep) = @_;
    contentsLabel->setText(Qt::String(this->tr('Type path from model above with items at each level separated by a \'%1\''))->arg($sep));
}

1;
