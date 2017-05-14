#!/usr/bin/perl

package TestModel;

use strict;
use warnings;
use blib;
use QtCore4;
use QtCore4::isa qw( Qt::AbstractItemModel );

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);

    this->{rootIndex} = Qt::ModelIndex();
    this->{data} = [
        [ qw( PerlQt is Awesome ) ],
        [ qw( The quick brown ) ],
        [ qw( jumped over the ) ],
        [ qw( lazy dog and ) ],
        [ qw( then ate lunch ) ]
    ];
}

1;

package main;

use strict;
use warnings;
no warnings 'once';
use blib;
use QtCore4;
use TestModel;
use Test::More tests=>15;

my $model;
my $unimplementedPureVirtualErr = 'Unimplemented pure virtual method called';

# Pure virutal methods
sub testColumnCount {
    my $columnCount = eval{ $model->columnCount() };
    like( $@, qr/$unimplementedPureVirtualErr/, 'columnCount() unimplemented' );
    *TestModel::columnCount = sub {
        my ($parent) = @_;
        return 5;
    };
    $columnCount = $model->columnCount();
    is( $columnCount, 5, 'columnCount()' );
}

sub testData {
    my $index = $model->index( 0, 0, Qt::ModelIndex() );
    my $data = eval{ $model->data( $index, Qt::DisplayRole() ) };
    like( $@, qr/$unimplementedPureVirtualErr/, 'data() unimplemented' );
    *TestModel::data = sub {
        my ( $index, $role ) = @_;

        if ( $role == Qt::DisplayRole() ) {
            my $data = Qt::this()->{data};
            return Qt::Variant( Qt::String( $data->[$index->row()]->[$index->column()] ) );
        }

        return Qt::Variant();
    };
    $data = $model->data( $index, Qt::DisplayRole() );
    is( $data->toString(), $model->{data}->[0]->[0], 'data()' );
}

sub testIndex {
    my $index = eval{ $model->index(0, 0, Qt::ModelIndex()) };
    like( $@, qr/$unimplementedPureVirtualErr/, 'index() unimplemented' );
    *TestModel::index = sub {
        my ( $row, $column, $parent ) = @_;

        if ( !$parent->isValid() ) {
            $parent = Qt::this()->{rootIndex};
        }
        return Qt::this()->createIndex( $row, $column, $parent );
    };
    $index = $model->index(0, 0, Qt::ModelIndex());
    ok( $index->parent() == $model->{rootIndex}, 'index()' );
}

sub testParent {
    my $parent = eval{ $model->parent(Qt::ModelIndex()) };
    like( $@, qr/$unimplementedPureVirtualErr/, 'parent() unimplemented' );
    *TestModel::parent = sub {
        my ( $index ) = @_;

        if ( !$index->isValid() ) {
            return Qt::this()->{rootIndex};
        }
        return $index->internalPointer();
    };
    $parent = $model->parent(Qt::ModelIndex());
    is( $parent, $model->{rootIndex}, 'rootIndex()' );
}

sub testRowCount {
    my $rowCount = eval{ $model->rowCount() };
    like( $@, qr/Unimplemented pure virtual method called/, 'rowCount() unimplemented' );
    *TestModel::rowCount = sub {
        my ($parent) = @_;
        if ($parent->isValid()) {
            return 0;
        }
        return 3;
    };
    $rowCount = $model->rowCount(Qt::ModelIndex());
    is( $rowCount, 3, 'rowCount()' );
    $rowCount = $model->rowCount($model->index(0, 0, Qt::ModelIndex));
    is( $rowCount, 0, 'rowCount()' );
}

#-------------------------------------------------------------------------------

sub testBuddy {
    my $index = $model->index( 0, 0, Qt::ModelIndex() );
    ok( $model->buddy($index) == $index, 'Inherited buddy()' );
    *TestModel::buddy = sub {
        package TestModel;
        my ($index) = @_;
        return Qt::this()->SUPER::buddy($index);
    };
    ok( $model->buddy($index) == $index, 'buddy()' );
}

sub testFlags {
    my $index = $model->index( 0, 0, Qt::ModelIndex() );
    my $defaultFlags = Qt::ItemIsEnabled() | Qt::ItemIsSelectable();
    ok( $model->flags($index) == $defaultFlags, 'Inherited flags()' );
    *TestModel::flags = sub {
        package TestModel;
        my ($index) = @_;
        return Qt::this()->SUPER::flags($index);
    };
    ok( $model->flags($index) == $defaultFlags, 'flags()' );
}

sub main {
    my $app = Qt::CoreApplication( \@ARGV );

    $model = TestModel();
    # Pure virtual methods
    testParent();
    testIndex();
    testColumnCount();
    testRowCount();
    testData();

    testBuddy();
    testFlags();

    return 0;
}

exit main();
