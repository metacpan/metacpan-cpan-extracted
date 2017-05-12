package Role1;

use Test::Able::Role;
use Test::More;

with qw( Role2 );

setup plan => 2, role1_setup_1 => sub {
    my ( $self, ) = @_;

    ok( 1, $self->meta->current_method->name ) for 1 .. 2;
};

test role1_test_1 => sub {};

1;
