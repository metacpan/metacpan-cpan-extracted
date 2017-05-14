package FindFileDialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    browse => [],
    help => [],
    openFile => ['QTreeWidgetItem *'],
    openFile => [],
    update => [];
use Assistant;
use TextEdit;

sub currentAssistant() {
    return this->{currentAssistant};
}

sub currentEditor() {
    return this->{currentEditor};
}

sub foundFilesTree() {
    return this->{foundFilesTree};
}

sub directoryComboBox() {
    return this->{directoryComboBox};
}

sub fileNameComboBox() {
    return this->{fileNameComboBox};
}

sub directoryLabel() {
    return this->{directoryLabel};
}

sub fileNameLabel() {
    return this->{fileNameLabel};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub browseButton() {
    return this->{browseButton};
}


# [0]
sub NEW
{
    my ($class, $editor, $assistant) = @_;
    $class->SUPER::NEW($editor);
    this->{currentAssistant} = $assistant;
    this->{currentEditor} = $editor;
# [0]

    createButtons();
    createComboBoxes();
    createFilesTree();
    createLabels();
    createLayout();

    directoryComboBox->addItem(Qt::Dir::toNativeSeparators(Qt::Dir::currentPath()));
    fileNameComboBox->addItem('*');
    findFiles();

    setWindowTitle(this->tr('Find File'));
# [1]
}
# [1]

sub browse
{
    my $currentDirectory = directoryComboBox->currentText();
    my $newDirectory = Qt::FileDialog::getExistingDirectory(this,
                               this->tr('Select Directory'), $currentDirectory);
    if (defined $newDirectory) {
        directoryComboBox->addItem(Qt::Dir::toNativeSeparators($newDirectory));
        directoryComboBox->setCurrentIndex(directoryComboBox->count() - 1);
        update();
    }
}

# [2]
sub help
{
    currentAssistant->showDocumentation('filedialog.html');    
}
# [2]

sub openFile
{
    my ($item) = @_;
    if (!defined $item) {
        $item = foundFilesTree->currentItem();
        if (!defined $item) {
            return;
        }
    }

    my $fileName = $item->text(0);
    my $path = directoryComboBox->currentText() . chr(Qt::Dir::separator()->toAscii);

    currentEditor->setContents($path . $fileName);
    this->close();
}

sub update
{
    findFiles();
    buttonBox->button(Qt::DialogButtonBox::Open())->setEnabled(
            foundFilesTree->topLevelItemCount() > 0);
}

sub findFiles
{
    my $filePattern = Qt::RegExp(fileNameComboBox->currentText() . '*');
    $filePattern->setPatternSyntax(Qt::RegExp::Wildcard());

    my $directory = Qt::Dir(directoryComboBox->currentText());

    my $allFiles = $directory->entryList(Qt::Dir::Files() | Qt::Dir::NoSymLinks());
    my $matchingFiles = [];

    foreach my $file ( @{$allFiles} ) {
        if ($filePattern->exactMatch($file)) {
            push @{$matchingFiles}, $file;
        }
    }
    showFiles($matchingFiles);
}

sub showFiles
{
    my ($files) = @_;
    foundFilesTree->clear();

    foreach my $file ( @{$files} ) {
        my $item = Qt::TreeWidgetItem(foundFilesTree);
        $item->setText(0, $file);
    }

    if (scalar @{$files} > 0) {
        foundFilesTree->setCurrentItem(foundFilesTree->topLevelItem(0));
    }
}

sub createButtons
{
    this->{browseButton} = Qt::ToolButton();
    browseButton->setText(this->tr('...'));
    this->connect(browseButton, SIGNAL 'clicked()', this, SLOT 'browse()');

    this->{buttonBox} = Qt::DialogButtonBox(Qt::DialogButtonBox::Open()
                                     | Qt::DialogButtonBox::Cancel()
                                     | Qt::DialogButtonBox::Help());
    this->connect(buttonBox, SIGNAL 'accepted()', this, SLOT 'openFile()');
    this->connect(buttonBox, SIGNAL 'rejected()', this, SLOT 'reject()');
    this->connect(buttonBox, SIGNAL 'helpRequested()', this, SLOT 'help()');
}

sub createComboBoxes
{
    this->{directoryComboBox} = Qt::ComboBox();
    this->{fileNameComboBox} = Qt::ComboBox();

    fileNameComboBox->setEditable(1);
    fileNameComboBox->setSizePolicy(Qt::SizePolicy::Expanding(),
                                    Qt::SizePolicy::Preferred());

    directoryComboBox->setMinimumContentsLength(30);
    directoryComboBox->setSizeAdjustPolicy(
            Qt::ComboBox::AdjustToMinimumContentsLength());
    directoryComboBox->setSizePolicy(Qt::SizePolicy::Expanding(),
                                     Qt::SizePolicy::Preferred());

    this->connect(fileNameComboBox, SIGNAL 'editTextChanged(QString)',
            this, SLOT 'update()');
    this->connect(directoryComboBox, SIGNAL 'currentIndexChanged(QString)',
            this, SLOT 'update()');
}

sub createFilesTree
{
    this->{foundFilesTree} = Qt::TreeWidget();
    foundFilesTree->setColumnCount(1);
    foundFilesTree->setHeaderLabels([this->tr('Matching Files')]);
    foundFilesTree->setRootIsDecorated(0);
    foundFilesTree->setSelectionMode(Qt::AbstractItemView::SingleSelection());

    this->connect(foundFilesTree, SIGNAL 'itemActivated(QTreeWidgetItem*,int)',
            this, SLOT 'openFile(QTreeWidgetItem*)');
}

sub createLabels
{
    this->{directoryLabel} = Qt::Label(this->tr('Search in:'));
    this->{fileNameLabel} = Qt::Label(this->tr('File name (including wildcards):'));
}

sub createLayout
{
    my $fileLayout = Qt::HBoxLayout();
    $fileLayout->addWidget(fileNameLabel);
    $fileLayout->addWidget(fileNameComboBox);

    my $directoryLayout = Qt::HBoxLayout();
    $directoryLayout->addWidget(directoryLabel);
    $directoryLayout->addWidget(directoryComboBox);
    $directoryLayout->addWidget(browseButton);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addLayout($fileLayout);
    $mainLayout->addLayout($directoryLayout);
    $mainLayout->addWidget(foundFilesTree);
    $mainLayout->addStretch();
    $mainLayout->addWidget(buttonBox);
    this->setLayout($mainLayout);
}

1;
