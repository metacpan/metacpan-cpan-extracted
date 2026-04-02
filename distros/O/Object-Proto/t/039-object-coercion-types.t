use strict;
use warnings;
use Test::More tests => 12;

# Test type coercion, undef at construction for Str, type edge cases

BEGIN {
    require Object::Proto;

    # Register a coercion type
    Object::Proto::register_type('TrimmedStr',
        sub { defined $_[0] && !ref $_[0] },   # check
        sub { my $v = $_[0]; $v =~ s/^\s+|\s+$//g; $v }  # coerce
    );

    Object::Proto::define('CoerceTest', 'bio:TrimmedStr');
    Object::Proto::define('StrTest', 'name:Str', 'label:Str');
}

use Object::Proto;

# --- Coercion tests ---

my $ct = new CoerceTest bio => '  padded  ';
is($ct->bio, 'padded', 'coercion trims whitespace on construction');

# Let's test via setter
$ct->bio('  hello world  ');
is($ct->bio, 'hello world', 'coercion trims whitespace on setter');

$ct->bio('no_padding');
is($ct->bio, 'no_padding', 'coercion leaves clean string alone');

$ct->bio('   ');
is($ct->bio, '', 'coercion trims to empty string');

# --- Str rejects undef at construction ---

eval { new StrTest name => undef, label => 'ok' };
like($@, qr/Type constraint failed.*name.*Str/i, 'Str rejects undef at construction');

# --- Str rejects reference at construction ---

eval { new StrTest name => [1,2,3], label => 'ok' };
like($@, qr/Type constraint failed.*name.*Str/i, 'Str rejects arrayref at construction');

eval { new StrTest name => {a => 1}, label => 'ok' };
like($@, qr/Type constraint failed.*name.*Str/i, 'Str rejects hashref at construction');

# --- Valid Str values at construction ---

my $s1 = new StrTest name => '', label => 'empty';
is($s1->name, '', 'Str accepts empty string at construction');

my $s2 = new StrTest name => '0', label => 'zero string';
is($s2->name, '0', 'Str accepts "0" at construction');

my $s3 = new StrTest name => 0, label => 'zero num';
is($s3->name, 0, 'Str accepts numeric 0 at construction');

# --- has_type for builtins ---

ok(Object::Proto::has_type('Str'), 'has_type returns true for builtin Str');
ok(Object::Proto::has_type('TrimmedStr'), 'has_type returns true for registered custom type');
