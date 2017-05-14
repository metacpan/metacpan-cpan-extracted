package DragWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use DragLabel;
use List::Util qw(max);

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $dictionaryFile = Qt::File('words.txt');
    $dictionaryFile->open(Qt::File::ReadOnly());
    my $inputStream = Qt::TextStream($dictionaryFile);
# [0]

# [1]
    my $x = 5;
    my $y = 5;

    while (!$inputStream->atEnd()) {
        my $word;
        no warnings qw(void);
        $inputStream >> Qt::String($word);
        use warnings;
        if ($word) {
            my $wordLabel = DragLabel($word, this);
            $wordLabel->move($x, $y);
            $wordLabel->show();
            $wordLabel->setAttribute(Qt::WA_DeleteOnClose());
            $x += $wordLabel->width() + 2;
            if ($x >= 245) {
                $x = 5;
                $y += $wordLabel->height() + 2;
            }
        }
    }
# [1]

# [2]
    my $newPalette = this->palette();
    $newPalette->setColor(Qt::Palette::Window(), Qt::Color(Qt::white()));
    this->setPalette($newPalette);

    this->setMinimumSize(400, max(200, $y));
    this->setWindowTitle(this->tr('Fridge Magnets'));
# [2] //! [3]
    this->setAcceptDrops(1);
}
# [3]

# [4]
sub dragEnterEvent
{
    my ($event) = @_;
# [4] //! [5]
    if ($event->mimeData()->hasFormat('application/x-fridgemagnet')) {
        my $children = this->children();
        if ($children && grep{ $_ eq $event->source } @{$children}) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
# [5] //! [6]
        }
# [6] //! [7]
    } elsif ($event->mimeData()->hasText()) {
        $event->acceptProposedAction();
    } else {
        $event->ignore();
    }
}
# [7]

# [8]
sub dragMoveEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('application/x-fridgemagnet')) {
        my $children = this->children();
        if ($children && grep{ $_ eq $event->source } @{$children}) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
    } elsif ($event->mimeData()->hasText()) {
        $event->acceptProposedAction();
    } else {
        $event->ignore();
    }
}
# [8]

# [9]
sub dropEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('application/x-fridgemagnet')) {
        my $mime = $event->mimeData();
# [9] //! [10]
        my $itemData = $mime->data('application/x-fridgemagnet');
        my $dataStream = Qt::DataStream($itemData, Qt::IODevice::ReadOnly());

        my $text = '';
        my $offset = Qt::Point();
        no warnings qw(void);
        $dataStream >> Qt::String($text) >> $offset;
        use warnings;
# [10]
# [11]
        my $newLabel = DragLabel($text, this);
        $newLabel->move($event->pos() - $offset);
        $newLabel->show();
        $newLabel->setAttribute(Qt::WA_DeleteOnClose());

        if ($event->source() == this) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
# [11] //! [12]
    } elsif ($event->mimeData()->hasText()) {
        my @pieces = split /\s+/, $event->mimeData()->text();
        my $position = $event->pos();

        foreach my $piece ( @pieces ) {
            my $newLabel = DragLabel($piece, this);
            $newLabel->move($position);
            $newLabel->show();
            $newLabel->setAttribute(Qt::WA_DeleteOnClose());

            $position += Qt::Point($newLabel->width(), 0);
        }

        $event->acceptProposedAction();
    } else {
        $event->ignore();
    }
}
# [12]

# [13]
sub mousePressEvent
{
    my ($event) = @_;
# [13]
# [14]
    my $child = this->childAt($event->pos());
    if (!$child) {
        return;
    }

    my $hotSpot = $event->pos() - $child->pos();

    my $itemData = Qt::ByteArray();
    my $dataStream = Qt::DataStream($itemData, Qt::IODevice::WriteOnly());
    no warnings qw(void);
    $dataStream << Qt::String($child->labelText()) << Qt::Point($hotSpot);
    use warnings;
# [14]

# [15]
    my $mimeData = Qt::MimeData();
    $mimeData->setData('application/x-fridgemagnet', $itemData);
    $mimeData->setText($child->labelText());
# [15]

# [16]
    my $drag = Qt::Drag(this);
    $drag->setMimeData($mimeData);
    $drag->setPixmap($child->pixmap());
    $drag->setHotSpot($hotSpot);

    $child->hide();
# [16]

# [17]
    if ($drag->exec(Qt::MoveAction() | Qt::CopyAction(), Qt::CopyAction()) == Qt::MoveAction()) {
        $child->close();
    }
    else {
        $child->show();
    }
}
# [17]

1;
