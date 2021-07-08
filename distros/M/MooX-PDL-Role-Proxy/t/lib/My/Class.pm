package My::Class;

use Moo;
use MooX::PDL::Role::Proxy;
use PDL::Lite ();

use overload '""'     => 'to_string';
use overload fallback => 1;

sub to_string {
    return join( "\n", "p1 = " . $_[0]->p1, "p2 = " . $_[0]->p2, );
}

has p1 => (
    is      => 'rwp',
    default => sub { PDL->null },
    piddle  => 1,
    trigger => sub { $_[0]->triggered(1) },
);

has p2 => (
    is      => 'rwp',
    default => sub { PDL->null },
    piddle  => 1,
);

has triggered => (
    is      => 'rw',
    clearer => 1,
    default => 0,
);

sub clone_with_piddles {

    my ( $self, %attr ) = @_;

    $self->new->_set_attr( %attr );
}

1;
