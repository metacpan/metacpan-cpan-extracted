package Tester::Moo;
use Moo;

has hashref => (
    is      => 'rw',
    default => sub { return { key => 'value' } },
);

has string => (
    is      => 'rw',
    default => sub {'string'},
);

sub change_hashref {
    my ( $self, $key, $val ) = @_;

    $self->hashref->{$key} = $val;
}

1;
