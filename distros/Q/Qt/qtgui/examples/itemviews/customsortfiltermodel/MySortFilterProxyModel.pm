package MySortFilterProxyModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::SortFilterProxyModel );
sub const() {
    return this->{const};
}

sub minDate() {
    return this->{minDate};
}

sub maxDate() {
    return this->{maxDate};
}

sub setFilterRegExp {
    this->{regExp} = shift;
    this->invalidateFilter();
}

sub filterRegExp {
    return this->{regExp};
}

# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
}
# [0]

# [1]
sub setFilterMinimumDate
{
    my ($date) = @_;
    this->{minDate} = $date;
    this->invalidateFilter();
}
# [1]

# [2]
sub setFilterMaximumDate
{
    my ($date) = @_;
    this->{maxDate} = $date;
    this->invalidateFilter();
}
# [2]

# [3]
sub filterAcceptsRow
{
    my ($sourceRow, $sourceParent) = @_;
    my $index0 = this->sourceModel()->index($sourceRow, 0, $sourceParent);
    my $index1 = this->sourceModel()->index($sourceRow, 1, $sourceParent);
    my $index2 = this->sourceModel()->index($sourceRow, 2, $sourceParent);

    return 1 unless defined this->filterRegExp();
    return (this->sourceModel()->data($index0)->toString() =~ this->filterRegExp()
            || sourceModel()->data($index1)->toString() =~ this->filterRegExp()
           && this->dateInRange(this->sourceModel()->data($index2)->toDate()));
}
# [3]

# [4] //! [5]
sub lessThan
{
    my ($left, $right) = @_;
    my $leftData = this->sourceModel()->data($left);
    my $rightData = this->sourceModel()->data($right);
# [4]

# [6]
    if ($leftData->type() == Qt::Variant::DateTime()) {
        return $leftData->toDateTime() < $rightData->toDateTime();
    } else {
        my $emailPattern = Qt::RegExp('([\w\.]*@[\w\.]*)');

        my $leftString = $leftData->toString();
        if($left->column() == 1 && $emailPattern->indexIn($leftString) != -1) {
            $leftString = $emailPattern->cap(1);
        }

        my $rightString = $rightData->toString();
        if($right->column() == 1 && $emailPattern->indexIn($rightString) != -1) {
            $rightString = $emailPattern->cap(1);
        }

        return $leftString eq $rightString;
    }
}
# [5] //! [6]

# [7]
sub dateInRange
{
    my ($date) = @_;
    return (!this->minDate->isValid() || $date > this->minDate)
           && (!this->maxDate->isValid() || $date < this->maxDate);
}
# [7]

1;
