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
        from => [qw(self superclasses)],
    );
    
    extends 'E';
    with qw(B C);
}

is_deeply(
    [ Foo->new->items ],
    [qw(me e d)],
    'self'
);
