package ImageDelegate;

use strict;
use warnings;

use QtCore4;
use QtGui4;

# [0]
use QtCore4::isa qw( Qt::ItemDelegate );
# [0]

# [2]
use QtCore4::slots
    emitCommitData => [];
# [2]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
}
# [0]

# [1]
sub createEditor {
    my ( $parent, $option, $index ) = @_;
    my $comboBox = Qt::ComboBox($parent);
    if ($index->column() == 1) {
        $comboBox->addItem(this->tr('Normal'));
        $comboBox->addItem(this->tr('Active'));
        $comboBox->addItem(this->tr('Disabled'));
        $comboBox->addItem(this->tr('Selected'));
    } elsif ( $index->column() == 2) {
        $comboBox->addItem(this->tr('Off'));
        $comboBox->addItem(this->tr('On'));
    }

    this->connect($comboBox, SIGNAL 'activated(int)', this, SLOT 'emitCommitData()');

    return $comboBox;
}
# [1]

# [2]
sub setEditorData {
    my ( $editor, $index ) = @_;
    my $comboBox = $editor;
    if (!$comboBox) {
        return;
    }

    my $pos = $comboBox->findText($index->model()->data($index)->toString(),
                                 Qt::MatchExactly());
    $comboBox->setCurrentIndex($pos);
}
# [2]

# [3]
sub setModelData {
    my ( $editor, $model, $index ) = @_;
    my $comboBox = $editor;
    if (!$comboBox) {
        return;
    }

    $model->setData($index,
        Qt::Variant(Qt::String($comboBox->currentText())));
}
# [3]

# [4]
sub emitCommitData {
    emit this->commitData(this->sender());
}
# [4]

1;
