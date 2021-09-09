package My::Class::Single::Piddle;

use Moo;
use MooX::PDL::Role::Proxy;

has p1 => (
    is      => 'rwp',
    piddle  => 1,
    trigger => sub { $_[0]->triggered( 1 ) },
);

has p2 => (
    is      => 'rwp',
    piddle => 1,
    trigger => sub { $_[0]->triggered( 1 ) },
);

sub clone_with_piddles {
    my ( $self, %attr ) = @_;
    $self->new->_set_attr( %attr );
}

with 'My::Class::Single';

1;
