package PuzzleWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::signals
    puzzleCompleted => [];

sub piecePixmaps() {
    return this->{piecePixmaps};
}

sub pieceRects() {
    return this->{pieceRects};
}

sub pieceLocations() {
    return this->{pieceLocations};
}

sub highlightedRect() {
    return this->{highlightedRect};
}

sub inPlace() {
    return this->{inPlace};
}

sub NEW
{
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setAcceptDrops(1);
    this->setMinimumSize(400, 400);
    this->setMaximumSize(400, 400);

    this->{highlightedRect} = Qt::Rect();
    this->{pieceRects} = [];
    this->{piecePixmaps} = [];
}

sub clear
{
    this->{pieceLocations} = [];
    this->{piecePixmaps} = [];
    this->{pieceRects} = [];
    this->{highlightedRect} = Qt::Rect();
    this->{inPlace} = 0;
    this->update();
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

sub dragLeaveEvent
{
    my ($event) = @_;
    my $updateRect = this->highlightedRect;
    this->{highlightedRect} = Qt::Rect();
    this->update($updateRect);
    $event->accept();
}

sub dragMoveEvent
{
    my ($event) = @_;
    my $updateRect = this->highlightedRect->unite(this->targetSquare($event->pos()));

    if ($event->mimeData()->hasFormat('image/x-puzzle-piece')
        && this->findPiece(this->targetSquare($event->pos())) == -1) {

        this->{highlightedRect} = this->targetSquare($event->pos());
        $event->setDropAction(Qt::MoveAction());
        $event->accept();
    } else {
        this->{highlightedRect} = Qt::Rect();
        $event->ignore();
    }

    this->update($updateRect);
}

sub dropEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasFormat('image/x-puzzle-piece')
        && this->findPiece(this->targetSquare($event->pos())) == -1) {

        my $pieceData = $event->mimeData()->data('image/x-puzzle-piece');
        my $stream = Qt::DataStream($pieceData, Qt::IODevice::ReadOnly());
        my $square = this->targetSquare($event->pos());
        my $pixmap = Qt::Pixmap();
        my $location = Qt::Point();
        no warnings qw(void); # For bitshift warning;
        $stream >> $pixmap >> $location;
        use warnings;

        push @{this->pieceLocations}, $location;
        push @{this->piecePixmaps}, $pixmap;
        push @{this->pieceRects}, $square;

        this->{highlightedRect} = Qt::Rect();
        this->update($square);

        $event->setDropAction(Qt::MoveAction());
        $event->accept();

        if ($location == Qt::Point($square->x()/80, $square->y()/80)) {
            this->{inPlace}++;
            if (this->inPlace == 25) {
                emit this->puzzleCompleted();
            }
        }
    } else {
        this->{highlightedRect} = Qt::Rect();
        $event->ignore();
    }
}

sub findPiece
{
    my ($pieceRect) = @_;
    foreach my $i (0..$#{this->pieceRects}) {
        if ($pieceRect == this->pieceRects->[$i]) {
            return $i;
        }
    }
    return -1;
}

sub mousePressEvent
{
    my ($event) = @_;
    my $square = this->targetSquare($event->pos());
    my $found = this->findPiece($square);

    if ($found == -1) {
        return;
    }

    my $location = this->pieceLocations->[$found];
    my $pixmap = this->piecePixmaps->[$found];
    splice @{this->{pieceLocations}}, $found, 1;
    splice @{this->{piecePixmaps}}, $found, 1;
    splice @{this->{pieceRects}}, $found, 1;

    if ($location == Qt::Point($square->x()/80, $square->y()/80)) {
        this->{inPlace}--;
    }

    this->update($square);

    my $itemData = Qt::ByteArray();
    my $dataStream = Qt::DataStream($itemData, Qt::IODevice::WriteOnly());

    no warnings qw(void); # For bitshift warning;
    $dataStream << $pixmap << $location;
    use warnings;

    my $mimeData = Qt::MimeData();
    $mimeData->setData('image/x-puzzle-piece', $itemData);

    my $drag = Qt::Drag(this);
    $drag->setMimeData($mimeData);
    $drag->setHotSpot($event->pos() - $square->topLeft());
    $drag->setPixmap($pixmap);

    if ($drag->start(Qt::MoveAction()) == 0) {
        splice @{this->{pieceLocations}}, $found, 0, $location;
        splice @{this->{piecePixmaps}}, $found, 0, $pixmap;
        splice @{this->{pieceRects}}, $found, 0, $square;
        this->update(this->targetSquare($event->pos()));

        if ($location == Qt::Point($square->x()/80, $square->y()/80)) {
            this->{inPlace}++;
        }
    }
}

sub paintEvent
{
    my ($event) = @_;
    my $painter = Qt::Painter();
    $painter->begin(this);
    $painter->fillRect($event->rect(), Qt::Brush(Qt::white()));

    if (this->highlightedRect->isValid()) {
        $painter->setBrush(Qt::Brush(Qt::Color(Qt::String('#ffcccc'))));
        $painter->setPen(Qt::NoPen());
        $painter->drawRect(this->highlightedRect->adjusted(0, 0, -1, -1));
    }

    foreach my $i (0..$#{this->pieceRects}) {
        $painter->drawPixmap(this->pieceRects->[$i], this->piecePixmaps->[$i]);
    }
    $painter->end();
}

sub targetSquare
{
    my ($position) = @_;
    return Qt::Rect(int($position->x()/80) * 80, int($position->y()/80) * 80, 80, 80);
}

1;
