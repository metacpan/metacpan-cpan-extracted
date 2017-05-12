package TestWebInterface::Controller::Test;

use qbit;

use base qw(QBit::WebInterface::Controller);

sub cmd1 : CMD {
    my ($self) = @_;

    return $self->from_template('cmd1.tt2', vars => {text => 'Test text: Q-Bit'});
}

sub formcmd1 : FORMCMD {
    return (
        title  => 'Test form 1',
        fields => [{name => 'testinput', type => 'input', value => 'i1'}, {type => 'submit', value => 'Submit'}]
      );
}

TRUE;
