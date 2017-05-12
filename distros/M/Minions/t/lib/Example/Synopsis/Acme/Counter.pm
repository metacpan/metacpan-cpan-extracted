package Example::Synopsis::Acme::Counter;

use Minions::Implementation
    has => {
        count => { default => 0 },
    } 
;

sub next {
    my ($self) = @_;

    $self->{$COUNT}++;
}

1;
