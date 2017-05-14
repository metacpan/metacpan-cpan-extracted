package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    updateButtons => ['int'];

sub nameLabel() {
    return this->{nameLabel};
}

sub setNameLabel($) {
    return this->{nameLabel} = shift;
}

sub addressLabel() {
    return this->{addressLabel};
}

sub setAddressLabel($) {
    return this->{addressLabel} = shift;
}

sub ageLabel() {
    return this->{ageLabel};
}

sub setAgeLabel($) {
    return this->{ageLabel} = shift;
}

sub nameEdit() {
    return this->{nameEdit};
}

sub setNameEdit($) {
    return this->{nameEdit} = shift;
}

sub addressEdit() {
    return this->{addressEdit};
}

sub setAddressEdit($) {
    return this->{addressEdit} = shift;
}

sub ageSpinBox() {
    return this->{ageSpinBox};
}

sub setAgeSpinBox($) {
    return this->{ageSpinBox} = shift;
}

sub nextButton() {
    return this->{nextButton};
}

sub setNextButton($) {
    return this->{nextButton} = shift;
}

sub previousButton() {
    return this->{previousButton};
}

sub setPreviousButton($) {
    return this->{previousButton} = shift;
}

sub model() {
    return this->{model};
}

sub setModel($) {
    return this->{model} = shift;
}

sub mapper() {
    return this->{mapper};
}

sub setMapper($) {
    return this->{mapper} = shift;
}

sub NEW
{
    my ( $class, $package ) = @_;
    $class->SUPER::NEW( $package );
    this->setupModel();

    this->setNameLabel( Qt::Label(this->tr('Na&me:')) );
    this->setNameEdit( Qt::LineEdit() );
    this->setAddressLabel( Qt::Label(this->tr('&Address:')) );
    this->setAddressEdit( Qt::TextEdit() );
    this->setAgeLabel( Qt::Label(this->tr('A&ge (in years):')) );
    this->setAgeSpinBox( Qt::SpinBox() );
    this->setNextButton( Qt::PushButton(this->tr('&Next')) );
    this->setPreviousButton( Qt::PushButton(this->tr('&Previous')) );

    this->nameLabel->setBuddy(this->nameEdit);
    this->addressLabel->setBuddy(this->addressEdit);
    this->ageLabel->setBuddy(this->ageSpinBox);

    this->setMapper( Qt::DataWidgetMapper(this) );
    this->mapper->setModel(this->model);
    this->mapper->addMapping(this->nameEdit, 0);
    this->mapper->addMapping(this->addressEdit, 1);
    this->mapper->addMapping(this->ageSpinBox, 2);

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
    $layout->addWidget(this->ageLabel, 3, 0, 1, 1);
    $layout->addWidget(this->ageSpinBox, 3, 1, 1, 1);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Simple Widget Mapper'));
    this->mapper->toFirst();
}

sub setupModel
{
    this->setModel( Qt::StandardItemModel(5, 3, this) );

    my @names = qw( Alice Bob Carol Donald Emma );

    my @addresses = (
        '<qt>123 Main Street<br/>Market Town</qt>',
        '<qt>PO Box 32<br/>Mail Handling Service<br/>Service City</qt>',
        '<qt>The Lighthouse<br/>Remote Island</qt>',
        '<qt>47338 Park Avenue<br/>Big City</qt>',
        '<qt>Research Station<br/>Base Camp<br/>Big Mountain</qt>'
    );

    my @ages = qw( 20 31 32 19 26 );
    
    foreach my $row (0..4) {
      my $item = Qt::StandardItem(Qt::String($names[$row]));
      this->model->setItem($row, 0, $item);
      $item = Qt::StandardItem(Qt::String($addresses[$row]));
      this->model->setItem($row, 1, $item);
      $item = Qt::StandardItem(Qt::String($ages[$row]));
      this->model->setItem($row, 2, $item);
    }
}

sub updateButtons
{
    my ($row) = @_;
    this->previousButton->setEnabled($row > 0);
    this->nextButton->setEnabled($row < this->model->rowCount() - 1);
}

1;
