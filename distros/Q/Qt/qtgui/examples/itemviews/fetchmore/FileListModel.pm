package FileListModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
#[0]
use QtCore4::isa qw( Qt::AbstractListModel );
use QtCore4::signals
    numberPopulated => ['int'];
use List::Util qw(min);

use QtCore4::slots
    setDirPath => ['const QString &'];

    #Qt::StringList fileList;
    #int fileCount;
#[0]

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
}

#[4]
sub rowCount
{
    return this->{fileCount};
}

sub data
{
    my ($index, $role) = @_;
    if (!$index->isValid()) {
        return Qt::Variant();
    }
    
    if ($index->row() >= scalar @{this->{fileList}} || $index->row() < 0) {
        return Qt::Variant();
    }
    
    if ($role == Qt::DisplayRole()) {
        return Qt::Variant(this->{fileList}->[$index->row()]);
    }
    elsif ($role == Qt::BackgroundRole()) {
        my $batch = ($index->row() / 100) % 2;
        if ($batch == 0) {
            return Qt::qVariantFromValue(qApp->palette()->base());
        }
        else {
            return Qt::qVariantFromValue(qApp->palette()->alternateBase());
        }
    }
    return Qt::Variant();
}
#[4]

#[1]
sub canFetchMore
{
    if (this->{fileCount} < scalar @{this->{fileList}}) {
        return 1;
    }
    else {
        return 0;
    }
}
#[1]

#[2]
sub fetchMore
{
    my $remainder = scalar @{this->{fileList}} - this->{fileCount};
    my $itemsToFetch = min(100, $remainder);

    this->beginInsertRows(Qt::ModelIndex(), this->{fileCount}, this->{fileCount}+$itemsToFetch);
    
    this->{fileCount} += $itemsToFetch;

    this->endInsertRows();

    emit this->numberPopulated($itemsToFetch);
}
#[2]

#[0]
sub setDirPath
{
    my ($path) = @_;
    my $dir = Qt::Dir($path);

    this->{fileList} = $dir->entryList();
    this->{fileCount} = 0;
    this->reset();
}
#[0]

1;
