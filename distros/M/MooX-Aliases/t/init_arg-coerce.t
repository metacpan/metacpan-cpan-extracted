use strictures 1;
use Test::More;

{
    package MyTest;
    use Moo;
    use MooX::Aliases;

    has foo => (
        is     => 'ro',
        isa    => sub { $_[0] >= 0 },
        alias  => ['bar'],
        coerce => sub { abs $_[0] },
    );

    has baz => (
        is       => 'rw',
        isa      => sub { $_[0] >= 0 },
        init_arg => undef,
        alias    => ['quux'],
        coerce   => sub { abs $_[0] },
    );
}

my $test1 = MyTest->new(foo => -1, baz => -3);
is($test1->foo, 1, 'Attribute set with default init_arg');
is($test1->baz, undef, 'Attribute set with default init_arg (undef)');

$test1->baz(-3);
is($test1->baz, 3,
    'Attribute set with default writer, read with default reader');
is($test1->quux, 3,
    'Attribute set with default writer, read with aliased reader');

$test1->quux(4);
is($test1->baz, 4, 'Attribute set with aliased writer');
is($test1->quux, 4, 'Attribute set with aliased writer');

my $test2 = MyTest->new(bar => -1, baz => -3);
is($test2->foo, 1, 'Attribute set wtih aliased init_arg');
is($test2->baz, undef, 'Attribute set with default init_arg (undef)');

$test2->baz(-3);
is($test2->baz, 3,
    'Attribute set with default writer, read with default reader');
is($test2->quux, 3,
    'Attribute set with default writer, read with aliased reader');

$test2->quux(-4);
is($test2->baz, 4, 'Attribute set with aliased writer');
is($test2->quux, 4, 'Attribute set with aliased writer');

done_testing;
