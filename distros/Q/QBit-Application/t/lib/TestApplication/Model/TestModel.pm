package TestApplication::Model::TestModel;

use qbit;

use base qw(QBit::Application::Model);

sub method {
    my ($self) = @_;

    return 12345;
}

TRUE;
