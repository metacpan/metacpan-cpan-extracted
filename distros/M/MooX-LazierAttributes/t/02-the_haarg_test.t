use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
	    require Moo;
        1;
    } or do {
        plan skip_all => "Cannot require Moo";
    };
}

{
    package Foo;
    use Moo;
    use MooX::LazierAttributes;
    attributes( foo => [ 'ro', {} ], );
}
my $o1 = Foo->new;
my $o2 = Foo->new;
$o1->foo->{foo} = 219;
is $o2->foo->{foo}, undef;

my $o3 = Foo->new({ foo => { a => 'b' }});

done_testing;
