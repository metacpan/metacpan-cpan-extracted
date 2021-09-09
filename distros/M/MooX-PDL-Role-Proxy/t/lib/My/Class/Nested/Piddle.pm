package My::Class::Nested::Piddle;

use Module::Load 'load';

use Moo;
use MooX::PDL::Role::Proxy;
use PDL::Lite ();

use My::Class;
sub test_class { 'My::Class::Single::Piddle' }

has c1 => ( is => 'rwp', piddle => 1 );
has c2 => ( is => 'rwp', piddle => 1 );

with "My::Class::Nested";

sub clone_with_piddles {
    my ( $self, %attr ) = @_;
    $self->new->_set_attr( %attr );
}

1;
