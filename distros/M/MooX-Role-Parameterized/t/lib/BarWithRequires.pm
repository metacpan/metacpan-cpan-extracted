package BarWithRequires;

use MooX::Role::Parameterized;

role {
    my ( $params, $p ) = @_;

    $p->has( $params->{attr} => ( is => 'rw' ) );

    $p->method(
        $params->{method} => sub {
            1024;
        }
    );

    $p->requires( $params->{requires} );
};

use Moo::Role;
has bar => ( is => 'ro' );

1;
