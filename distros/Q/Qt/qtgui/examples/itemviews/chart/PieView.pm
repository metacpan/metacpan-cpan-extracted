package PieView;

use strict;
use warnings;

use List::Util qw(min max);
use Math::Trig;
use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::AbstractItemView);
use QtCore4::slots
    dataChanged => ['const Qt::ModelIndex&', 'const Qt::ModelIndex&'],
    rowsInserted => ['const Qt::ModelIndex&', 'int', 'int'],
    rowsAboutToBeRemoved => ['const Qt::ModelIndex&', 'int', 'int'];

use constant { M_PI => 3.1415927 };

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->horizontalScrollBar()->setRange(0, 0);
    this->verticalScrollBar()->setRange(0, 0);

    my $margin = 8;
    this->{margin} = $margin;
    my $totalSize = 300;
    this->{totalSize} = $totalSize;
    this->{pieSize} = $totalSize - 2 * $margin;
    this->{validItems} = 0;
    this->{totalValue} = 0.0;
    this->{rubberBand} = 0;
}

sub dataChanged {
    my ($topLeft, $bottomRight) = @_;
    this->SUPER::dataChanged($topLeft, $bottomRight);

    my $validItems = 0;
    my $totalValue = 0.0;

    foreach my $row (0..this->model()->rowCount(this->rootIndex())) {

        my $index = this->model()->index($row, 1, this->rootIndex());
        my $value = this->model()->data($index)->toDouble();

        if ($value > 0.0) {
            $totalValue += $value;
            $validItems++;
        }
    }
    this->{validItems} = $validItems;
    this->{totalValue} = $totalValue;
    this->viewport()->update();
}

sub edit {
    my ($index, $trigger, $event) = @_;
    if ($index->column() == 0) {
        return this->SUPER::edit($index, $trigger, $event);
    }
    else {
        return 0;
    }
}

=begin

    Returns the item that covers the coordinate given in the view.

=cut

sub indexAt {
    my ($point) = @_;
    my $totalSize = this->{totalSize};
    if (this->{validItems} == 0) {
        return Qt::ModelIndex();
    }

    # Transform the view coordinates into contents widget coordinates.
    my $wx = $point->x() + this->horizontalScrollBar()->value();
    my $wy = $point->y() + this->verticalScrollBar()->value();

    if ($wx < $totalSize) {
        my $cx = $wx - $totalSize/2;
        my $cy = $totalSize/2 - $wy; # positive cy for items above the center

        # Determine the distance from the center point of the pie chart.
        my $d = (($cx**2) + ($cy**2))**0.5;

        if ($d == 0 || $d > this->{pieSize}/2) {
            return Qt::ModelIndex();
        }

        # Determine the angle of the point.
        my $angle = (180 / M_PI) * acos($cx/$d);
        if ($cy < 0) {
            $angle = 360 - $angle;
        }

        # Find the relevant slice of the pie.
        my $startAngle = 0.0;

        foreach my $row (0..this->model()->rowCount(this->rootIndex())) {

            my $index = this->model()->index($row, 1, this->rootIndex());
            my $value = this->model()->data($index)->toDouble();

            if ($value > 0.0) {
                my $sliceAngle = 360*$value/this->{totalValue};

                if ($angle >= $startAngle && $angle < ($startAngle + $sliceAngle)) {
                    return this->model()->index($row, 1, this->rootIndex());
                }

                $startAngle += $sliceAngle;
            }
        }
    } else {
        my $itemHeight = Qt::FontMetrics(this->viewOptions()->font)->height();
        my $listItem = int(($wy - this->{margin}) / $itemHeight);
        my $validRow = 0;

        foreach my $row (0..this->model()->rowCount(this->rootIndex())) {

            my $index = this->model()->index($row, 1, this->rootIndex());
            if (this->model()->data($index)->toDouble() > 0.0) {

                if ($listItem == $validRow) {
                    return this->model()->index($row, 0, this->rootIndex());
                }

                # Update the list index that corresponds to the next valid row.
                $validRow++;
            }
        }
    }

    return Qt::ModelIndex();
}

sub isIndexHidden {
    return 0;
}

=begin

    Returns the rectangle of the item at position \a index in the
    model. The rectangle is in contents coordinates.

=cut

sub itemRect {
    my ($index) = @_;
    if (!$index->isValid()) {
        return Qt::Rect();
    }

    # Check whether the index's row is in the list of rows represented
    # by slices.
    my $valueIndex;

    if ($index->column() != 1) {
        $valueIndex = this->model()->index($index->row(), 1, this->rootIndex());
    }
    else {
        $valueIndex = $index;
    }

    if (this->model()->data($valueIndex)->toDouble() > 0.0) {

        my $listItem = 0;
        for (my $row = $index->row()-1; $row >= 0; --$row) {
            if (this->model()->data(this->model()->index($row, 1, this->rootIndex()))->toDouble() > 0.0) {
                $listItem++;
            }
        }

        my $itemHeight;

        if ($index->column() == 0) {
            $itemHeight = Qt::FontMetrics(this->viewOptions()->font)->height();

            return Qt::Rect(this->{totalSize},
                         int(this->{margin} + $listItem*$itemHeight),
                         this->{totalSize} - this->{margin}, int($itemHeight));
        }
        elsif ($index->column() == 1) {
            return this->viewport()->rect();
        }

    }
    return Qt::Rect();
}

sub itemRegion {
    my ($index) = @_;
    if (!$index->isValid()) {
        return Qt::Region();
    }

    if ($index->column() != 1) {
        return itemRect($index);
    }

    if (this->model()->data($index)->toDouble() <= 0.0) {
        return Qt::Region();
    }

    my $startAngle = 0.0;
    foreach my $row (0..this->model()->rowCount(this->rootIndex())) {

        my $sliceIndex = this->model()->index($row, 1, this->rootIndex());
        my $value = this->model()->data($sliceIndex)->toDouble();

        if ($value > 0.0) {
            my $angle = 360*$value/this->{totalValue};

            if ($sliceIndex == $index) {
                my $slicePath = Qt::PainterPath();
                my $totalSize = this->{totalSize};
                my $margin = this->{margin};
                my $pieSize = this->{pieSize};
                $slicePath->moveTo($totalSize/2, $totalSize/2);
                $slicePath->arcTo($margin, $margin, $margin+$pieSize, $margin+$pieSize,
                                $startAngle, $angle);
                $slicePath->closeSubpath();

                return Qt::Region($slicePath->toFillPolygon()->toPolygon());
            }

            $startAngle += $angle;
        }
    }

    return Qt::Region();
}

sub horizontalOffset {
    return this->horizontalScrollBar()->value();
}

sub mousePressEvent {
    my ($event) = @_;

    this->SUPER::mousePressEvent($event);

    my $origin = Qt::Point($event->pos());
    this->{origin} = $origin;
    my $rubberBand = this->{rubberBand};
    if (!$rubberBand) {
        $rubberBand = Qt::RubberBand(Qt::RubberBand::Rectangle(), this);
        this->{rubberBand} = $rubberBand;
    }
    $rubberBand->setGeometry(Qt::Rect($origin, Qt::Size()));
    $rubberBand->show();
}

sub mouseMoveEvent {
    my ($event) = @_;
    my $rubberBand = this->{rubberBand};
    if ($rubberBand) {
        $rubberBand->setGeometry(Qt::Rect(this->{origin}, $event->pos())->normalized());
    }
    this->SUPER::mouseMoveEvent($event);
}

sub mouseReleaseEvent {
    my ($event) = @_;
    this->SUPER::mouseReleaseEvent($event);
    my $rubberBand = this->{rubberBand};
    if ($rubberBand) {
        $rubberBand->hide();
    }
    this->viewport()->update();
}

sub moveCursor {
    my ($cursorAction) = @_;
    my $current = this->currentIndex();

    if ($cursorAction == Qt::AbstractItemView::MoveLeft() ||
        $cursorAction == Qt::AbstractItemView::MoveUp() ) {
        if ($current->row() > 0) {
            $current = this->model()->index($current->row() - 1, $current->column(),
                                     this->rootIndex());
        }
        else {
            $current = this->model()->index(0, $current->column(), this->rootIndex());
        }
    }
    elsif ($cursorAction == Qt::AbstractItemView::MoveRight() ||
           $cursorAction == Qt::AbstractItemView::MoveDown() ) {
        if ($current->row() < this->rows($current) - 1) {
            $current = this->model()->index($current->row() + 1, $current->column(),
                                     this->rootIndex());
        }
        else {
            $current = this->model()->index(this->rows($current) - 1, $current->column(),
                                     this->rootIndex());
        }
    }

    this->viewport()->update();
    this->{current} = $current;
    return $current;
}

sub paintEvent {
    my ($event) = @_;
    my $selections = this->selectionModel();
    my $option = this->viewOptions();
    my $state = $option->state;

    my $background = $option->palette()->base();
    my $foreground = Qt::Pen($option->palette->color(Qt::Palette::WindowText()));
    my $textPen = Qt::Pen($option->palette->color(Qt::Palette::Text()));
    my $highlightedPen = Qt::Pen($option->palette->color(Qt::Palette::HighlightedText()));

    my $painter = Qt::Painter(this->viewport());
    $painter->setRenderHint(Qt::Painter::Antialiasing());

    $painter->fillRect($event->rect(), $background);
    $painter->setPen($foreground);

    # Viewport rectangles
    my $margin = this->{margin};
    my $totalSize = this->{totalSize};
    my $pieSize = this->{pieSize};
    my $pieRect = Qt::Rect($margin, $margin, $pieSize, $pieSize);
    my $keyPoint = Qt::Point($totalSize - this->horizontalScrollBar()->value(),
                             $margin - this->verticalScrollBar()->value());

    if (this->{validItems} > 0) {

        $painter->save();
        $painter->translate($pieRect->x() - this->horizontalScrollBar()->value(),
                          $pieRect->y() - this->verticalScrollBar()->value());
        $painter->drawEllipse(0, 0, $pieSize, $pieSize);
        my $startAngle = 0.0;
        my $row;

        foreach my $row ( 0..this->model()->rowCount(this->rootIndex()) ) {

            my $index = this->model()->index($row, 1, this->rootIndex());
            my $value = this->model()->data($index)->toDouble();

            if ($value > 0.0) {
                my $angle = 360*$value/this->{totalValue};

                my $colorIndex = this->model()->index($row, 0, this->rootIndex());
                my $color = Qt::Color(Qt::String(this->model()->data($colorIndex,
                                Qt::DecorationRole())->toString()));

                if (this->currentIndex() == $index) {
                    $painter->setBrush(Qt::Brush($color, Qt::Dense4Pattern()));
                }
                elsif ($selections->isSelected($index)) {
                    $painter->setBrush(Qt::Brush($color, Qt::Dense3Pattern()));
                }
                else {
                    $painter->setBrush(Qt::Brush($color));
                }

                $painter->drawPie(0, 0, $pieSize, $pieSize, int($startAngle*16),
                                int($angle*16));

                $startAngle += $angle;
            }
        }
        $painter->restore();

        my $keyNumber = 0;

        foreach my $row ( 0..this->model()->rowCount(this->rootIndex()) ) {

            my $index = this->model()->index($row, 1, this->rootIndex());
            my $value = this->model()->data($index)->toDouble();

            if ($value > 0.0) {
                my $labelIndex = this->model()->index($row, 0, this->rootIndex());

                # TODO: Fix this.  It should be able to do
                # $option->rect = this->visualRect($labelIndex), etc.
                my $option = this->viewOptions();
                $option->setRect( this->visualRect($labelIndex) );
                if ($selections->isSelected($labelIndex)) {
                    $option->setState( $option->state | Qt::Style::State_Selected() );
                }
                if (this->currentIndex() == $labelIndex) {
                    $option->setState( $option->state | Qt::Style::State_HasFocus() );
                }
                this->itemDelegate()->paint($painter, $option, $labelIndex);

                $keyNumber++;
            }
        }
    }
    $painter->end();
}

sub resizeEvent {
    this->updateGeometries();
}

sub rows {
    my ($index) = @_;
    return this->model()->rowCount(this->model()->parent($index));
}

sub rowsInserted {
    my ($parent, $start, $end) = @_;
    foreach my $row ($start..$end) {

        my $index = this->model()->index($row, 1, this->rootIndex());
        my $value = this->model()->data($index)->toDouble();

        if ($value > 0.0) {
            this->{totalValue} += $value;
            this->{validItems}++;
        }
    }

    this->SUPER::rowsInserted($parent, $start, $end);
}

sub rowsAboutToBeRemoved {
    my ($parent, $start, $end) = @_;
    foreach my $row ($start..$end) {

        my $index = this->model()->index($row, 1, this->rootIndex());
        my $value = this->model()->data($index)->toDouble();
        if ($value > 0.0) {
            this->{totalValue} -= $value;
            this->{validItems}--;
        }
    }

    this->SUPER::rowsAboutToBeRemoved($parent, $start, $end);
}

sub scrollContentsBy {
    my ($dx, $dy) = @_;
    this->viewport()->scroll($dx, $dy);
}

sub scrollTo {
    my ($index) = @_;
    my $area = this->viewport()->rect();
    my $rect = this->visualRect($index);

    if ($rect->left() < $area->left()) {
        this->horizontalScrollBar()->setValue(
            this->horizontalScrollBar()->value() + $rect->left() - $area->left());
    }
    elsif ($rect->right() > $area->right()) {
        this->horizontalScrollBar()->setValue(
            this->horizontalScrollBar()->value() + min(
                $rect->right() - $area->right(), $rect->left() - $area->left()));
    }

    if ($rect->top() < $area->top()) {
        this->verticalScrollBar()->setValue(
            this->verticalScrollBar()->value() + $rect->top() - $area->top());
    }
    elsif ($rect->bottom() > $area->bottom()) {
        this->verticalScrollBar()->setValue(
            this->verticalScrollBar()->value() + min(
                $rect->bottom() - $area->bottom(), $rect->top() - $area->top()));
    }

    this->update();
}

=begin

    Find the indices corresponding to the extent of the selection.

=cut

sub setSelection {
    my ($rect, $command) = @_;
    # Use content widget coordinates because we will use the itemRegion()
    # function to check for intersections.

    my $contentsRect = $rect->translated(
                            this->horizontalScrollBar()->value(),
                            this->verticalScrollBar()->value())->normalized();

    my $rows = this->model()->rowCount(this->rootIndex());
    my $columns = this->model()->columnCount(this->rootIndex());
    my $indexes;

    foreach my $row (0..$rows) {
        foreach my $column (0..$columns) {
            my $index = this->model()->index($row, $column, this->rootIndex());
            my $region = this->itemRegion($index);
            if (!$region->intersect($contentsRect)->isEmpty()) {
                push @{$indexes}, $index;
            }
        }
    }

    if ( ref $indexes eq 'ARRAY' && scalar @{$indexes} > 0) {
        my $firstRow = $indexes->[0]->row();
        my $lastRow = $indexes->[0]->row();
        my $firstColumn = $indexes->[0]->column();
        my $lastColumn = $indexes->[0]->column();

        foreach my $i (1..$#{$indexes}) {
            $firstRow = min($firstRow, $indexes->[$i]->row());
            $lastRow = max($lastRow, $indexes->[$i]->row());
            $firstColumn = min($firstColumn, $indexes->[$i]->column());
            $lastColumn = max($lastColumn, $indexes->[$i]->column());
        }

        my $selection = Qt::ItemSelection(
            this->model()->index($firstRow, $firstColumn, this->rootIndex()),
            this->model()->index($lastRow, $lastColumn, this->rootIndex()));
        this->selectionModel()->select($selection, $command);
    } else {
        my $noIndex = Qt::ModelIndex();
        my $selection = Qt::ItemSelection($noIndex, $noIndex);
        this->selectionModel()->select($selection, $command);
    }

    this->update();
}

sub updateGeometries {
    this->horizontalScrollBar()->setPageStep(this->viewport()->width());
    this->horizontalScrollBar()->setRange(0, max(0, 2*this->{totalSize} - this->viewport()->width()));
    this->verticalScrollBar()->setPageStep(this->viewport()->height());
    this->verticalScrollBar()->setRange(0, max(0, this->{totalSize} - this->viewport()->height()));
}

sub verticalOffset {
    return this->verticalScrollBar()->value();
}

=begin

    Returns the position of the item in viewport coordinates.

=cut

sub visualRect {
    my ($index) = @_;
    my $rect = this->itemRect($index);
    if ($rect->isValid()) {
        return Qt::Rect($rect->left() - this->horizontalScrollBar()->value(),
                     $rect->top() - this->verticalScrollBar()->value(),
                     $rect->width(), $rect->height());
    }
    else {
        return $rect;
    }
}

=begin

    Returns a region corresponding to the selection in viewport coordinates.

=cut

sub visualRegionForSelection {
    my ($selection) = @_;
    my $ranges = ref $selection eq 'ARRAY' ? scalar @{$selection} : 0;

    if ($ranges == 0) {
        return Qt::Region( Qt::Rect() );
    }

    my $region;
    foreach my $i (0..$ranges) {
        my $range = $selection->at($i);
        foreach my $row ($range->top()..$range->bottom()) {
            foreach my $col ($range->left()..$range->right()) {
                my $index = this->model()->index($row, $col, this->rootIndex());
                $region += visualRect($index);
            }
        }
    }
    return $region;
}

1;
