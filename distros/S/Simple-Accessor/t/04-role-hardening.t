use strict;
use warnings;

use Test::More tests => 10;
use FindBin;

use lib $FindBin::Bin. '/lib';

# --- Test: with() on a non-SA module gives clear error ---
{
    package NotARole;
    sub some_method { 42 }
    $INC{"NotARole.pm"} = 1;

    package WithNonSA;
    use Simple::Accessor qw{name};

    package main;

    eval { WithNonSA::with("NotARole") };
    like $@, qr/is not a Simple::Accessor role/,
        'with() on a non-SA module gives clear error message';
}

# --- Test: duplicate role application is idempotent ---
{
    package DupRole;
    use Simple::Accessor qw{color};
    sub _build_color { 'blue' }
    $INC{"DupRole.pm"} = 1;

    package DupConsumer;
    use Simple::Accessor qw{name};

    package main;

    eval { DupConsumer::with("DupRole") };
    is $@, '', 'first role application succeeds';

    eval { DupConsumer::with("DupRole") };
    is $@, '', 'second role application is silently ignored (idempotent)';

    my $o = DupConsumer->new(name => 'test');
    is $o->name, 'test', 'own attributes work after duplicate role';
    is $o->color, 'blue', 'role attributes work after duplicate role';
}

# --- Test: duplicate attribute at declaration time still dies ---
{
    eval q{
        package DupAttr;
        use Simple::Accessor qw{foo foo};
    };
    like $@, qr/attribute 'foo' is already defined/,
        'declaring the same attribute twice still dies';
}

# --- Test: two roles with overlapping attributes, second role's attr is skipped ---
{
    package RoleA;
    use Simple::Accessor qw{shared_attr};
    sub _build_shared_attr { 'from_A' }
    $INC{"RoleA.pm"} = 1;

    package RoleB;
    use Simple::Accessor qw{shared_attr};
    sub _build_shared_attr { 'from_B' }
    $INC{"RoleB.pm"} = 1;

    package OverlapConsumer;
    use Simple::Accessor qw{name};

    package main;

    eval {
        OverlapConsumer::with("RoleA");
        OverlapConsumer::with("RoleB");
    };
    is $@, '', 'two roles with overlapping attributes do not crash';

    my $o = OverlapConsumer->new();
    is $o->shared_attr, 'from_A', 'first role wins for overlapping attributes';
}

# --- Test: role with no attributes applied cleanly ---
{
    package EmptyRole;
    use Simple::Accessor;  # no attributes
    $INC{"EmptyRole.pm"} = 1;

    package EmptyConsumer;
    use Simple::Accessor qw{val};

    package main;

    eval { EmptyConsumer::with("EmptyRole") };
    is $@, '', 'role with no attributes is applied without error';

    my $o = EmptyConsumer->new(val => 99);
    is $o->val, 99, 'own attributes work after empty role composition';
}
