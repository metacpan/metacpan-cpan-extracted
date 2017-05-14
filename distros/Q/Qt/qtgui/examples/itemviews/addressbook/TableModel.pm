package TableModel;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw(Qt::AbstractTableModel);

Qt::_internal::installsignal( 'Qt::AbstractTableModel::dataChanged' );

sub NEW {
    my ( $class, $pairs, $parent ) = @_;
    my $listOfPairs;
    if ( ref $pairs eq 'ARRAY' && defined $parent ) {
        $listOfPairs = $pairs;
    }
    else {
        $listOfPairs = [];
        $parent = $pairs;
    }

    $class->SUPER::NEW( $parent );
    this->{listOfPairs} = $listOfPairs;
}

sub rowCount {
    return scalar @{this->{listOfPairs}};
}

sub columnCount {
    return 2;
}

sub data {
    my ($index, $role) = @_;
    my $listOfPairs = this->{listOfPairs};
    if (!$index->isValid()) {
        return Qt::Variant();
    }
    
    if ($index->row() >= scalar @{$listOfPairs} || $index->row() < 0) {
        return Qt::Variant();
    }
    
    if ($role == Qt::DisplayRole()) {
        my $pair = $listOfPairs->[$index->row()];
        
        if ($index->column() == 0) {
            return $pair->[0] ? Qt::Variant($pair->[0]) : Qt::Variant();
        }
        elsif ($index->column() == 1) {
            return $pair->[1] ? Qt::Variant($pair->[1]) : Qt::Variant();
        }
    }
    return Qt::Variant();
}

sub headerData {
    my ($section, $orientation, $role) = @_;
    if ($role != Qt::DisplayRole()) {
        return Qt::Variant();
    }
    
    if ($orientation == Qt::Horizontal()) {
        if ($section == 0) {
            return Qt::Variant(Qt::String(this->tr("Name")));
        }
        elsif ($section == 1) {
            return Qt::Variant(Qt::String(this->tr("Address")));
        }
        else {
            return Qt::Variant();
        }
    }
    return Qt::Variant();
}

sub insertRows {
    my ($position, $rows, $index) = @_;
    my $listOfPairs = this->{listOfPairs};
    this->beginInsertRows(Qt::ModelIndex(), $position, $position+$rows-1);
    
    foreach my $row (0..$rows-1) {
        if( $position == 0 ) {
            unshift @{$listOfPairs}, [ ' ', ' ' ];
        }
        elsif( $position == scalar @{$listOfPairs} ) {
            push @{$listOfPairs}, [ ' ', ' ' ];
        }
        else {
            #$listOfPairs->[$position] = [ ' ', ' ' ];
        }
    }

    this->endInsertRows();
    return 1;
}

sub removeRows {
    my ($position, $rows, $index) = @_;
    my $listOfPairs = this->{listOfPairs};
    this->beginRemoveRows(Qt::ModelIndex(), $position, $position+$rows-1);

    foreach my $row (0..$rows-1) {
        splice( @{$listOfPairs}, $position, 1 );
    }

    this->endRemoveRows();
    return 1;
}

sub setData {
    my ($index, $value, $role) = @_;
    my $listOfPairs = this->{listOfPairs};
    if ($index->isValid() && $role == Qt::EditRole()) {
        my $row = $index->row();

        my $p = $listOfPairs->[$row];

        if ($index->column() == 0) {
            $p->[0] = $value;
        }
        elsif ($index->column() == 1) {
            $p->[1] = $value;
        }
        else {
            return 0;
        }

        $listOfPairs->[$row] = $p;
        #Qt::_internal::setDebug(0xffffff);
        emit dataChanged($index, $index);
        #Qt::_internal::setDebug(0);

        return 1;
    }

    return 0;
}

sub flags {
    my ($index) = @_;
    if (!$index->isValid()) {
        return Qt::ItemIsEnabled();
    }

    return bless( \this->SUPER::flags($index), 'Qt::ItemFlag') | Qt::ItemIsEditable();
}

sub getList {
    return this->{listOfPairs};
}

1;
