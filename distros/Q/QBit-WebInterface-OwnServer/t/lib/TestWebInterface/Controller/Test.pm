package TestWebInterface::Controller::Test;

use qbit;

use base qw(QBit::WebInterface::Controller);

sub test : CMD : DEFAULT {
    my ($self) = @_;

    return $self->from_template(\'[% WRAPPER page %]Hello world[% END %]');
}

TRUE;
