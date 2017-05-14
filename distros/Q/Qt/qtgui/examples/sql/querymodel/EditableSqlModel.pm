package EditableSqlModel;

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
sub flags
{
    my ($index) = @_;
    my $flags = this->SUPER::flags($index);
    if ($index->column() == 1 || $index->column() == 2) {
        $flags |= Qt::ItemIsEditable();
    }
    return $flags;
}
# [0]

# [1]
sub setData
{
    my ($index, $value) = @_;
    if ($index->column() < 1 || $index->column() > 2) {
        return 0;
    }

    my $primaryKeyIndex = this->SUPER::index($index->row(), 0);
    my $id = this->data($primaryKeyIndex)->toInt();

    this->clear();

    my $ok;
    if ($index->column() == 1) {
        $ok = this->setFirstName($id, $value->toString());
    } else {
        $ok = this->setLastName($id, $value->toString());
    }
    this->refresh();
    return $ok;
}
# [1]

sub refresh
{
    this->setQuery('select * from person');
    this->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('ID'))));
    this->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('First name'))));
    this->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('Last name'))));
}

# [2]
sub setFirstName
{
    my ($personId, $firstName) = @_;
    my $query = Qt::SqlQuery();
    $query->prepare('update person set firstname = ? where id = ?');
    $query->addBindValue(Qt::Variant(Qt::String($firstName)));
    $query->addBindValue(Qt::Variant(Qt::String($personId)));
    return $query->exec();
}
# [2]

sub setLastName
{
    my ($personId, $lastName) = @_;
    my $query = Qt::SqlQuery();
    $query->prepare('update person set lastname = ? where id = ?');
    $query->addBindValue(Qt::Variant(Qt::String($lastName)));
    $query->addBindValue(Qt::Variant(Qt::String($personId)));
    return $query->exec();
}

1;
