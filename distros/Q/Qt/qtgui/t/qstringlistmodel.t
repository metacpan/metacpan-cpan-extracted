#!/usr/bin/perl

package TestModel;

use strict;
use warnings;
use blib;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::StringListModel );

sub NEW {
    my ($class, $parent) = @_;

    my $data = [
        qw( PerlQt is Awesome ),
        qw( The quick brown ),
        qw( jumped over the ),
        qw( lazy dog and ),
        qw( then ate lunch ),
    ];

    $class->SUPER::NEW($data, $parent);

    this->{data} = $data;
}

sub data {
    return this->SUPER::data(@_);
}


1;

package main;

use strict;
use warnings;
no warnings 'once';
use blib;
use QtCore4;
use TestModel;
use Test::More tests=>4;

my $model;
my $unimplementedPureVirtualErr = 'Unimplemented pure virtual method called';

# Pure virutal methods

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
    my $defaultFlags = Qt::ItemIsSelectable() | Qt::ItemIsEditable() | Qt::ItemIsDragEnabled() | Qt::ItemIsDropEnabled() | Qt::ItemIsEnabled();
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

    testBuddy();
    testFlags();

    return 0;
}

exit main();
