package TheParameterizedRole;
use strict;
use warnings;

use MooX::Role::Parameterized;

role {
    my ( $params, $mop ) = @_;

    my $attribute = $params->{attribute};
    my $method    = $params->{method};

    $mop->has(
        $attribute => (
            is      => 'ro',
            default => 'this works'
        )
    );

    $mop->method( $method => sub {'dummy'} );
};

use Moo::Role;

has xoxo => ( is => 'ro' );

1;
