use strict;
use warnings;

use Test::More tests => 10;

# --- Inline role: defined in the same file, no .pm file ---
{
    package InlineRole;
    use Simple::Accessor qw{color};

    sub _build_color { 'red' }
    # Note: NO $INC{"InlineRole.pm"} = 1 hack needed
}

# --- Consumer of inline role ---
{
    package InlineConsumer;
    use Simple::Accessor qw{name};

    # This should work without requiring InlineRole.pm to exist on disk
    eval { with('InlineRole') };
    ::is $@, '', 'with() accepts inline-defined SA role (no $INC hack needed)';
}

# === Inline role attributes work ===

my $obj = InlineConsumer->new(name => 'test', color => 'blue');
ok $obj, 'constructor works with inline role attributes';
is $obj->name, 'test', 'own attribute set correctly';
is $obj->color, 'blue', 'inline role attribute set via constructor';

# === Inline role builder works ===

my $obj2 = InlineConsumer->new(name => 'default');
is $obj2->color, 'red', 'inline role builder fires correctly';

# === File-based roles still work (regression check) ===
{
    package FileRoleConsumer;
    use Simple::Accessor qw{size};

    use FindBin;
    use lib $FindBin::Bin . '/lib';

    with 'StrictRole';  # file-based role from t/lib/
}

my $fr = FileRoleConsumer->new(size => 'L', color => 'green');
ok $fr, 'file-based role still works';
is $fr->size, 'L', 'own attribute works with file-based role';
is $fr->color, 'green', 'file-based role attribute works';

# === Non-SA inline package still rejected ===
{
    package NotSARole;
    sub helper { 42 }
    $INC{"NotSARole.pm"} = 1;  # fake require so we test the SA role check
}

eval {
    package RejectConsumer;
    use Simple::Accessor qw{val};
    with('NotSARole');
};
like $@, qr/is not a Simple::Accessor role/,
    'non-SA inline package (with $INC hack) is still rejected';

# === Unknown module still fails with require error ===
{
    eval {
        package UnknownConsumer;
        use Simple::Accessor qw{val};
        with('This::Module::Does::Not::Exist');
    };
    like $@, qr/Can't locate/,
        'unknown module still fails with require error';
}
