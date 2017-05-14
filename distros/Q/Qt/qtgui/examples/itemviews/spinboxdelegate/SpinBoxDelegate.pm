package SpinBoxDelegate;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::ItemDelegate );

# [0]
sub NEW {
    shift->SUPER::NEW();
}
# [0]

# [1]
sub createEditor {
    my ( $parent, $option, $index ) = @_;
    my $editor = Qt::SpinBox($parent);
    $editor->setMinimum(0);
    $editor->setMaximum(100);

    return $editor;
}
# [1]

# [2]
sub setEditorData {
    my ($editor, $index) = @_;
    my $value = $index->model()->data($index, Qt::EditRole())->toInt();

    my $spinBox = $editor;
    $spinBox->setValue($value);
}
# [2]

# [3]
sub setModelData {
    my ($editor, $model, $index) = @_;
    my $spinBox = $editor;
    $spinBox->interpretText();
    my $value = Qt::Variant($spinBox->value());

    $model->setData($index, $value, Qt::EditRole());
}
# [3]

# [4]
sub updateEditorGeometry {
    my ($editor, $option, $index) = @_;
    $editor->setGeometry($option->rect);
}
# [4]

1;
