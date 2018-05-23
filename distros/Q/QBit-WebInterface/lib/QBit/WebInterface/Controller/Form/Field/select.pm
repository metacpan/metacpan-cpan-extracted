package QBit::WebInterface::Controller::Form::Field::select;
$QBit::WebInterface::Controller::Form::Field::select::VERSION = '0.031';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field);

sub control_html {
    my ($self) = @_;

    my $html = '<select';
    $html .= $self->_class('span9');
    foreach (qw(id name style)) {
        $html .= " $_=\"" . html_encode($self->{$_}) . '"' if defined($self->{$_});
    }
    $html .= '>';

    $html .= '<option></option>' if $self->{'add_empty'};

    foreach my $option (@{$self->{'options'} || []}) {
        $html .= '<option value="' . html_encode($option->{$self->{'items_key'}}) . '"';
        $html .= ' selected="selected"'
          if defined($self->{'value'})
              && defined($option->{$self->{'items_key'}})
              && $self->{'value'} eq $option->{$self->{'items_key'}};
        $html .= '>' . html_encode($option->{$self->{'items_label'}}) . '</option>';
    }


    $html .= '</select>';

    $html .= $self->_html_error();

    return $html;
}

TRUE;
