package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use ColorListEditor;

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $factory = Qt::ItemEditorFactory();

    my $colorListCreator =
        Qt::StandardItemEditorCreator();

    $factory->registerEditor(Qt::Variant::Color(), $colorListCreator);

    Qt::ItemEditorFactory::setDefaultFactory($factory);

    this->createGUI();
}
# [0]

sub createGUI
{
    my $list = [
        [this->tr('Alice'), Qt::Color('aliceblue')],
        [this->tr('Neptun'), Qt::Color('aquamarine')],
        [this->tr('Ferdinand'), Qt::Color('springgreen')]
    ];

    my $table = Qt::TableWidget(3, 2);
    $table->setHorizontalHeaderLabels([this->tr('Name'), this->tr('Hair Color')]);
    $table->verticalHeader()->setVisible(0);
    $table->resize(150, 50);

    foreach my $i (0..2) {
        my $pair = $list->[$i];

        my $nameItem = Qt::TableWidgetItem($pair->[0]);
        my $colorItem = Qt::TableWidgetItem();
        $colorItem->setData(Qt::DisplayRole(), $pair->[1]);

        $table->setItem($i, 0, $nameItem);
        $table->setItem($i, 1, $colorItem);
    }
    $table->resizeColumnToContents(0);
    $table->horizontalHeader()->setStretchLastSection(1);

    my $layout = Qt::GridLayout();
    $layout->addWidget($table, 0, 0);

    this->setLayout($layout);

    this->setWindowTitle(this->tr('Color Editor Factory'));
}

1;
