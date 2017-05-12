use strict;
use warnings;

use Test::More;
use Test::Deep;

# blech! but Test::Requires does a stringy eval, so this works...
use Test::Requires { 'MooseX::Types' => '()' };

{
    package MyTypes;
    use strict;
    use warnings;
    use MooseX::Types -declare => [ qw(MyNum MaybeMyNum) ];
    use MooseX::Types::Moose 'Num';
    subtype MyNum, as Num;
    subtype MaybeMyNum, as maybe_type(MyNum);
}

{
    package MyClass;
    use Moose;
    use MooseX::Storage;

    with Storage;

    has 'mynum'  => ( is => 'ro', isa => MyTypes::MyNum );
    has 'maybe_mynum'  => ( is => 'ro', isa => MyTypes::MaybeMyNum );
}

my $obj = MyClass->new(
    mynum => 10,
    maybe_mynum => 20,
);

my $packed = $obj->pack;

cmp_deeply(
    $packed,
    {
        __CLASS__ => 'MyClass',
        mynum => 10,
        maybe_mynum => 20,
    },
    'correctly serialized a MooseX::Type attribute using Maybe',
);

my $unpacked = MyClass->unpack($packed);

cmp_deeply(
    $unpacked,
    all(
        isa('MyClass'),
        noclass({
            mynum => 10,
            maybe_mynum => 20,
        }),
    ),
    'correctly deserialized data from a MooseX::Type attribute using Maybe',
);

done_testing;
