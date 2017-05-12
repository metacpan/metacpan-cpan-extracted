package Example::Usage::ArraySet;

use Minions::Implementation
    has => { set => { default => sub { [] } } },
;

sub has {
    my ($self, $e) = @_;
    scalar grep { $_ == $e } @{ $self->{$SET} };
}

sub add {
    my ($self, $e) = @_;

    if ( ! $self->has($e) ) {
        push @{ $self->{$SET} }, $e;
    }
}

1;
