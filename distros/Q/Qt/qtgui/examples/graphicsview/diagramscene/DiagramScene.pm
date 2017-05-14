package DiagramScene;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use DiagramItem;
use DiagramTextItem;
use Arrow;

# [0]
use QtCore4::isa qw( Qt::GraphicsScene );

use QtCore4::slots
    setMode => ['int'],
    setItemType => ['int'],
    editorLostFocus => ['QGraphicsTextItem *'];

use QtCore4::signals
    itemInserted => ['QGraphicsPolygonItem *'],
    textInserted => ['QGraphicsTextItem *'],
    itemSelected => ['QGraphicsItem *'];

use constant {
    InsertItem => 0,
    InsertLine => 1,
    InsertText => 2,
    MoveItem => 3,
};

sub font()
    { return this->{myFont}; }
sub textColor()
    { return this->{myTextColor}; }
sub itemColor()
    { return this->{myItemColor}; }
sub lineColor()
    { return this->{myLineColor}; }

sub myItemType() {
    return this->{myItemType};
}

sub myItemMenu() {
    return this->{myItemMenu};
}

sub myMode() {
    return this->{myMode};
}

sub leftButtonDown() {
    return this->{leftButtonDown};
}

sub startPoint() {
    return this->{startPoint};
}

sub line() {
    return this->{line};
}

sub textItem() {
    return this->{textItem};
}

# [0]
sub NEW
{
    my ($class, $itemMenu, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{myItemMenu} = $itemMenu;
    this->{myMode} = MoveItem;
    this->{myItemType} = DiagramItem::Step;
    this->{line} = undef;
    this->{textItem} = DiagramTextItem();
    this->{myItemColor} = Qt::white();
    this->{myTextColor} = Qt::black();
    this->{myLineColor} = Qt::black();
    this->{myFont} = Qt::Font();
}
# [0]

# [1]
sub setLineColor
{
    my ($color) = @_;
    this->{myLineColor} = $color;
    if (this->isItemChange(Arrow::Type)) {
        my $item = this->selectedItems()->[0];
        $item->setColor(this->lineColor);
        this->update();
    }
}
# [1]

# [2]
sub setTextColor
{
    my ($color) = @_;
    this->{myTextColor} = $color;
    if (this->isItemChange(DiagramTextItem::Type)) {
        my $item = this->selectedItems()->[0];
        $item->setDefaultTextColor(this->textColor);
    }
}
# [2]

# [3]
sub setItemColor
{
    my ($color) = @_;
    this->{myItemColor} = $color;
    if (this->isItemChange(DiagramItem::Type)) {
        my $item = this->selectedItems()->[0];
        $item->setBrush(Qt::Brush(this->itemColor));
    }
}
# [3]

# [4]
sub setFont
{
    my ($font) = @_;
    this->{myFont} = $font;

    if (this->isItemChange(DiagramTextItem::Type)) {
        my $item = this->selectedItems()->[0];
        # At this point the selection can change so the first selected item might not be a DiagramTextItem
        if (ref $item eq ' DiagramTextItem') {
            $item->setFont(this->font);
        }
    }
}
# [4]

sub setMode
{
    my ($mode) = @_;
    this->{myMode} = $mode;
}

sub setItemType
{
    my ($type) = @_;
    this->{myItemType} = $type;
}

# [5]
sub editorLostFocus
{
    my ($item) = @_;
    my $cursor = $item->textCursor();
    $cursor->clearSelection();
    $item->setTextCursor($cursor);

    if (!$item->toPlainText()) {
        this->removeItem($item);
        $item->deleteLater();
    }
}
# [5]

# [6]
sub mousePressEvent
{
    my ($mouseEvent) = @_;
    if ($mouseEvent->button() != Qt::LeftButton()) {
        return;
    }

    if ( this->myMode == InsertItem ) {
        my $item = DiagramItem(this->myItemType, this->myItemMenu);
        $item->setBrush(Qt::Brush(this->itemColor));
        this->addItem($item);
        $item->setPos($mouseEvent->scenePos());
        emit this->itemInserted($item);
# [6] //! [7]
    }
    elsif ( this->myMode == InsertLine ) {
        this->{line} = Qt::GraphicsLineItem(Qt::LineF($mouseEvent->scenePos(),
                                    $mouseEvent->scenePos()));
        this->line->setPen(Qt::Pen(Qt::Brush(this->{myLineColor}), 2));
        this->addItem(this->line);
# [7] //! [8]
    }
    elsif ( this->myMode == InsertText ) {
        this->{textItem} = DiagramTextItem();
        this->textItem->setFont(this->font);
        this->textItem->setTextInteractionFlags(Qt::TextEditorInteraction());
        this->textItem->setZValue(1000.0);
        this->connect(this->textItem, SIGNAL 'lostFocus(QGraphicsTextItem*)',
                this, SLOT 'editorLostFocus(QGraphicsTextItem*)');
        this->connect(this->textItem, SIGNAL 'selectedChange(QGraphicsItem*)',
                this, SIGNAL 'itemSelected(QGraphicsItem*)');
        this->addItem(this->textItem);
        this->textItem->setDefaultTextColor(Qt::Color(this->textColor));
        this->textItem->setPos($mouseEvent->scenePos());
        emit this->textInserted(this->textItem);
    }
# [8] //! [9]
    this->SUPER::mousePressEvent($mouseEvent);
}
# [9]

# [10]
sub mouseMoveEvent
{
    my ($mouseEvent) = @_;
    if (this->myMode == InsertLine && defined line) {
        my $newLine = Qt::LineF(this->line->line()->p1(), $mouseEvent->scenePos());
        this->line->setLine($newLine);
    } elsif (this->myMode == MoveItem) {
        this->SUPER::mouseMoveEvent($mouseEvent);
    }
}
# [10]

# [11]
sub mouseReleaseEvent
{
    my ($mouseEvent) = @_;
    if (defined this->line && this->myMode == InsertLine) {
        my $startItems = this->items(this->line->line()->p1());
        if (scalar @{$startItems} && $startItems->[0] eq this->line) {
            shift @{$startItems};
        }
        my $endItems = this->items(this->line->line()->p2());
        if (scalar @{$endItems} && $endItems->[0] eq this->line) {
            shift @{$endItems};
        }

        this->removeItem(this->line);
# [11] //! [12]

        if (scalar @{$startItems} > 0 && scalar @{$endItems} > 0 &&
            $startItems->[0]->type() == DiagramItem::Type &&
            $endItems->[0]->type() == DiagramItem::Type &&
            $startItems->[0] != $endItems->[0]) {
            my $startItem = $startItems->[0];
            my $endItem = $endItems->[0];
            my $arrow = Arrow($startItem, $endItem);
            $arrow->setColor(this->lineColor);
            $startItem->addArrow($arrow);
            $endItem->addArrow($arrow);
            $arrow->setZValue(-1000.0);
            this->addItem($arrow);
            $arrow->updatePosition();
        }
    }
# [12] //! [13]
    this->{line} = undef;
    this->SUPER::mouseReleaseEvent($mouseEvent);
}
# [13]

# [14]
sub isItemChange
{
    my ($type) = @_;
    foreach my $item ( @{this->selectedItems()} ) {
        if ($item->type() == $type) {
            return 1;
        }
    }
    return 0;
}
# [14]

1;
