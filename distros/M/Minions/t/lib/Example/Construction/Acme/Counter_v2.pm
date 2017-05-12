package Example::Construction::Acme::Counter_v2;

use Minions::Implementation
    has  => {
        count => { },
    }, 
;

sub BUILD {
    my (undef, $self, $arg) = @_;

    $self->{$COUNT} = $arg->{start};
}

sub next {
    my ($self) = @_;

    $self->{$COUNT}++;
}

1;
