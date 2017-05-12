package FixedSizeQueueImpl;

use Minions::Implementation
    has  => {
        q => { default => sub { [ ] } },
        max_size => { 
            init_arg => 'max_size',
            reader => 1,
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
}

1;
