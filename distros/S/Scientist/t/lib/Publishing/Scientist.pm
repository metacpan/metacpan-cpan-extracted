package Publishing::Scientist;

use parent 'Scientist';

sub publish {
    my $self = shift;
    die $self->result->{experiment};
}

1;
