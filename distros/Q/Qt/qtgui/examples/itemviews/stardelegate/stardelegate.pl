#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use StarDelegate;
use StarEditor;
use StarRating;

# [0]
sub populateTableWidget
{
    my ($tableWidget) = @_;

    my @staticData = (
        { 
            title => 'Mass in B-Minor',
            genre => 'Baroque',
            artist => 'J.S. Bach',
            rating => 5
        },
        { 
            title => 'Three More Foxes',
            genre => 'Jazz',
            artist => 'Maynard Ferguson',
            rating => 4
        },
        { 
            title => 'Sex Bomb',
            genre => 'Pop',
            artist => 'Tom Jones',
            rating => 3
        },
        { 
            title => 'Barbie Girl',
            genre => 'Pop',
            artist => 'Aqua',
            rating => 5
        },
    );

    foreach my $rowIndex ( 0..$#staticData ) {
        my $row = $staticData[$rowIndex];
        my $item0 = Qt::TableWidgetItem($row->{title});
        my $item1 = Qt::TableWidgetItem($row->{genre});
        my $item2 = Qt::TableWidgetItem($row->{artist});
        my $item3 = Qt::TableWidgetItem();
        $item3->setData(0,
                       Qt::qVariantFromValue(StarRating->new($row->{rating})));

        $tableWidget->setItem($rowIndex, 0, $item0);
        $tableWidget->setItem($rowIndex, 1, $item1);
        $tableWidget->setItem($rowIndex, 2, $item2);
        $tableWidget->setItem($rowIndex, 3, $item3);
    }
}
# [4]

# [5]
sub main
{
    my $app = Qt::Application(\@ARGV);

    my $tableWidget = Qt::TableWidget(4, 4);
    $tableWidget->setItemDelegate(StarDelegate($tableWidget));
    $tableWidget->setEditTriggers(Qt::AbstractItemView::DoubleClicked()
                                | Qt::AbstractItemView::SelectedClicked());
    $tableWidget->setSelectionBehavior(Qt::AbstractItemView::SelectRows());

    my @headerLabels = qw( Title Genre Artist Rating );
    $tableWidget->setHorizontalHeaderLabels(\@headerLabels);

    populateTableWidget($tableWidget);

    $tableWidget->resizeColumnsToContents();
    $tableWidget->resize(500, 300);
    $tableWidget->show();

    return $app->exec();
}
# [5]

exit main();
