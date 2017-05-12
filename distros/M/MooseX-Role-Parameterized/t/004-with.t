use strict;
use warnings;
use Test::More 0.88;

do {
    package MyItem::Role::Wearable;
    use Moose::Role;

    has is_worn => (
        is => 'rw',
        isa => 'Bool',
        default => 0,
    );

    sub equip { shift->is_worn(1) }
    sub remove { shift->is_worn(0) }
};

do {
    package MyItem::Role::Equippable;
    use MooseX::Role::Parameterized;

    parameter slot => (
        isa      => 'Str',
        required => 1,
    );

    role {
        my $p = shift;

        with 'MyItem::Role::Wearable';

        method slot => sub { $p->slot };
    };
};

do {
    package MyItem::Helmet;
    use Moose;
    with 'MyItem::Role::Equippable' => {
        slot => 'head',
    };
};

do {
    package MyItem::Belt;
    use Moose;
    with 'MyItem::Role::Equippable' => {
        slot => 'waist',
    };
};

can_ok('MyItem::Helmet', qw/is_worn equip remove slot/);
can_ok('MyItem::Belt', qw/is_worn equip remove slot/);

my $visored = MyItem::Helmet->new(is_worn => 1);
ok($visored->is_worn);
is($visored->slot, 'head');

my $utility = MyItem::Belt->new;
ok(!$utility->is_worn);
is($utility->slot, 'waist');

done_testing;
