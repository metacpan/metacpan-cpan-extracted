use strict;
use warnings;

use Test::More;

{

    package Foo;
    use Mouse;

    our $Triggered = 0;

    has hash => (
        traits  => ['Hash'],
        is      => 'rw',
        isa     => 'HashRef',
        handles => {
            delete_key => 'delete',
            set_key    => 'set',
        },
        clearer => 'clear_key',
        trigger => sub { $Triggered++ },
    );
}

my $foo = Foo->new;

{
    $foo->hash( { x => 1, y => 2 } );

    is_deeply(
        $Foo::Triggered,
        1,
        'trigger was called for normal writer'
    );

    $foo->set_key( z => 5 );

    is_deeply(
        $Foo::Triggered,
        2,
        'trigger was called on set'
    );

    $foo->delete_key('y');

    is_deeply(
        $Foo::Triggered,
        3,
        'trigger was called on delete'
    );
}

done_testing;
