package Bar;

use Moo::Role;
use MooX::Role::Parameterized;

role {
    my ( $params, $p ) = @_;

    $p->has( $params->{attr} => ( is => 'rw' ) );

    $p->method(
        $params->{method} => sub {
            1024;
        }
    );
};

has bar => ( is => 'ro' );

1;
