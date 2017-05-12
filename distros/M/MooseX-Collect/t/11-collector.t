use strict;
use warnings;

use Test::More tests => 1;

{
    package Foo;
    use Moose;
    use MooseX::Collect;
    use t::classes;
    
    sub items () { qw/me/ }
    
    collect 'items' => sub {
        my $self = shift;
        return (@_, reverse @_);
    };
    
    extends 'E';
    with qw(B C);
}

is_deeply(
    [ Foo->new->items ],
    [qw(me e d b a a2 c c a2 a b d e me)],
    'custom collector'
);
