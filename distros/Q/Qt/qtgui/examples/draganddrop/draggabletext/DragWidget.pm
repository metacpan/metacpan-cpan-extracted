package DragWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use DragLabel;
use List::Util qw(max);

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $dictionaryFile = Qt::File('words.txt');
    $dictionaryFile->open(Qt::IODevice::ReadOnly());
    my $inputStream = Qt::TextStream($dictionaryFile);

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
            if ($x >= 195) {
                $x = 5;
                $y += $wordLabel->height() + 2;
            }
        }
    }

    my $newPalette = this->palette();
    $newPalette->setColor(Qt::Palette::Window(), Qt::Color(Qt::white()));
    this->setPalette($newPalette);

    this->setAcceptDrops(1);
    this->setMinimumSize(400, max(200, $y));
    this->setWindowTitle(this->tr('Draggable Text'));
}

sub dragEnterEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasText()) {
        my $children = this->children();
        if ($children && grep{ $_ eq $event->source } @{$children}) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
    } else {
        $event->ignore();
    }
}

sub dropEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasText()) {
        my $mime = $event->mimeData();
        my @pieces = split /\s+/, $mime->text();
        my $position = $event->pos();
        my $hotSpot = Qt::Point();

        my @hotSpotPos = split / /, $mime->data('application/x-hotspot')->data();
        if (scalar @hotSpotPos == 2) {
            $hotSpot->setX($hotSpotPos[0]);
            $hotSpot->setY($hotSpotPos[1]);
        }

        foreach my $piece ( @pieces ) {
            my $newLabel = DragLabel($piece, this);
            $newLabel->move($position - $hotSpot);
            $newLabel->show();
            $newLabel->setAttribute(Qt::WA_DeleteOnClose());

            $position += Qt::Point($newLabel->width(), 0);
        }

        if ($event->source() == this) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
    } else {
        $event->ignore();
    }
    foreach my $child ( @{this->children()} ) {
        if ($child->inherits('Qt::Widget')) {
            if (!$child->isVisible()) {
                $child->deleteLater();
            }
        }
    }
}

sub mousePressEvent
{
    my ($event) = @_;
    my $child = this->childAt($event->pos());
    if (!$child) {
        return;
    }

    my $hotSpot = $event->pos() - $child->pos();

    my $mimeData = Qt::MimeData();
    $mimeData->setText($child->text());
    $mimeData->setData('application/x-hotspot',
                       Qt::ByteArray( $hotSpot->x()
                           . ' ' . $hotSpot->y()) );

    my $pixmap = Qt::Pixmap($child->size());
    $child->render($pixmap);

    my $drag = Qt::Drag(this);
    $drag->setMimeData($mimeData);
    $drag->setPixmap($pixmap);
    $drag->setHotSpot($hotSpot);

    my $dropAction = $drag->exec(Qt::CopyAction() | Qt::MoveAction(), Qt::CopyAction());

    if ($dropAction == Qt::MoveAction()) {
        $child->close();
    }
}

1;
