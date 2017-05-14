package CalculatorForm;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

# [0]
use Ui_CalculatorForm;
# [0]

# [1]
use QtCore4::slots
    on_inputSpinBox1_valueChanged => ['int'],
    on_inputSpinBox2_valueChanged => ['int'];

# [1]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW($parent);
    this->{ui} = Ui_CalculatorForm->setupUi(this);
}
# [0]

# [1]
sub on_inputSpinBox1_valueChanged {
    my ( $value ) = @_;
    this->{ui}->outputWidget()->setText( $value + this->{ui}->inputSpinBox2->value() );
}
# [1]

# [2]
sub on_inputSpinBox2_valueChanged {
    my ( $value ) = @_;
    this->{ui}->outputWidget()->setText( $value + this->{ui}->inputSpinBox1->value() );
}
# [2]

1;
