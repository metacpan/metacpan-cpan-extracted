package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    openDialog => [],
    printFile => [];
use DetailsDialog;

sub printAction() {
    return this->{printAction};
}

sub letters() {
    return this->{letters};
}

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $fileMenu = Qt::Menu(this->tr('&File'), this);
    my $newAction = $fileMenu->addAction(this->tr('&New...'));
    $newAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+N')));
    this->{printAction} = $fileMenu->addAction(this->tr('&Print...'), this, SLOT 'printFile()');
    this->printAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+P')));
    this->printAction->setEnabled(0);
    my $quitAction = $fileMenu->addAction(this->tr('E&xit'));
    $quitAction->setShortcut(this->tr('Ctrl+Q'));
    this->menuBar()->addMenu($fileMenu);

    this->{letters} = Qt::TabWidget();

    this->connect($newAction, SIGNAL 'triggered()', this, SLOT 'openDialog()');
    this->connect($quitAction, SIGNAL 'triggered()', this, SLOT 'close()');

    this->setCentralWidget(this->letters);
    this->setWindowTitle(this->tr('Order Form'));
}
# [0]

# [1]
sub createLetter
{
    my ($name, $address, $orderItems, $sendOffers) = @_;
    my $editor = Qt::TextEdit();
    my $tabIndex = this->letters->addTab($editor, $name);
    this->letters->setCurrentIndex($tabIndex);
# [1]

# [2]
    my $cursor = Qt::TextCursor($editor->textCursor());
    $cursor->movePosition(Qt::TextCursor::Start());
# [2] //! [3]
    my $topFrame = $cursor->currentFrame();
    my $topFrameFormat = $topFrame->frameFormat();
    $topFrameFormat->setPadding(16);
    $topFrame->setFrameFormat($topFrameFormat);

    my $textFormat = Qt::TextCharFormat();
    my $boldFormat = Qt::TextCharFormat();
    $boldFormat->setFontWeight(Qt::Font::Bold());

    my $referenceFrameFormat = Qt::TextFrameFormat();
    $referenceFrameFormat->setBorder(1);
    $referenceFrameFormat->setPadding(8);
    $referenceFrameFormat->setPosition(Qt::TextFrameFormat::FloatRight());
    $referenceFrameFormat->setWidth(Qt::TextLength(Qt::TextLength::PercentageLength(), 40));
    $cursor->insertFrame($referenceFrameFormat);

    $cursor->insertText('A company', $boldFormat);
    $cursor->insertBlock();
    $cursor->insertText('321 City Street');
    $cursor->insertBlock();
    $cursor->insertText('Industry Park');
    $cursor->insertBlock();
    $cursor->insertText('Another country');
# [3]

# [4]
    $cursor->setPosition($topFrame->lastPosition());

    $cursor->insertText($name, $textFormat);
    my $line;
    foreach my $line ( split "\n", $address ) {
        $cursor->insertBlock();
        $cursor->insertText($line);
    }
# [4] //! [5]
    $cursor->insertBlock();
    $cursor->insertBlock();

    my $date = Qt::Date::currentDate();
    $cursor->insertText(sprintf this->tr('Date: %s'), $date->toString('d MMMM yyyy'),
                      $textFormat);
    $cursor->insertBlock();

    my $bodyFrameFormat = Qt::TextFrameFormat();
    $bodyFrameFormat->setWidth(Qt::TextLength(Qt::TextLength::PercentageLength(), 100));
    $cursor->insertFrame($bodyFrameFormat);
# [5]

# [6]
    $cursor->insertText(this->tr('I would like to place an order for the following ' .
                         'items:'), $textFormat);
    $cursor->insertBlock();
# [6] //! [7]
    $cursor->insertBlock();
# [7]

# [8]
    my $orderTableFormat = Qt::TextTableFormat();
    $orderTableFormat->setAlignment(Qt::AlignHCenter());
    my $orderTable = $cursor->insertTable(1, 2, $orderTableFormat);

    my $orderFrameFormat = $cursor->currentFrame()->frameFormat();
    $orderFrameFormat->setBorder(1);
    $cursor->currentFrame()->setFrameFormat($orderFrameFormat);
# [8]

# [9]
    $cursor = $orderTable->cellAt(0, 0)->firstCursorPosition();
    $cursor->insertText(this->tr('Product'), $boldFormat);
    $cursor = $orderTable->cellAt(0, 1)->firstCursorPosition();
    $cursor->insertText(this->tr('Quantity'), $boldFormat);
# [9]

# [10]
    for (my $i = 0; $i < @{$orderItems}; ++$i) {
        my $item = $orderItems->[$i];
        my $row = $orderTable->rows();

        $orderTable->insertRows($row, 1);
        $cursor = $orderTable->cellAt($row, 0)->firstCursorPosition();
        $cursor->insertText($item->[0], $textFormat);
        $cursor = $orderTable->cellAt($row, 1)->firstCursorPosition();
        $cursor->insertText($item->[1], $textFormat);
    }
# [10]

# [11]
    $cursor->setPosition($topFrame->lastPosition());

    $cursor->insertBlock();
# [11] //! [12]
    $cursor->insertText(this->tr('Please update my records to take account of the ' .
                         'following privacy information:'));
    $cursor->insertBlock();
# [12]

# [13]
    my $offersTable = $cursor->insertTable(2, 2);

    $cursor = $offersTable->cellAt(0, 1)->firstCursorPosition();
    $cursor->insertText(this->tr('I want to receive more information about your ' .
                         'company\'s products and special offers.'), $textFormat);
    $cursor = $offersTable->cellAt(1, 1)->firstCursorPosition();
    $cursor->insertText(this->tr('I do not want to receive any promotional information ' .
                         'from your company.'), $textFormat);

    if ($sendOffers) {
        $cursor = $offersTable->cellAt(0, 0)->firstCursorPosition();
    }
    else {
        $cursor = $offersTable->cellAt(1, 0)->firstCursorPosition();
    }

    $cursor->insertText('X', $boldFormat);
# [13]

# [14]
    $cursor->setPosition($topFrame->lastPosition());
    $cursor->insertBlock();
    $cursor->insertText(this->tr('Sincerely,'), $textFormat);
    $cursor->insertBlock();
    $cursor->insertBlock();
    $cursor->insertBlock();
    $cursor->insertText($name);

    this->printAction->setEnabled(1);
}
# [14]

# [15]
sub createSample
{
    my $dialog = DetailsDialog('Dialog with default values', this);
    this->createLetter('Mr. Smith', "12 High Street\nSmall Town\nThis country",
                 $dialog->orderItems(), 1);
}
# [15]

# [16]
sub openDialog
{
    my $dialog = DetailsDialog(this->tr('Enter Customer Details'), this);

    if ($dialog->exec() == Qt::Dialog::Accepted()) {
        this->createLetter($dialog->senderName(), $dialog->senderAddress(),
                     $dialog->orderItems(), $dialog->sendOffers());
    }
}
# [16]

# [17]
sub printFile
{
    my $editor = this->letters->currentWidget();
# [18]
    my $printer = Qt::Printer();

    my $dialog = Qt::PrintDialog($printer, this);
    $dialog->setWindowTitle(this->tr('Print Document'));
    if ($editor->textCursor()->hasSelection()) {
        $dialog->addEnabledOption(Qt::AbstractPrintDialog::PrintSelection());
    }
    if ($dialog->exec() != Qt::Dialog::Accepted()) {
        return;
    }
# [18]

    $editor->print($printer);
}
# [17]

1;
