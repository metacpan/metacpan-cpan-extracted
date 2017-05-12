use strict;
use warnings;

use Test::More tests => 1;

{
    package Foo;
    use Moose;
    use MooseX::Collect;
    use t::classes;
    
    collect 'items';
    
    extends 'E';
    with qw(B C);
}

is_deeply(
    [ Foo->new->items ],
    [qw(e d b a a2 c)],
    'simple syntax'
);
