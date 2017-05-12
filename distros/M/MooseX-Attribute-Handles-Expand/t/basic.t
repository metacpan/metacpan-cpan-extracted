use strict;
use warnings;

use Test::More tests => 3;

{
    package Foo;
    use Moose;
    use MooseX::Attribute::Handles::Expand;

    my $i = 1;

    has [ qw/ bar baz / ] => (
        traits => [ 'Array', 'Handles::Expand' ],
        default => sub { [ (1) x 5 ] },
        handles => {
            'size_*' => 'count',
        },
    );

    has quux => (
        traits => [ 'Handles::Expand', 'Bool' ],
        default => sub { 0 },
        handles => {
            'un*' => 'not',
        },
    );
}

my $foo = Foo->new;

is $foo->size_bar => 5;
is $foo->size_baz => 5;

ok $foo->unquux, "quux"



