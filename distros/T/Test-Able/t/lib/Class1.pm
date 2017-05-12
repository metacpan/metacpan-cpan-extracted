package Class1;

use Test::Able;
use Test::More;

with qw( Role1 );

startup plan => 5, class1_startup_1 => sub {
    my ( $self, ) = @_;

    ok( 1, $self->meta->current_method->name ) for 1 .. 5;
};

test class1_test_1 => sub {};

shutdown class1_shutdown_1 => sub {};

1;
