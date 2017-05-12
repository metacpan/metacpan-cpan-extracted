use strict;
use warnings;

use Test::More tests => 4;

{
    package Foo;
    use Moose;
    use MooseX::Collect;
    use t::classes;
    
    sub items { qw/me/ }
    
    collect 'get_items' => (
        provider => 'items',
    );
    
    collect 'get_items_roles' => (
        from => 'roles',
        provider => 'items',
    );
    
    collect 'get_items_self' => (
        from => 'self',
        provider => 'items',
    );
    
    collect 'get_items_superclasses' => (
        from => 'superclasses',
        provider => 'items',
    );
    
    extends 'E';
}

{
    package Bar;
    use Moose;
    extends 'Foo';
    
    sub items { qw/sub1 sub2/ }
    
    with qw(B C);
}

my $Bar = Bar->new;

is_deeply(
    [ $Bar->get_items ],
    [qw(sub1 sub2 me e d b a a2 c)],
    'subclassed collector'
);

is_deeply(
    [ $Bar->get_items_roles ],
    [qw(b a a2 c)],
    'subclassed collector'
);

is_deeply(
    [ $Bar->get_items_self ],
    [qw(sub1 sub2)],
    'subclassed collector'
);

is_deeply(
    [ $Bar->get_items_superclasses ],
    [qw(me e d)],
    'subclassed collector'
);
