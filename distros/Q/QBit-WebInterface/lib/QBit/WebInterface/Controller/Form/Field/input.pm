package QBit::WebInterface::Controller::Form::Field::input;
$QBit::WebInterface::Controller::Form::Field::input::VERSION = '0.029';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field);

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'input_type'} = 'text' unless defined($self->{'type'});
}

sub control_html {
    my ($self) = @_;

    my $html = '<input type="' . html_encode($self->{'input_type'}) . '"';
    $html .= $self->_class('span9');

    foreach (qw(id name style maxlength)) {
        $html .= " $_=\"" . html_encode($self->{$_}) . '"' if defined($self->{$_});
    }

    $html .= ' value="' . html_encode($self->value) . '"' if defined($self->value);

    $html .= ' checked="checked"' if $self->{'checked'};

    $html .=
      ' placeholder="'
      . html_encode(ref($self->{'placeholder'}) eq 'CODE' ? $self->{'placeholder'}() : $self->{'placeholder'}) . '"'
      if defined($self->{'placeholder'});

    $html .= ' />';

    $html .= $self->_html_error();

    return $html;
}

TRUE;
