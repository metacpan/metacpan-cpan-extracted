package CustomSqlModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtSql4;
use QtCore4::isa qw( Qt::SqlQueryModel );

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
}

# [0]
sub data
{
    my ($index, $role) = @_;
    my $value = this->SUPER::data($index, $role);
    if ($value->isValid() && $role == Qt::DisplayRole()) {
        if ($index->column() == 0) {
            return Qt::Variant(Qt::String('#' . $value->toString()));
        }
        elsif ($index->column() == 2) {
            return Qt::Variant(Qt::String(uc $value->toString()));
        }
    }
    if ($role == Qt::TextColorRole() && $index->column() == 1) {
        return Qt::qVariantFromValue(Qt::Color(Qt::blue()));
    }
    return $value;
}
# [0]

1;
