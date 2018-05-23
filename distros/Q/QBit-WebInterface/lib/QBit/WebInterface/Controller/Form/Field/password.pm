package QBit::WebInterface::Controller::Form::Field::password;
$QBit::WebInterface::Controller::Form::Field::password::VERSION = '0.031';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field::input);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'input_type'} = 'password';
}

TRUE;
