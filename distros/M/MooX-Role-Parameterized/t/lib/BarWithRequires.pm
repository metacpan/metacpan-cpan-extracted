package BarWithRequires;

use MooX::Role::Parameterized;

role {
    my ( $params, $mop ) = @_;

    $mop->has( $params->{attr} => ( is => 'rw' ) );

    $mop->method(
        $params->{method} => sub {
            1024;
        }
    );

    $mop->requires( $params->{requires} );
};

use Moo::Role;
has bar => ( is => 'ro' );

1;
