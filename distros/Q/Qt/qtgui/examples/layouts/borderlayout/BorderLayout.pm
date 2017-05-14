package ItemWrapper;

sub new {
    my ($class, $i, $p) = @_;
    return bless {item=>$i, position=>$p}, $class;
}

sub item() {
    my ($self) = @_;
    return $self->{item};
}

sub position() {
    my ($self) = @_;
    return $self->{position};
}

package BorderLayout;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Layout );

use constant {
    West => 1,
    North => 2,
    South => 3,
    East => 4,
    Center => 5
};


use constant {
    MinimumSize => 1,
    SizeHint => 2
};

sub list() {
    return this->{list};
}

sub NEW
{
    my ($class, $parent, $margin, $spacing) = @_;
    $class->SUPER::NEW( $parent );
    this->{list} = [];
    if ( !$spacing ) {
        $margin = $spacing;
    }
    else {
        this->setSpacing($spacing);
    }
    this->setMargin($margin);
}

sub addItem
{
    my ($item) = @_;
    this->add($item, West);
}

sub addWidget
{
    my ($widget, $position) = @_;
    this->add(Qt::WidgetItem($widget), $position);
}

sub expandingDirections
{
    return Qt::Horizontal() | Qt::Vertical();
}

sub hasHeightForWidth
{
    return 0;
}

sub count
{
    return scalar @{this->list};
}

sub itemAt
{
    my ($index) = @_;
    my $wrapper = this->list->[$index];
    if ($wrapper) {
        return $wrapper->item;
    }
    else {
        return 0;
    }
}

sub minimumSize
{
    return this->calculateSize(MinimumSize);
}

sub setGeometry
{
    my ($rect) = @_;
    my $center;
    my $eastWidth = 0;
    my $westWidth = 0;
    my $northHeight = 0;
    my $southHeight = 0;
    my $centerHeight = 0;
    my $i;

    this->SUPER::setGeometry($rect);

    for ($i = 0; $i < scalar @{this->list}; ++$i) {
        my $wrapper = this->list->[$i];
        my $item = $wrapper->item;
        my $position = $wrapper->position;

        if ($position == North) {
            $item->setGeometry(Qt::Rect($rect->x(), $northHeight, $rect->width(),
                                    $item->sizeHint()->height()));

            $northHeight += $item->geometry()->height() + this->spacing();
        } elsif ($position == South) {
            $item->setGeometry(Qt::Rect($item->geometry()->x(),
                                    $item->geometry()->y(), $rect->width(),
                                    $item->sizeHint()->height()));

            $southHeight += $item->geometry()->height() + this->spacing();

            $item->setGeometry(Qt::Rect($rect->x(),
                              $rect->y() + $rect->height() - $southHeight + this->spacing(),
                              $item->geometry()->width(),
                              $item->geometry()->height()));
        } elsif ($position == Center) {
            $center = $wrapper;
        }
    }

    $centerHeight = $rect->height() - $northHeight - $southHeight;

    for ($i = 0; $i < scalar @{this->list}; ++$i) {
        my $wrapper = this->list->[$i];
        my $item = $wrapper->item;
        my $position = $wrapper->position;

        if ($position == West) {
            $item->setGeometry(Qt::Rect($rect->x() + $westWidth, $northHeight,
                                    $item->sizeHint()->width(), $centerHeight));

            $westWidth += $item->geometry()->width() + this->spacing();
        } elsif ($position == East) {
            $item->setGeometry(Qt::Rect($item->geometry()->x(), $item->geometry()->y(),
                                    $item->sizeHint()->width(), $centerHeight));

            $eastWidth += $item->geometry()->width() + this->spacing();

            $item->setGeometry(Qt::Rect(
                              $rect->x() + $rect->width() - $eastWidth + this->spacing(),
                              $northHeight, $item->geometry()->width(),
                              $item->geometry()->height()));
        }
    }

    if ($center) {
        $center->item->setGeometry(Qt::Rect($westWidth, $northHeight,
                                        $rect->width() - $eastWidth - $westWidth,
                                        $centerHeight));
    }
}

sub sizeHint
{
    return this->calculateSize(SizeHint);
}

sub takeAt
{
    my ($index) = @_;
    if ($index >= 0 && $index < scalar @{this->list}) {
        my $layoutStruct = splice @{this->list}, $index, 1;
        return $layoutStruct->item;
    }
    return 0;
}

sub add
{
    my ($item, $position) = @_;
    push @{this->list}, ItemWrapper->new($item, $position);
}

sub calculateSize
{
    my ($sizeType) = @_;
    my $totalSize = Qt::Size();

    for (my $i = 0; $i < scalar @{this->list}; ++$i) {
        my $wrapper = this->list->[$i];
        my $position = $wrapper->position;
        my $itemSize = Qt::Size();

        if ($sizeType == MinimumSize) {
            $itemSize = $wrapper->item->minimumSize();
        }
        else {
            $itemSize = $wrapper->item->sizeHint();
        }

        if ($position == North || $position == South || $position == Center) {
            $totalSize->setHeight( $totalSize->height() + $itemSize->height() );
        }

        if ($position == West || $position == East || $position == Center) {
            $totalSize->setWidth( $totalSize->width() + $itemSize->width() );
        }
    }
    return $totalSize;
}

1;
