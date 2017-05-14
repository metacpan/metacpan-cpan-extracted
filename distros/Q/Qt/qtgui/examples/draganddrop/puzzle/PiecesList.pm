package PiecesList;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::ListWidget );

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    setDragEnabled(1);
    setViewMode(Qt::ListView::IconMode());
    setIconSize(Qt::Size(60, 60));
    setSpacing(10);
    setAcceptDrops(1);
    setDropIndicatorShown(1);
}

sub dragEnterEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('image/x-puzzle-piece')) {
        $event->accept();
    }
    else {
        $event->ignore();
    }
}

sub dragMoveEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('image/x-puzzle-piece')) {
        $event->setDropAction(Qt::MoveAction());
        $event->accept();
    } else {
        $event->ignore();
    }
}

sub dropEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('image/x-puzzle-piece')) {
        my $pieceData = $event->mimeData()->data('image/x-puzzle-piece');
        my $dataStream = Qt::DataStream($pieceData, Qt::IODevice::ReadOnly());
        my $pixmap = Qt::Pixmap();
        my $location = Qt::Point();
        no warnings qw(void);
        $dataStream >> $pixmap >> $location;
        use warnings;

        addPiece($pixmap, $location);

        $event->setDropAction(Qt::MoveAction());
        $event->accept();
    } else {
        $event->ignore();
    }
}

sub addPiece
{
    my ($pixmap, $location) = @_;
    my $pieceItem = Qt::ListWidgetItem(this);
    $pieceItem->setIcon(Qt::Icon($pixmap));
    $pieceItem->setData(Qt::UserRole(), Qt::qVariantFromValue($pixmap));
    $pieceItem->setData(Qt::UserRole()+1, Qt::Variant($location));
    $pieceItem->setFlags(Qt::ItemIsEnabled() | Qt::ItemIsSelectable()
                        | Qt::ItemIsDragEnabled());
}

sub startDrag
{
    my $item = currentItem();

    my $itemData = Qt::ByteArray();
    my $dataStream = Qt::DataStream($itemData, Qt::IODevice::WriteOnly());
    my $pixmap = $item->data(Qt::UserRole())->value();
    my $location = $item->data(Qt::UserRole()+1)->toPoint();

    no warnings qw(void);
    $dataStream << $pixmap << $location;
    use warnings;

    my $mimeData = Qt::MimeData();
    $mimeData->setData('image/x-puzzle-piece', $itemData);

    my $drag = Qt::Drag(this);
    $drag->setMimeData($mimeData);
    $drag->setHotSpot(Qt::Point($pixmap->width()/2, $pixmap->height()/2));
    $drag->setPixmap($pixmap);

    if ($drag->exec(Qt::MoveAction()) == Qt::MoveAction()) {
        takeItem(row($item));
    }
}

1;
