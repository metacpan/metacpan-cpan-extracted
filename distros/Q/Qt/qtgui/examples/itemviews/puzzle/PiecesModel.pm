package PiecesModel;

use strict;
use warnings;
use List::Util qw( min max );
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::AbstractListModel );

use constant { RAND_MAX => 2147483647 };

sub locations() {
    return this->{locations};
}

sub pixmaps() {
    return this->{pixmaps};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW( $parent );

    this->{locations} = [];
    this->{pixmaps} = [];
}

sub data
{
    my ($index, $role) = @_;
    if (!$index->isValid()) {
        return Qt::Variant();
    }

    if ($role == Qt::DecorationRole()) {
        return Qt::qVariantFromValue(Qt::Icon(this->pixmaps->[$index->row()]->scaled(60, 60,
                         Qt::KeepAspectRatio(), Qt::SmoothTransformation())));
    }
    elsif ($role == Qt::UserRole()) {
        return Qt::qVariantFromValue(this->pixmaps->[$index->row()]);
    }
    elsif ($role == Qt::UserRole() + 1) {
        return Qt::Variant(this->locations->[$index->row()]);
    }

    return Qt::Variant();
}

sub addPiece
{
    my ($pixmap, $location) = @_;
    my $row;
    if (int(2.0*rand(RAND_MAX)/(RAND_MAX+1.0)) == 1) {
        $row = 0;
    }
    else {
        $row = scalar @{this->pixmaps};
    }

    this->beginInsertRows(Qt::ModelIndex(), $row, $row);
    splice @{this->pixmaps}, $row, 0, $pixmap;
    splice @{this->locations}, $row, 0, $location;
    this->endInsertRows();
}

sub flags
{
    my ($index) = @_;
    if ($index->isValid()) {
        return (Qt::ItemIsEnabled() | Qt::ItemIsSelectable() | Qt::ItemIsDragEnabled());
    }

    return Qt::ItemIsDropEnabled();
}

sub removeRows
{
    my ($row, $count, $parent) = @_;
    if ($parent->isValid()) {
        return 0;
    }

    if ($row >= scalar @{this->pixmaps} || $row + $count <= 0) {
        return 0;
    }

    my $beginRow = max(0, $row);
    my $endRow = min($row + $count - 1, scalar @{this->pixmaps} - 1);

    this->beginRemoveRows($parent, $beginRow, $endRow);

    while ($beginRow <= $endRow) {
        splice @{this->pixmaps}, $beginRow, 1;
        splice @{this->locations}, $beginRow, 1;
        ++$beginRow;
    }

    this->endRemoveRows();
    return 1;
}

sub mimeTypes
{
    return [ 'image/x-puzzle-piece' ];
}

sub mimeData
{
    my ($indexes) = @_;
    my $mimeData = Qt::MimeData();
    my $encodedData = Qt::ByteArray();

    my $stream = Qt::DataStream($encodedData, Qt::IODevice::WriteOnly());

    foreach my $index ( @{$indexes} ) {
        if ($index->isValid()) {
            my $pixmap = Qt::qVariantValue( this->data($index, Qt::UserRole()), 'Qt::Pixmap' );
            my $location = this->data($index, Qt::UserRole()+1)->toPoint();
            no warnings qw(void); # Ignore bitshift warning
            $stream << $pixmap << $location;
            use warnings;
        }
    }

    $mimeData->setData('image/x-puzzle-piece', $encodedData);
    return $mimeData;
}

sub dropMimeData
{
    my ($data, $action, $row, $column, $parent) = @_;
    if (!$data->hasFormat('image/x-puzzle-piece')) {
        return 0;
    }

    if ($action == Qt::IgnoreAction()) {
        return 1;
    }

    if ($column > 0) {
        return 0;
    }

    my $endRow;

    if (!$parent->isValid()) {
        if ($row < 0) {
            $endRow = scalar @{this->pixmaps};
        }
        else {
            $endRow = min($row, scalar @{this->pixmaps});
        }
    } else {
        $endRow = $parent->row();
    }

    my $encodedData = $data->data('image/x-puzzle-piece');
    my $stream = Qt::DataStream($encodedData, Qt::IODevice::ReadOnly());

    while (!$stream->atEnd()) {
        my $pixmap = Qt::Pixmap();
        my $location = Qt::Point();
        no warnings qw(void); # Ignore bitshift warning
        $stream >> $pixmap >> $location;
        use warnings;

        this->beginInsertRows(Qt::ModelIndex(), $endRow, $endRow);
        splice @{this->pixmaps}, $endRow, 0, $pixmap;
        splice @{this->locations}, $endRow, 0, $location;
        this->endInsertRows();

        ++$endRow;
    }

    return 1;
}

sub rowCount
{
    my ($parent) = @_;
    if ($parent->isValid()) {
        return 0;
    }
    else {
        return scalar @{this->pixmaps};
    }
}

sub supportedDropActions
{
    return Qt::CopyAction() | Qt::MoveAction();
}

sub addPieces
{
    my ($pixmap) = @_;
    this->beginRemoveRows(Qt::ModelIndex(), 0, 24);
    this->{pixmaps} = [];
    this->{locations} = [];
    this->endRemoveRows();
    foreach my $y (0..4) {
        foreach my $x (0..4) {
            my $pieceImage = $pixmap->copy($x*80, $y*80, 80, 80);
            this->addPiece($pieceImage, Qt::Point($x, $y));
        }
    }
}

1;
