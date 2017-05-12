use strict;
use warnings;

use Test::More;

{
    package Foo;
    use Mouse;

    our $Triggered = 0;

    has array => (
        traits  => ['Array'],
        is      => 'rw',
        isa     => 'ArrayRef',
        handles => {
            push_array => 'push',
            set_array  => 'set',
        },
        clearer => 'clear_array',
        trigger => sub { $Triggered++ },
    );
}

my $foo = Foo->new;

{
    $foo->array( [ 1, 2, 3 ] );

    is_deeply(
        $Foo::Triggered,
        1,
        'trigger was called for normal writer'
    );

    $foo->push_array(5);

    is_deeply(
        $Foo::Triggered,
        2,
        'trigger was called on push'
    );

    $foo->set_array( 1, 42 );

    is_deeply(
        $Foo::Triggered,
        3,
        'trigger was called on set'
    );
}

done_testing;
