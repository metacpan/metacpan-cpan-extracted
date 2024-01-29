package CompleteExample;

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

    $mop->with( $params->{with} );

    $mop->requires( $params->{requires} );

    if ( $params->{after} ) {
        $mop->after( @{ $params->{after} } );
    }

    if ( $params->{before} ) {
        $mop->before( @{ $params->{before} } );
    }

    if ( $params->{around} ) {
        $mop->around( @{ $params->{around} } );
    }
};


1;
