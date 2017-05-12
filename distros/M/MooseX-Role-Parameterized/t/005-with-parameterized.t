use strict;
use warnings;
use Test::More 0.88;

do {
    package MyItem::Role::Wearable;
    use MooseX::Role::Parameterized;

    parameter is_worn_default => (
        is      => 'rw',
        isa     => 'Bool',
        default => 1,
    );

    role {
        my $p = shift;
        has is_worn => (
            is      => 'rw',
            isa     => 'Bool',
            default => $p->is_worn_default,
        );

        method equip => sub { shift->is_worn(1) };
        method remove => sub { shift->is_worn(0) };
    };
};

do {
    package MyItem::Role::Equippable;
    use MooseX::Role::Parameterized;

    parameter slot => (
        isa      => 'Str',
        required => 1,
    );

    # XXX: UGH! We need some way of making this work I think..
    parameter is_worn_default => (
        is      => 'rw',
        isa     => 'Bool',
        default => 1,
    );

    role {
        my $p = shift;

        with 'MyItem::Role::Wearable' => {
            is_worn_default => $p->is_worn_default,
        };

        method slot => sub { $p->slot };
    };
};

do {
    package MyItem::Helmet;
    use Moose;
    with 'MyItem::Role::Equippable' => {
        slot            => 'head',
        is_worn_default => 0,
    };
};

do {
    package MyItem::Belt;
    use Moose;
    with 'MyItem::Role::Equippable' => {
        slot            => 'waist',
        is_worn_default => 1,
    };
};

can_ok('MyItem::Helmet', qw/is_worn equip remove slot/);
can_ok('MyItem::Belt', qw/is_worn equip remove slot/);

my $feathered = MyItem::Helmet->new;
ok(!$feathered->is_worn, "default for helmet is not worn");
is($feathered->slot, 'head');

my $chastity = MyItem::Belt->new;
ok($chastity->is_worn, "default for belt is worn");
is($chastity->slot, 'waist');

done_testing;
