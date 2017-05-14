package StarDelegate;

use strict;
use warnings;
use QtCore4;
use QtGui4;

# [0]
use QtCore4::isa qw( Qt::StyledItemDelegate );
use QtCore4::slots
    commitAndCloseEditor => [];
# [0]

use StarDelegate;
use StarEditor;
use StarRating;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
}

# [0]
sub paint
{
    my ($painter, $option, $index) = @_;
    my $starRating = $index->data()->value();
    if ( ref $starRating eq 'StarRating') {

        if (${$option->state() & Qt::Style::State_Selected()}) {
            $painter->fillRect($option->rect(), $option->palette()->highlight());
        }

        $starRating->paint($painter, $option->rect(), $option->palette(),
                         StarRating::ReadOnly);
    } else {
        this->SUPER::paint($painter, $option, $index);
    }
# [0]
}

# [1]
sub sizeHint
{
    my ($option, $index) = @_;
    my $starRating = $index->data()->value();
    if ( ref $starRating eq 'StarRating') {
        return $starRating->sizeHint();
    } else {
        return this->SUPER::sizeHint($option, $index);
    }
}
# [1]

# [2]
sub createEditor
{
    my ($parent, $option, $index) = @_;
    my $starRating = $index->data()->value();
    if ( ref $starRating eq 'StarRating') {
        my $editor = StarEditor($parent);
        this->connect($editor, SIGNAL 'editingFinished()',
                this, SLOT 'commitAndCloseEditor()');
        return $editor;
    } else {
        return this->SUPER::createEditor($parent, $option, $index);
    }
}
# [2]

# [3]
sub setEditorData
{
    my ($editor, $index) = @_;
    my $starRating = $index->data()->value();
    if ( ref $starRating eq 'StarRating') {
        my $starEditor = $editor;
        $starEditor->setStarRating($starRating);
    } else {
        this->SUPER::setEditorData($editor, $index);
    }
}
# [3]

# [4]
sub setModelData
{
    my ($editor, $model, $index) = @_;
    my $starRating = $index->data()->value();
    if ( ref $starRating eq 'StarRating') {
        my $starEditor = $editor;
        $model->setData($index, Qt::qVariantFromValue($starEditor->starRating()));
    } else {
        this->SUPER::setModelData($editor, $model, $index);
    }
}
# [4]

# [5]
sub commitAndCloseEditor
{
    my $editor = this->sender();
    emit this->commitData($editor);
    emit this->closeEditor($editor);
}
# [5]

1;
