package My::Class::Single::NDarray;

use Moo;
use MooX::PDL::Role::Proxy;

has p1 => (
    is      => 'rwp',
    trigger => sub { $_[0]->triggered( 1 ) },
    ndarray => 1,
);

has p2 => (
    is      => 'rwp',
    trigger => sub { $_[0]->triggered( 1 ) },
    ndarray => 1,
);

sub _clone_with_ndarrays {
    my ( $self, $attr, $args ) = @_;
    $args //= {};
    $self->new( $args )->_set_attr( %$attr );
}

with 'My::Class::Single';

1;
