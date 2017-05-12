package QBit::WebInterface::Controller::Form::Field::email;
$QBit::WebInterface::Controller::Form::Field::email::VERSION = '0.029';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field::input);

use Exception::Form;

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    push_hs(
        $self,
        {
            input_type  => 'text',
            trim        => TRUE,
            placeholder => 'name@example.com'
        }
    );
}

sub check {
    my ($self) = @_;

    $self->SUPER::check();

    throw Exception::Form gettext('Invalid E-Mail') unless check_email($self->value);

    return TRUE;
}

TRUE;
