package TheParameterizedRole;
use strict;
use warnings;

use MooX::Role::Parameterized;

role {
    my $params = shift;
    my $p      = shift;

    my $attribute = $params->{attribute};
    my $method    = $params->{method};

    $p->has(
        $attribute => (
            is      => 'ro',
            default => 'this works'
        )
    );

    $p->method( $method => sub { 'dummy' } );
};

use Moo::Role;

has xoxo => ( is => 'ro' );

1;
