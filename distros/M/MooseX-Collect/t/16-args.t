use strict;
use warnings;

use Test::More tests => 1;

{
    package Foo;
    use Moose;
    use MooseX::Collect;
    use t::classes;
    
    collect 'multiply';
    
    extends 'E';
    with qw(B C);
}

is_deeply(
    [ Foo->new->multiply(10, 20) ],
    [qw(30 60 20 40)],
    'args'
);
