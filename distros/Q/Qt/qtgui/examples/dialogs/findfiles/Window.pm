package Window;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );

# [0]
use QtCore4::slots
    browse => [],
    find => [],
    openFileOfItem => ['int', 'int'];

# [0]

# [0]
sub NEW {
    shift->SUPER::NEW( @_ );
    my $browseButton = createButton(this->tr('&Browse...'), SLOT 'browse()');
    my $findButton = createButton(this->tr('&Find'), SLOT 'find()');

    my $fileComboBox = createComboBox(this->tr('*'));
    my $textComboBox = createComboBox();
    my $directoryComboBox = createComboBox(Qt::Dir::currentPath());

    my $fileLabel = Qt::Label(this->tr('Named:'));
    my $textLabel = Qt::Label(this->tr('Containing text:'));
    my $directoryLabel = Qt::Label(this->tr('In directory:'));
    my $filesFoundLabel = Qt::Label();

    createFilesTable();
# [0]

# [1]
    my $buttonsLayout = Qt::HBoxLayout();
    $buttonsLayout->addStretch();
    $buttonsLayout->addWidget($findButton);

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget($fileLabel, 0, 0);
    $mainLayout->addWidget($fileComboBox, 0, 1, 1, 2);
    $mainLayout->addWidget($textLabel, 1, 0);
    $mainLayout->addWidget($textComboBox, 1, 1, 1, 2);
    $mainLayout->addWidget($directoryLabel, 2, 0);
    $mainLayout->addWidget($directoryComboBox, 2, 1);
    $mainLayout->addWidget($browseButton, 2, 2);
    $mainLayout->addWidget(this->{filesTable}, 3, 0, 1, 3);
    $mainLayout->addWidget($filesFoundLabel, 4, 0);
    $mainLayout->addLayout($buttonsLayout, 5, 0, 1, 3);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Find Files'));
    this->resize(700, 300);

    this->{fileComboBox} = $fileComboBox;
    this->{textComboBox} = $textComboBox;
    this->{directoryComboBox} = $directoryComboBox;
    this->{fileLabel} = $fileLabel;
    this->{textLabel} = $textLabel;
    this->{directoryLabel} = $directoryLabel;
    this->{filesFoundLabel} = $filesFoundLabel;
    this->{browseButton} = $browseButton;
    this->{findButton} = $findButton;
}
# [1]

# [2]
sub browse {
    my $directory = Qt::FileDialog::getExistingDirectory(this,
                               this->tr('Find Files'), Qt::Dir::currentPath());

    my $directoryComboBox = this->{directoryComboBox};
    if ($directory) {
        if ($directoryComboBox->findText($directory) == -1) {
            $directoryComboBox->addItem($directory);
        }
        $directoryComboBox->setCurrentIndex($directoryComboBox->findText($directory));
    }
}
# [2]

sub updateComboBox {
    my ($comboBox) = @_;
    if ($comboBox->findText($comboBox->currentText()) == -1) {
        $comboBox->addItem($comboBox->currentText());
    }
}

# [3]
sub find {
    my $filesTable = this->{filesTable};
    my $fileComboBox = this->{fileComboBox};
    my $textComboBox = this->{textComboBox};
    my $directoryComboBox = this->{directoryComboBox};
    my $currentDir = this->{currentDir};
    $filesTable->setRowCount(0);

    my $fileName = $fileComboBox->currentText();
    my $text = $textComboBox->currentText();
    my $path = $directoryComboBox->currentText();
# [3]

    updateComboBox($fileComboBox);
    updateComboBox($textComboBox);
    updateComboBox($directoryComboBox);

# [4]
    $currentDir = Qt::Dir($path);
    this->{currentDir} = $currentDir;
    my $files;
    if (!$fileName) {
        $fileName = '*';
    }
    $files = $currentDir->entryList( [ $fileName ],
                                 Qt::Dir::Files() | Qt::Dir::NoSymLinks());

    if ($text) {
        $files = findFiles($files, $text);
    }
    showFiles($files);
}
# [4]

# [5]

sub findFiles {
    my ($files, $text) = @_;
    my $progressDialog = Qt::ProgressDialog(this);
    $progressDialog->setCancelButtonText(this->tr('&Cancel'));
    $progressDialog->setRange(0, $#{$files});
    $progressDialog->setWindowTitle(this->tr('Find Files'));

# [5] //! [6]
    my @foundFiles;

    for (my $i = 0; $i < @{$files}; ++$i) {
        $progressDialog->setValue($i);
        $progressDialog->setLabelText(this->tr("Searching file number $i of " . @{$files}));
        qApp->processEvents();
# [6]

        if ($progressDialog->wasCanceled()) {
            last;
        }

# [7]
        my $file = Qt::File(this->{currentDir}->absoluteFilePath($files->[$i]));

        if ($file->open(Qt::IODevice::ReadOnly())) {
            my $line;
            my $in = Qt::TextStream($file);
            while (!$in->atEnd()) {
                if ($progressDialog->wasCanceled()) {
                    last;
                }
                $line = $in->readLine();
                if ($line =~ m/$text/) {
                    push @foundFiles, $files->[$i];
                    last;
                }
            }
        }
    }
    return \@foundFiles;
}
# [7]

# [8]
sub showFiles {
    my ($files) = @_;
    my $filesTable = this->{filesTable};
    for (my $i = 0; $i < @{$files}; ++$i) {
        my $file = Qt::File(this->{currentDir}->absoluteFilePath($files->[$i]));
        my $size = Qt::FileInfo($file)->size();

        my $fileNameItem = Qt::TableWidgetItem($files->[$i]);
        $fileNameItem->setFlags($fileNameItem->flags() ^ Qt::ItemIsEditable());
        my $sizeItem = Qt::TableWidgetItem(this->tr(sprintf '%d KB',
                                             (($size + 1023) / 1024)));
        $sizeItem->setTextAlignment(Qt::AlignRight() | Qt::AlignVCenter());
        $sizeItem->setFlags($sizeItem->flags() ^ Qt::ItemIsEditable());

        my $row = $filesTable->rowCount();
        $filesTable->insertRow($row);
        $filesTable->setItem($row, 0, $fileNameItem);
        $filesTable->setItem($row, 1, $sizeItem);
    }
    my $filesFoundLabel = this->{filesFoundLabel};
    $filesFoundLabel->setText(this->tr(scalar @{$files} . ' file(s) found' .
                             ' (Double click on a file to open it)'));
}
# [8]

# [9]
sub createButton {
    my ($text, $member) = @_;
    my $button = Qt::PushButton($text);
    this->connect($button, SIGNAL 'clicked()', this, $member);
    return $button;
}
# [9]

# [10]
sub createComboBox {
    my ($text) = @_;
    my $comboBox = Qt::ComboBox();
    $comboBox->setEditable(1);
    $comboBox->addItem($text);
    $comboBox->setSizePolicy(Qt::SizePolicy::Expanding(), Qt::SizePolicy::Preferred());
    return $comboBox;
}
# [10]

# [11]
sub createFilesTable {
    my $filesTable = Qt::TableWidget(0, 2);
    this->{filesTable} = $filesTable;
    $filesTable->setSelectionBehavior(Qt::AbstractItemView::SelectRows());

    my @labels;
    push @labels, this->tr('File Name'), this->tr('Size');
    $filesTable->setHorizontalHeaderLabels(\@labels);
    $filesTable->horizontalHeader()->setResizeMode(0, Qt::HeaderView::Stretch());
    $filesTable->verticalHeader()->hide();
    $filesTable->setShowGrid(0);

    this->connect($filesTable, SIGNAL 'cellActivated(int, int)',
            this, SLOT 'openFileOfItem(int, int)');
}
# [11]

# [12]

sub openFileOfItem {
    my ( $row ) = @_;
    my $filesTable = this->{filesTable};
    my $item = $filesTable->item($row, 0);

    Qt::DesktopServices::openUrl(Qt::Url(this->{currentDir}->absoluteFilePath($item->text())));
}

# [12]

1;
