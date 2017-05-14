package DragWidget;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Frame );

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->setMinimumSize(200, 200);
    this->setFrameStyle(Qt::Frame::Sunken() | Qt::Frame::StyledPanel());
    this->setAcceptDrops(1);

    my $boatIcon = Qt::Label(this);
    $boatIcon->setPixmap(Qt::Pixmap('images/boat.png'));
    $boatIcon->move(20, 20);
    $boatIcon->show();
    $boatIcon->setAttribute(Qt::WA_DeleteOnClose());

    my $carIcon = Qt::Label(this);
    $carIcon->setPixmap(Qt::Pixmap('images/car.png'));
    $carIcon->move(120, 20);
    $carIcon->show();
    $carIcon->setAttribute(Qt::WA_DeleteOnClose());

    my $houseIcon = Qt::Label(this);
    $houseIcon->setPixmap(Qt::Pixmap('images/house.png'));
    $houseIcon->move(20, 120);
    $houseIcon->show();
    $houseIcon->setAttribute(Qt::WA_DeleteOnClose());
}
# [0]

sub dragEnterEvent {
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('application/x-dnditemdata')) {
        my $source = $event->source();
        if (defined $source && $source == this) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
    } else {
        $event->ignore();
    }
}

sub dragMoveEvent {
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('application/x-dnditemdata')) {
        my $source = $event->source();
        if (defined $source && $source == this) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
    } else {
        $event->ignore();
    }
}

sub dropEvent {
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('application/x-dnditemdata')) {
        my $itemData = $event->mimeData()->data('application/x-dnditemdata');
        my $dataStream = Qt::DataStream($itemData, Qt::IODevice::ReadOnly());
        
        my $pixmap = Qt::Pixmap();
        my $offset = Qt::Point();
        {
            no warnings qw(void); # For bitshift warning
            $dataStream >> $pixmap >> $offset;
        }

        my $newIcon = Qt::Label(this);
        $newIcon->setPixmap($pixmap);
        $newIcon->move($event->pos() - $offset);
        $newIcon->show();
        $newIcon->setAttribute(Qt::WA_DeleteOnClose());

        my $source = $event->source();
        if (defined $source && $source == this) {
            $event->setDropAction(Qt::MoveAction());
            $event->accept();
        } else {
            $event->acceptProposedAction();
        }
    } else {
        $event->ignore();
    }
}

# [1]
sub mousePressEvent {
    my ($event) = @_;
    my $child = this->childAt($event->pos());
    if (!$child) {
        return;
    }

    my $pixmap = $child->pixmap();

    my $itemData = Qt::ByteArray();
    my $dataStream = Qt::DataStream($itemData, Qt::IODevice::WriteOnly());
    {
        no warnings qw(void); # For bitshift warning
        $dataStream << $pixmap << Qt::Point($event->pos() - $child->pos());
    }
# [1]

# [2]
    my $mimeData = Qt::MimeData();
    $mimeData->setData('application/x-dnditemdata', $itemData);
# [2]
        
# [3]
    my $drag = Qt::Drag(this);
    $drag->setMimeData($mimeData);
    $drag->setPixmap($pixmap);
    $drag->setHotSpot($event->pos() - $child->pos());
# [3]

    # XXX Fix this.  Shared memory on the Pixmap causes $tempPixmap and $pixmap
    # to point to the same data.  The C++ code paints on the tempPixmap instead
    # of the pixmap.
    my $tempPixmap = Qt::Pixmap($pixmap);
    my $painter = Qt::Painter();
    $painter->begin($pixmap);
    $painter->fillRect($tempPixmap->rect(), Qt::Color(127,127,127,127));
    $painter->end();

    $child->setPixmap($pixmap);

    my $result = $drag->exec(Qt::CopyAction() | Qt::MoveAction(), Qt::CopyAction());
    if ($result == Qt::MoveAction()) {
        $child->close();
    }
    else {
        $child->show();
        $child->setPixmap($tempPixmap);
    }
}

1;
