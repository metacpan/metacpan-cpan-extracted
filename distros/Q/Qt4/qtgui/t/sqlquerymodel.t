#!/usr/bin/perl

package SqlQueryModelHelp;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw( QVERIFY );
use EditableSqlModel;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    testEditability => [],
    initTestCase => [];
use Test::More;
use lib '../';
use Connection;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub testEditability {
    my $model = this->{model};
    my $view = this->{view};

    foreach my $index ( $model->index( 1, 1 ), $model->index( 1, 2 ) ) {
        my $text;
        my $curText;
        my $col = $index->column();
        if ( $col == 1 ) {
            $curText = 'Christine';
            $text = 'Larry';
        }
        else {
            $curText = 'Holand';
            $text = 'Wall';
        }

        is( $model->data( $index, Qt::DisplayRole() )->value(), $curText );
        my $itemRect = $view->visualRect( $index );
        Qt::Test::mouseClick( $view->viewport(), Qt::LeftButton(), Qt::NoModifier(), $itemRect->center() );
        Qt::Test::mouseDClick( $view->viewport(), Qt::LeftButton(), Qt::NoModifier(), $itemRect->center() );
        my $delegate = ($view->findChildren( 'Qt::LineEdit' ))[0]->[0];
        Qt::Test::keyClicks( $delegate, $text );
        Qt::Test::qWait(100);
        Qt::Test::keyClick( $delegate, Qt::Key_Enter() );
        Qt::Test::qWait(100);

        is( $model->data( $index, Qt::DisplayRole() )->value(), $text );
    }
}

sub initializeModel
{
    my ($model) = @_;
    $model->setQuery('select * from person');
    $model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('ID'))));
    $model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('First name'))));
    $model->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('Last name'))));
}

sub initTestCase {
    Connection::createConnection();
    
    my $editableModel = EditableSqlModel();
    initializeModel($editableModel);

    my $view = Qt::TableView();
    $view->setModel($editableModel);
    $view->setWindowTitle( Qt::Object::tr('Editable Query Model') );
    $view->show();
    
    Qt::Test::qWaitForWindowShown( $view );
    Qt::Test::qWait(100);
    this->{model} = $editableModel;
    this->{view} = $view;
    pass( 'Window shown' );
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw(QTEST_MAIN);
use Test::More tests => 5;
use SqlQueryModelHelp;

exit QTEST_MAIN('SqlQueryModelHelp');
