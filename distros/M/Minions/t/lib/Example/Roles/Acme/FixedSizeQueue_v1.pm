package Example::Roles::Acme::FixedSizeQueue_v1;

use Minions::Implementation
    has  => {
        q => { default => sub { [ ] } },

        max_size => { 
            init_arg => 'max_size',
        },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$Q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$Q} }, $val;

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$Q} };
}

1;
