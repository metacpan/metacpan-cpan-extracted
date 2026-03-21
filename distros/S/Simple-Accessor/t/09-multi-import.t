use strict;
use warnings;

use Test::More tests => 14;

# === Multiple `use Simple::Accessor` in the same package ===

# Test: attributes from both imports are usable as accessors
# and the constructor initializes all of them.

{
    package MultiImport;
    use Simple::Accessor qw{name email};
    use Simple::Accessor qw{role status};
}

# All four accessors should work
my $obj = MultiImport->new(
    name   => 'alice',
    email  => 'alice@example.com',
    role   => 'admin',
    status => 'active',
);

ok $obj, 'object created with attributes from both imports';
is $obj->name,   'alice',             'name from first import';
is $obj->email,  'alice@example.com', 'email from first import';
is $obj->role,   'admin',             'role from second import';
is $obj->status, 'active',            'status from second import';

# Setters should work for all attributes
$obj->name('bob');
is $obj->name, 'bob', 'setter works for first-import attribute';
$obj->role('viewer');
is $obj->role, 'viewer', 'setter works for second-import attribute';

# === Constructor partial initialization ===

my $partial = MultiImport->new(name => 'carol', status => 'pending');
is $partial->name,   'carol',   'first-import attr set via constructor';
is $partial->status, 'pending', 'second-import attr set via constructor';
is $partial->email,  undef,     'unset first-import attr is undef';
is $partial->role,   undef,     'unset second-import attr is undef';

# === Deterministic init order across imports ===

{
    package OrderedMulti;
    use Simple::Accessor qw{alpha beta};
    use Simple::Accessor qw{gamma delta};

    my @order;
    sub _before_alpha { push @order, 'alpha'; 1 }
    sub _before_beta  { push @order, 'beta';  1 }
    sub _before_gamma { push @order, 'gamma'; 1 }
    sub _before_delta { push @order, 'delta'; 1 }

    sub get_order { [@order] }
    sub reset_order { @order = () }
}

OrderedMulti->reset_order();
OrderedMulti->new(delta => 4, alpha => 1, gamma => 3, beta => 2);
is_deeply( OrderedMulti->get_order(),
    [qw{alpha beta gamma delta}],
    'init order follows declaration order across both imports' );

# === Strict constructor with multi-import ===

{
    package StrictMulti;
    use Simple::Accessor qw{x y};
    use Simple::Accessor qw{z};

    sub _strict_constructor { 1 }
}

my $sm = StrictMulti->new(x => 1, y => 2, z => 3);
ok $sm, 'strict constructor accepts all multi-import attributes';

eval { StrictMulti->new(x => 1, w => 99) };
like $@, qr/unknown attribute.*w/,
    'strict constructor rejects unknown attrs with multi-import';
