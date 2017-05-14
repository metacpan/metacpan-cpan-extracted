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
    changeModel => [];
# [0]
use DirModel;

# [1]
sub caseCombo() {
    return this->{caseCombo};
}

sub modeCombo() {
    return this->{modeCombo};
}

sub modelCombo() {
    return this->{modelCombo};
}

sub wrapCheckBox() {
    return this->{wrapCheckBox};
}

sub completer() {
    return this->{completer};
}

sub contentsLabel() {
    return this->{contentsLabel};
}

sub lineEdit() {
    return this->{lineEdit};
}
# [1]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->{completer} = 0;
    this->{lineEdit} = 0;

    this->createMenu();

    my $centralWidget = Qt::Widget();

    my $modelLabel = Qt::Label();
    $modelLabel->setText(this->tr('Model'));

    this->{modelCombo} = Qt::ComboBox();
    this->modelCombo->addItem(this->tr('Qt::DirModel'));
    this->modelCombo->addItem(this->tr('Qt::DirModel that shows full path'));
    this->modelCombo->addItem(this->tr('Country list'));
    this->modelCombo->addItem(this->tr('Word list'));
    this->modelCombo->setCurrentIndex(0);

    my $modeLabel = Qt::Label();
    $modeLabel->setText(this->tr('Completion Mode'));
    this->{modeCombo} = Qt::ComboBox();
    this->modeCombo->addItem(this->tr('Inline'));
    this->modeCombo->addItem(this->tr('Filtered Popup'));
    this->modeCombo->addItem(this->tr('Unfiltered Popup'));
    this->modeCombo->setCurrentIndex(1);

    my $caseLabel = Qt::Label();
    $caseLabel->setText(this->tr('Case Sensitivity'));
    this->{caseCombo} = Qt::ComboBox();
    this->caseCombo->addItem(this->tr('Case Insensitive'));
    this->caseCombo->addItem(this->tr('Case Sensitive'));
    this->caseCombo->setCurrentIndex(0);
# [0]

# [1]
    this->{wrapCheckBox} = Qt::CheckBox();
    this->wrapCheckBox->setText(this->tr('Wrap around completions'));
    this->wrapCheckBox->setChecked(1);
# [1]

# [2]
    this->{contentsLabel} = Qt::Label();
    this->contentsLabel->setSizePolicy(Qt::SizePolicy::Fixed(), Qt::SizePolicy::Fixed());

    this->connect(this->modelCombo, SIGNAL 'activated(int)', this, SLOT 'changeModel()');
    this->connect(this->modeCombo, SIGNAL 'activated(int)', this, SLOT 'changeMode(int)');
    this->connect(this->caseCombo, SIGNAL 'activated(int)', this, SLOT 'changeCase(int)');
# [2]

# [3]
    this->{lineEdit} = Qt::LineEdit();
    
    my $layout = Qt::GridLayout();
    $layout->addWidget($modelLabel, 0, 0); $layout->addWidget(this->modelCombo, 0, 1);
    $layout->addWidget($modeLabel, 1, 0);  $layout->addWidget(this->modeCombo, 1, 1);
    $layout->addWidget($caseLabel, 2, 0);  $layout->addWidget(this->caseCombo, 2, 1);
    $layout->addWidget(this->wrapCheckBox, 3, 0);
    $layout->addWidget(this->contentsLabel, 4, 0, 1, 2);
    $layout->addWidget(this->lineEdit, 5, 0, 1, 2);
    $centralWidget->setLayout($layout);
    this->setCentralWidget($centralWidget);

    this->changeModel();

    this->setWindowTitle(this->tr('Completer'));
    this->lineEdit->setFocus();
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

    my $fileMenu = this->menuBar()->addMenu(this->tr('File'));
    $fileMenu->addAction($exitAction);

    my $helpMenu = this->menuBar()->addMenu(this->tr('About'));
    $helpMenu->addAction($aboutAct);
    $helpMenu->addAction($aboutQtAct);
}
# [4]

# [5]
sub modelFromFile
{
    my ($fileName) = @_;
    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::ReadOnly())) {
        return Qt::StringListModel(this->completer);
    }
# [5]

# [6]
    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    my @words;

    while (!$file->atEnd()) {
        my $line = $file->readLine();
        if ($line) {
            chomp( $line = $line->data() );
            push @words, $line;
        }
    }

    Qt::Application::restoreOverrideCursor();
# [6]

# [7]
    if (!($fileName =~ m/countries\.txt/)) {
        return Qt::StringListModel(\@words, this->completer);
    }
# [7]

    # The last two chars of the countries.txt file indicate the country
    # symbol. We put that in column 2 of a standard item model
# [8]
    my $m = Qt::StandardItemModel( scalar @words, 2, this->completer);
# [8] //! [9]
    for (my $i = 0; $i < scalar @words; ++$i) {
        my $countryIdx = $m->index($i, 0);
        my $symbolIdx = $m->index($i, 1);
        my $country = substr $words[$i], 0, length($words[$i])-2;
        my $symbol = substr $words[$i], -2;
        $country =~ s/\s+$//;
        $m->setData($countryIdx, Qt::Variant(Qt::String($country)));
        $m->setData($symbolIdx, Qt::Variant(Qt::String($symbol)));
    }

    return $m;
}
# [9]

# [10]
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

    this->completer->setCompletionMode($mode);
}
# [10]

sub changeCase
{
    my ($cs) = @_;
    this->completer->setCaseSensitivity($cs ? Qt::CaseSensitive() : Qt::CaseInsensitive());
}

# [11]
sub changeModel
{
    this->{completer} = Qt::Completer(this);

    if (this->modelCombo->currentIndex() == 0) {
        # Unsorted Qt::DirModel
        my $dirModel = Qt::DirModel(this->completer);
        this->completer->setModel($dirModel);
        this->contentsLabel->setText(this->tr('Enter file path'));
    }
# [11] #! [12]
    elsif (this->modelCombo->currentIndex() == 1) {
        # DirModel that shows full paths
        my $dirModel = DirModel(this->completer);
        this->completer->setModel($dirModel);
        this->contentsLabel->setText(this->tr('Enter file path'));
    }
# [12] #! [13]
    elsif (this->modelCombo->currentIndex() == 2) {
        # Country List
        this->completer->setModel(this->modelFromFile('resources/countries.txt'));
        my $treeView = Qt::TreeView();
        this->completer->setPopup($treeView);
        $treeView->setRootIsDecorated(0);
        $treeView->header()->hide();
        $treeView->header()->setStretchLastSection(0);
        $treeView->header()->setResizeMode(0, Qt::HeaderView::Stretch());
        $treeView->header()->setResizeMode(1, Qt::HeaderView::ResizeToContents());
        this->contentsLabel->setText(this->tr('Enter name of your country'));
    }
# [13] #! [14]
    elsif (this->modelCombo->currentIndex() == 3) {
        # Word list
        this->completer->setModel(this->modelFromFile('resources/wordlist.txt'));
        this->completer->setModelSorting(Qt::Completer::CaseInsensitivelySortedModel());
        this->contentsLabel->setText(this->tr('Enter a word'));
    }

    this->changeMode(this->modeCombo->currentIndex());
    this->changeCase(this->caseCombo->currentIndex());
    this->completer->setWrapAround(this->wrapCheckBox->isChecked());
    this->lineEdit->setCompleter(this->completer);
    this->connect(this->wrapCheckBox, SIGNAL 'clicked(bool)', this->completer, SLOT 'setWrapAround(bool)');
}
# [14]

# [15]
sub about
{
    Qt::MessageBox::about(this, this->tr('About'), this->tr('This example demonstrates the ' .
        'different features of the Qt::Completer class.'));
}
# [15]

1;
