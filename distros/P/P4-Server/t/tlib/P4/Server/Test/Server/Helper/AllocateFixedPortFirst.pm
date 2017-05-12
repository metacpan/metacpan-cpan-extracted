package P4::Server::Test::Server::Helper::AllocateFixedPortFirst;

use base qw( P4::Server );

use Class::Std;

{

my %fixed_port_of   : ATTR( init_arg => 'fixed_port' );

sub _allocate_port : RESTRICTED {
    my ($self) = @_;

    if( ! defined( $self->get_port() ) ) {
        $self->set_port( $fixed_port_of{ident $self} );
    }
    else {
        $self->SUPER::_allocate_port();
    }

    return;
}

}

1;
