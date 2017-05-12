use strict;
use warnings;

use Test::More tests => 1;

{
    package Foo;
    use Moose;
    use MooseX::Collect;
    use t::classes;
    
    sub items { qw/me/ }
    
    collect 'items' => (
        from => 'roles',
    );
    
    extends 'E';
}

{
    package Bar;
    use Moose;
    extends 'Foo';
    with qw(B C);
}

is_deeply(
    [ Bar->new->items ],
    [qw(b a a2 c)],
    'subclassed collector'
);
