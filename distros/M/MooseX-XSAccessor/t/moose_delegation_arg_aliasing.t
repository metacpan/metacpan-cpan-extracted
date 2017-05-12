use lib "t/lib";
use lib "moose/lib";
use lib "lib";

## skip Test::Tabs
use strict;
use warnings;
use Test::More;

{
    package Foo;
    use MyMoose;

    sub aliased {
        my $self = shift;
        $_[1] = $_[0];
    }
}

{
    package HasFoo;
    use MyMoose;

    has foo => (
        is  => 'ro',
        isa => 'Foo',
        handles => {
            foo_aliased => 'aliased',
            foo_aliased_curried => ['aliased', 'bar'],
        }
    );
}

my $hasfoo = HasFoo->new(foo => Foo->new);
my $x;
$hasfoo->foo->aliased('foo', $x);
is($x, 'foo', "direct aliasing works");
undef $x;
$hasfoo->foo_aliased('foo', $x);
is($x, 'foo', "delegated aliasing works");
undef $x;
$hasfoo->foo_aliased_curried($x);
is($x, 'bar', "delegated aliasing with currying works");

done_testing;
