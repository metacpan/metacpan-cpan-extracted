use strict;
use warnings;

use Test::More tests => 1;

{
    package Bar;
    use Moose::Role;
    use MooseX::Collect;
    
    collect 'get_items' => (
        provider => 'items',
    );
}

{
    package Foo;
    use Moose;
    use t::classes;
    
    sub items { qw/me/ }
    
    extends 'E';
    with qw(B C Bar);
}

is_deeply(
    [ Foo->new->get_items ],
    [qw(me e d b a a2 c)],
    'collector defined in role'
);
