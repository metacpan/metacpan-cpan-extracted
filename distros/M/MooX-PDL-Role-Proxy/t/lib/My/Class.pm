package My::Class;

use Moo;
use MooX::PDL::Role::Proxy;
use PDL::Lite ();


has p1 => (
    is      => 'rwp',
    default => sub { PDL->null },
    piddle  => 1,
);

has p2 => (
    is      => 'rwp',
    default => sub { PDL->null },
    piddle  => 1,
);

sub clone_with_piddles {

    my ( $self, %attr ) = @_;

    $self->new->_set_attr( %attr );
}


1;
