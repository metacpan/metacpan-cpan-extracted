package QBit::WebInterface::Controller::Form::Field::submit;
$QBit::WebInterface::Controller::Form::Field::submit::VERSION = '0.033';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field::button);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'type'} = 'submit';
}

TRUE;
