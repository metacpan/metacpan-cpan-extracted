use strict;
use warnings;
use Test::More tests => 18;

# Positional constructor with typed slots, constructor edge cases

BEGIN {
    require Object::Proto;
    Object::Proto::define('TypedPos', 'name:Str', 'age:Int', 'score:Num');
    Object::Proto::define('WithDefaults', 'label:Str:default(hello)', 'count:Int:default(0)');
    Object::Proto::define('WithRequired', 'id:Int:required', 'tag:Str');
    Object::Proto::define('ReadonlyDefault', 'value:Str:readonly:default(foo)');
    Object::Proto::define('Plain', qw(a b c));
}

use Object::Proto;

# --- Positional typed constructor ---

# Valid positional typed
my $tp = new TypedPos 'Alice', 30, 99.5;
is($tp->name, 'Alice', 'positional typed: Str accepted');
is($tp->age, 30, 'positional typed: Int accepted');
is($tp->score, 99.5, 'positional typed: Num accepted');

# Invalid type in positional should croak
eval { new TypedPos 'Bob', 'not_int', 50.0 };
like($@, qr/Type constraint failed.*age.*Int/i, 'positional typed: rejects bad Int');

eval { new TypedPos [], 25, 50.0 };
like($@, qr/Type constraint failed.*name.*Str/i, 'positional typed: rejects ref as Str');

# --- Named constructor unknown keys ---

my $plain = new Plain a => 1, b => 2, c => 3, nonexistent => 99;
is($plain->a, 1, 'unknown keys silently ignored: known key works');
is($plain->b, 2, 'unknown keys silently ignored: second key works');

# --- Positional with too many args ---

my $extra = new Plain 'x', 'y', 'z', 'overflow';
is($extra->a, 'x', 'extra positional args ignored: first works');
is($extra->b, 'y', 'extra positional args ignored: second works');
is($extra->c, 'z', 'extra positional args ignored: third works');

# --- Positional with too few args ---

my $few = new Plain 'only_one';
is($few->a, 'only_one', 'fewer positional args: first set');
ok(!defined $few->b || $few->b eq '', 'fewer positional args: second undef-ish');

# --- Defaults applied ---

my $def = new WithDefaults;
is($def->label, 'hello', 'default Str applied');
is($def->count, 0, 'default Int applied');

# --- Required croak on missing ---

eval { new WithRequired tag => 'test' };
like($@, qr/Required.*id/i, 'required slot croaks when missing');

# Named with required provided
my $req = new WithRequired id => 42, tag => 'ok';
is($req->id, 42, 'required slot accepted when provided');

# --- Readonly with default ---

my $ro = new ReadonlyDefault;
is($ro->value, 'foo', 'readonly+default: default applied');
eval { $ro->value('bar') };
like($@, qr/readonly|Cannot modify/i, 'readonly+default: setter croaks');
