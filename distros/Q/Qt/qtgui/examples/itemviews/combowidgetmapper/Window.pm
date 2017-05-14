package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [Window definition]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    updateButtons => ['int'];

sub nameLabel() {
    return this->{nameLabel};
}

sub addressLabel() {
    return this->{addressLabel};
}

sub typeLabel() {
    return this->{typeLabel};
}

sub nameEdit() {
    return this->{nameEdit};
}

sub addressEdit() {
    return this->{addressEdit};
}

sub typeComboBox() {
    return this->{typeComboBox};
}

sub nextButton() {
    return this->{nextButton};
}

sub previousButton() {
    return this->{previousButton};
}

sub model() {
    return this->{model};
}

sub typeModel() {
    return this->{typeModel};
}

sub mapper() {
    return this->{mapper};
}
# [Window definition]

# [Set up widgets]
sub NEW
{
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setupModel();

    this->{nameLabel} = Qt::Label(this->tr('Na&me:'));
    this->{nameEdit} = Qt::LineEdit();
    this->{addressLabel} = Qt::Label(this->tr('&Address:'));
    this->{addressEdit} = Qt::TextEdit();
    this->{typeLabel} = Qt::Label(this->tr('&Type:'));
    this->{typeComboBox} = Qt::ComboBox();
    this->{nextButton} = Qt::PushButton(this->tr('&Next'));
    this->{previousButton} = Qt::PushButton(this->tr('&Previous'));

    this->nameLabel->setBuddy(this->nameEdit);
    this->addressLabel->setBuddy(this->addressEdit);
    this->typeLabel->setBuddy(this->typeComboBox);

    this->typeComboBox->setModel(this->typeModel);
# [Set up widgets]

# [Set up the mapper]
    this->{mapper} = Qt::DataWidgetMapper(this);
    this->mapper->setModel(this->model);
    this->mapper->addMapping(this->nameEdit, 0);
    this->mapper->addMapping(this->addressEdit, 1);
    this->mapper->addMapping(this->typeComboBox, 2, Qt::ByteArray('currentIndex'));
# [Set up the mapper]

# [Set up connections and layouts]
    this->connect(this->previousButton, SIGNAL 'clicked()',
            this->mapper, SLOT 'toPrevious()');
    this->connect(this->nextButton, SIGNAL 'clicked()',
            this->mapper, SLOT 'toNext()');
    this->connect(this->mapper, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'updateButtons(int)');

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->nameLabel, 0, 0, 1, 1);
    $layout->addWidget(this->nameEdit, 0, 1, 1, 1);
    $layout->addWidget(this->previousButton, 0, 2, 1, 1);
    $layout->addWidget(this->addressLabel, 1, 0, 1, 1);
    $layout->addWidget(this->addressEdit, 1, 1, 2, 1);
    $layout->addWidget(this->nextButton, 1, 2, 1, 1);
    $layout->addWidget(this->typeLabel, 3, 0, 1, 1);
    $layout->addWidget(this->typeComboBox, 3, 1, 1, 1);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Delegate Widget Mapper'));
    this->mapper->toFirst();
}
# [Set up connections and layouts]

# [Set up the model]
sub setupModel
{
    my @items = (
        this->tr('Home'),
        this->tr('Work'),
        this->tr('Other')
    );
    this->{typeModel} = Qt::StringListModel(\@items, this);
    
    this->{model} = Qt::StandardItemModel(5, 3, this);
    my @names = qw( Alice Bob Carol Donald Emma );
    my @addresses = (
        '<qt>123 Main Street<br/>Market Town</qt>',
        '<qt>PO Box 32<br/>Mail Handling Service<br/>Service City</qt>',
        '<qt>The Lighthouse<br/>Remote Island</qt>',
        '<qt>47338 Park Avenue<br/>Big City</qt>',
        '<qt>Research Station<br/>Base Camp<br/>Big Mountain</qt>'
    );

    my @types = qw( 0 1 2 0 2 );
 
    foreach my $row (0..4) {
        my $item = Qt::StandardItem($names[$row]);
        this->model->setItem($row, 0, $item);
        $item = Qt::StandardItem($addresses[$row]);
        this->model->setItem($row, 1, $item);
        $item = Qt::StandardItem($types[$row]);
        this->model->setItem($row, 2, $item);
    }
}
# [Set up the model]

# [Slot for updating the buttons]
sub updateButtons
{
    my ( $row ) = @_;
    this->previousButton->setEnabled($row > 0);
    this->nextButton->setEnabled($row < this->model->rowCount() - 1);
}
# [Slot for updating the buttons]

1;
