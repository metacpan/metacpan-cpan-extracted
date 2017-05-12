use strictures 1;
use Test::More;

{
    package MyTest;
    use Moo;
    use MooX::Aliases;

    has foo => (
        is    => 'ro',
        alias => ['bar'],
    );

    has baz => (
        is => 'rw',
        init_arg => undef,
        alias    => ['quux'],
    );

    package MyTest::Sub;
    use Moo;
    use MooX::Aliases;

    extends qw(MyTest);
    has '+foo' => (
        is      => 'rw',
        alias   => 'override',
    );
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

my $test3 = MyTest::Sub->new(override => 'over');
is($test3->override, 'over', 'Overriden attribute set with aliased writer');

done_testing;
