use strictures 1;
use Test::More;

{
    package MyTestRole;
    use Moo::Role;
    use MooX::Aliases;

    has foo => (
        is      => 'rw',
        alias   => 'bar',
    );

    has baz => (
        is      => 'rw',
        init_arg => undef,
        alias   => [qw/quux quuux/],
    );
}

{
    package MyTest;
    use Moo;
    with 'MyTestRole';
}

my $test1 = MyTest->new(foo => 'foo', baz => 'baz');
is($test1->foo, 'foo', 'Attribute set with default init_arg');
is($test1->baz, undef, 'Attribute set with default init_arg (undef)');

$test1->baz('baz');
is($test1->baz, 'baz',
    'Attribute set with default writer, read with default reader');
is($test1->quux, 'baz',
    'Attribute set with default writer, read with aliased reader');

$test1->quux('quux');
is($test1->baz, 'quux', 'Attribute set with aliased writer');
is($test1->quux, 'quux', 'Attribute set with aliased writer');

my $test2 = MyTest->new(bar => 'foo', baz => 'baz');
is($test2->foo, 'foo', 'Attribute set wtih aliased init_arg');
is($test2->baz, undef, 'Attribute set with default init_arg (undef)');

$test2->baz('baz');
is($test2->baz, 'baz',
    'Attribute set with default writer, read with default reader');
is($test2->quux, 'baz',
    'Attribute set with default writer, read with aliased reader');

$test2->quux('quux');
is($test2->baz, 'quux', 'Attribute set with aliased writer');
is($test2->quux, 'quux', 'Attribute set with aliased writer');

done_testing;
