package Example::Delegates::Acme::Queue_v1;

use Minions::Implementation
    has  => {
        q => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$Q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$Q} }, $val;
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$Q} };
}

1;
