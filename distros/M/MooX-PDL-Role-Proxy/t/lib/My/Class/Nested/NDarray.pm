package My::Class::Nested::NDarray;

use Module::Load 'load';

use Moo;
use MooX::PDL::Role::Proxy;
use PDL::Lite ();

sub test_class { 'My::Class::Single::NDarray' }

has c1 => ( is => 'rwp', ndarray => 1 );
has c2 => ( is => 'rwp', ndarray => 1 );

with 'My::Class::Nested';

sub _clone_with_ndarrays {
    my ( $self, $attr, $arg ) = @_;
    $self->new->_set_attr( %$attr );
}

1;
