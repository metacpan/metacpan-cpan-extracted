use strict;
use warnings;
use Test::More;
use MooX::Purple;
use MooX::Purple::G -lib => 't/lib';

class Foo {
    attributes( foo => [ 'ro', {} ], );
}

my $o1 = Foo->new;
my $o2 = Foo->new;
$o1->foo->{foo} = 219;
is $o2->foo->{foo}, undef;

my $o3 = Foo->new({ foo => { a => 'b' }});

done_testing;
