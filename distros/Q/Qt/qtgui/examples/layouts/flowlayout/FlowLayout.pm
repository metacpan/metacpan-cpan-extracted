package FlowLayout;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Layout );
use List::Util qw(max);

sub itemList() {
    return this->{itemList};
}

sub m_hSpace() {
    return this->{m_hSpace};
}

sub m_vSpace() {
    return this->{m_vSpace};
}

# [1]
sub NEW
{
    my ($class, $parent);
    my($margin, $hSpacing, $vSpacing) = (-1, -1, -1);
    if ( scalar @_ == 5 ) {
        ($class, $parent, $margin, $hSpacing, $vSpacing) = @_;
    }
    elsif ( scalar @_ == 4 ) {
        ($class, $margin, $hSpacing, $vSpacing) = @_;
    }
    else {
        ($class) = @_;
    }
    $class->SUPER::NEW($parent);
    this->{itemList} = [];
    this->{m_hSpace} = $hSpacing;
    this->{m_vSpace} = $vSpacing;
    this->setContentsMargins($margin, $margin, $margin, $margin);
}
# [1]

# [3]
sub addItem
{
    my ($item) = @_;
    push @{this->itemList}, $item;
}
# [3]

# [4]
sub horizontalSpacing
{
    if (this->m_hSpace >= 0) {
        return this->m_hSpace;
    } else {
        return this->smartSpacing(Qt::Style::PM_LayoutHorizontalSpacing());
    }
}

sub verticalSpacing
{
    if (this->m_vSpace >= 0) {
        return this->m_vSpace;
    } else {
        return this->smartSpacing(Qt::Style::PM_LayoutVerticalSpacing());
    }
}
# [4]

# [5]
sub count
{
    return scalar @{this->itemList};
}

sub itemAt
{
    my ($index) = @_;
    return this->itemList->[$index];
}

sub takeAt
{
    my ($index) = @_;
    if ($index >= 0 && $index < scalar @{this->itemList}) {
        return splice @{this->itemList}, $index, 1;
    }
    else {
        return 0;
    }
}
# [5]

# [6]
sub expandingDirections
{
    return 0;
}
# [6]

# [7]
sub hasHeightForWidth
{
    return 1;
}

sub heightForWidth
{
    my ($width) = @_;
    my $height = this->doLayout(Qt::Rect(0, 0, $width, 0), 1);
    return $height;
}
# [7]

# [8]
sub setGeometry
{
    my ($rect) = @_;
    this->SUPER::setGeometry($rect);
    this->doLayout($rect, 0);
}

sub sizeHint
{
    return this->minimumSize();
}

sub minimumSize
{
    my $size = Qt::Size();
    my $item = Qt::LayoutItem();
    foreach my $item ( @{this->itemList} ) {
        $size = $size->expandedTo($item->minimumSize());
    }

    $size += Qt::Size(2*this->margin(), 2*this->margin());
    return $size;
}
# [8]

# [9]
sub doLayout
{
    my ($rect, $testOnly) = @_;
    my ( $left, $top, $right, $bottom );
    this->getContentsMargins($left, $top, $right, $bottom);
    my $effectiveRect = $rect->adjusted(+$left, +$top, -$right, -$bottom);
    my $x = $effectiveRect->x();
    my $y = $effectiveRect->y();
    my $lineHeight = 0;
# [9]

# [10]
    my $item = Qt::LayoutItem();
    foreach my $item ( @{this->itemList} ) {
        my $wid = $item->widget();
        my $spaceX = this->horizontalSpacing();
        if ($spaceX == -1) {
            $spaceX = $wid->style()->layoutSpacing(
                Qt::SizePolicy::PushButton(), Qt::SizePolicy::PushButton(), Qt::Horizontal());
        }
        my $spaceY = this->verticalSpacing();
        if ($spaceY == -1) {
            $spaceY = $wid->style()->layoutSpacing(
                Qt::SizePolicy::PushButton(), Qt::SizePolicy::PushButton(), Qt::Vertical());
        }
# [10]
# [11]
        my $nextX = $x + $item->sizeHint()->width() + $spaceX;
        if ($nextX - $spaceX > $effectiveRect->right() && $lineHeight > 0) {
            $x = $effectiveRect->x();
            $y = $y + $lineHeight + $spaceY;
            $nextX = $x + $item->sizeHint()->width() + $spaceX;
            $lineHeight = 0;
        }

        if (!$testOnly) {
            $item->setGeometry(Qt::Rect(Qt::Point($x, $y), $item->sizeHint()));
        }

        $x = $nextX;
        $lineHeight = max($lineHeight, $item->sizeHint()->height());
    }
    return $y + $lineHeight - $rect->y() + $bottom;
}
# [11]
# [12]
sub smartSpacing
{
    my ($pm) = @_;
    my $parent = this->parent();
    if (!$parent) {
        return -1;
    } elsif ($parent->isWidgetType()) {
        my $pw = $parent;
        return $pw->style()->pixelMetric($pm, undef, $pw);
    } else {
        return $parent->spacing();
    }
}
# [12]

1;
