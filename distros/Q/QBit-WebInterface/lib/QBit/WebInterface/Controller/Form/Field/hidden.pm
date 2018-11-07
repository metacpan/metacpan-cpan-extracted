package QBit::WebInterface::Controller::Form::Field::hidden;
$QBit::WebInterface::Controller::Form::Field::hidden::VERSION = '0.033';
use qbit;

use base qw(QBit::WebInterface::Controller::Form::Field);

sub is_hidden {1}

sub clean {
    my ($self, $value) = @_;

    if ($self->{'inttype'}) {
        $value = int($value);
        $value = abs($value) if $self->{'unsigned'};
    }

    return $value;
}

sub as_html {
    my ($self) = @_;

    my $input_html = '<input type="hidden"';
    foreach (qw(id name)) {
        $input_html .= " $_=\"" . html_encode($self->{$_}) . '"' if exists($self->{$_});
    }

    $input_html .= ' value="' . html_encode($self->{'value'}) . '"';

    $input_html .= ' />';

    return $input_html;
}

TRUE;
