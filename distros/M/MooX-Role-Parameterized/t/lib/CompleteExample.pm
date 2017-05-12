package CompleteExample;

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

    $p->with( $params->{with} );

    $p->requires( $params->{requires} );

    if ( $params->{after} ) {
        $p->after( @{ $params->{after} } );
    }

    if ( $params->{before} ) {
        $p->before( @{ $params->{before} } );
    }

    if ( $params->{around} ) {
        $p->around( @{ $params->{around} } );
    }
};

1;
