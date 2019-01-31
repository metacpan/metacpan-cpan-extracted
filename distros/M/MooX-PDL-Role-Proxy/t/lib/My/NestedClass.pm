package My::NestedClass;

use My::Class;

use Moo;
use MooX::PDL::Role::Proxy;
use PDL::Lite ();


has c1 => (
    is      => 'rwp',
    default => sub { My::Class->new },
    piddle  => 1,
);

has c2 => (
    is      => 'rwp',
    default => sub { My::Class->new },
    piddle  => 1,
);

sub clone_with_piddles {

    my ( $self, %attr ) = @_;

    $self->new->_set_attr( %attr );
}


1;
