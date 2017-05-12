package Example::Roles::Acme::Stack_v1;

use Minions::Implementation
    has  => {
        items => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$ITEMS} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$ITEMS} }, $val;
}

sub pop {
    my ($self) = @_;

    pop @{ $self->{$ITEMS} };
}

1;
