package Role2;

use Test::Able::Role;
use Test::More;

test plan => 1, role2_test_1 => sub {
    my ( $self, ) = @_;

    ok( 1, $self->meta->current_method->name );
};

teardown role2_teardown_1 => sub {};

1;
