use strict;
use warnings;

use Test::More tests => 1;

{
    package Foo;
    use Moose;
    use MooseX::Collect;
    use t::classes;
    
    sub items { qw/me/ }
    
    collect 'itemz' => (
        provider => 'items',
        from => 'roles',
        method_order => 'reverse',
    );
    
    extends 'E';
    with qw(B C);
}

is_deeply(
    [ Foo->new->itemz ],
    [qw(c a a2 b)],
    'provider and reverse'
);
