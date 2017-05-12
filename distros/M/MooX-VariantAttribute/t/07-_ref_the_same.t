use Test::More;

use Types::Standard qw/Str Object/;

{
    package One::Two::Three;

    use Moo;
    with 'MooX::VariantAttribute::Role';    
}

{
    package One::Two::Three::Four;

    use Moo;

    has single => (
        is => 'ro',
    );
}

my $obj = One::Two::Three->new;

is (&One::Two::Three::_ref_the_same('hey', 'hey'), 1, 'hey');
is (&One::Two::Three::_ref_the_same('hy', 'hey'), undef, 'hy not hey');

is (&One::Two::Three::_struct_the_same(1, 1), 1, 'test 1');
is (&One::Two::Three::_struct_the_same(1, 0), undef, '1 not 0');

my $hash = { one => 'two', three => 'four' };
is (&One::Two::Three::_ref_the_same($hash, $hash), 1, 'match hash');
is (&One::Two::Three::_ref_the_same({ one => 'two', three => 'four' }, { one => 'two', three => 'four' }), undef, 'fail hash');
is (&One::Two::Three::_ref_the_same({ one => 'two', thee => 'four' }, { one => 'two', three => 'four' }), undef, 'fail hash');

my $array = [qw/one two three/];
is (&One::Two::Three::_ref_the_same($array, $array), 1, 'match array');
is (&One::Two::Three::_ref_the_same([qw/one two three/], [qw/one two three/]), undef, 'fail array');
is (&One::Two::Three::_ref_the_same([qw/one two thee/], [qw/one two three/]), undef, 'fail array');

my $obj1 = One::Two::Three::Four->new( single => 'Hey' );

is (&One::Two::Three::_ref_the_same($obj1, $obj1), 1, 'the same object ref');

my $obj2 = One::Two::Three::Four->new( single => 'Hey' );

is (&One::Two::Three::_ref_the_same($obj1, $obj2), undef, 'fail object ref');

my $obj3 = One::Two::Three::Four->new( single => 'Heya' );

is (&One::Two::Three::_ref_the_same($obj1, $obj3), undef, 'not the same object ref');

done_testing();
