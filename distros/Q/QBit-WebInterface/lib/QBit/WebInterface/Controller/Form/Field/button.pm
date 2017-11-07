package QBit::WebInterface::Controller::Form::Field::button;
$QBit::WebInterface::Controller::Form::Field::button::VERSION = '0.030';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field);

sub control_html {
    my ($self) = @_;

    my $html = '<button class="btn';
    $html .= ' btn-' . $self->{'info_type'} if defined($self->{'info_type'});
    $html .= ' btn-' . $self->{'size'} if defined($self->{'size'});
    $html .= ' disabled' if $self->{'disabled'};
    $html .= ' ' . $self->{'class'} if defined($self->{'class'});
    $html .= '"';

    $html .= ' type="' . (defined($self->{'type'}) ? $self->{'type'} : 'button') . '"';

    $html .= '>' . html_encode(ref($self->value) eq "CODE" ? $self->value->() : $self->value) . '</button>';

    return $html;
}

TRUE;
