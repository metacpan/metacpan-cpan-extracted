package Bar;

use Moo::Role;
use MooX::Role::Parameterized;

role {
    my ( $params, $mop ) = @_;

    $mop->has( $params->{attr} => ( is => 'rw' ) );

    $mop->method(
        $params->{method} => sub {
            1024;
        }
    );
};

has bar => ( is => 'ro' );

1;
