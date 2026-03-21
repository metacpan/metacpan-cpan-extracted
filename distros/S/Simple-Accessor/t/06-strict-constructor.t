use strict;
use warnings;

use Test::More tests => 10;
use FindBin;
use lib $FindBin::Bin . '/lib';

# --- Strict constructor class ---
{
    package StrictClass;
    use Simple::Accessor qw{name age};

    sub _strict_constructor { 1 }
    sub _build_name { 'default' }
}

# --- Non-strict class (default behavior) ---
{
    package LooseClass;
    use Simple::Accessor qw{name};
}

# --- Strict with role ---
{
    package StrictWithRole;
    use Simple::Accessor qw{size};
    with 'StrictRole';

    sub _strict_constructor { 1 }
}

# === Strict constructor: valid usage ===

my $obj = StrictClass->new(name => 'alice', age => 30);
ok $obj, 'strict constructor accepts known attributes';
is $obj->name, 'alice', 'name set correctly';
is $obj->age, 30, 'age set correctly';

# Empty constructor is fine
my $empty = StrictClass->new();
ok $empty, 'strict constructor accepts empty args';
is $empty->name, 'default', 'builder still works with strict constructor';

# === Strict constructor: rejects unknown attributes ===

eval { StrictClass->new(nmae => 'typo') };
like $@, qr/unknown attribute\(s\): nmae/,
    'strict constructor dies on typo attribute';

eval { StrictClass->new(name => 'ok', bogus => 1, fake => 2) };
like $@, qr/unknown attribute\(s\): bogus, fake/,
    'strict constructor lists all unknown attributes (sorted)';

# === Non-strict class: unknown attributes silently ignored ===

my $loose = LooseClass->new(name => 'bob', extra => 'ignored');
ok $loose, 'non-strict constructor ignores unknown attributes';
is $loose->name, 'bob', 'known attribute still set in non-strict mode';

# === Strict constructor with roles ===

eval { StrictWithRole->new(size => 'L', color => 'blue', weight => 5) };
like $@, qr/unknown attribute\(s\): weight/,
    'strict constructor recognizes role attributes as known';
