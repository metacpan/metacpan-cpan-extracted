package TWebInterface::Controller::TestController;

use qbit;

use base qw(QBit::WebInterface::Controller);

sub test_cmd : CMD : SAFE : DEFAULT {
    my ($self, %opts) = @_;

    $self->as_json(\%opts);
}

TRUE;
