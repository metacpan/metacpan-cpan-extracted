#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "eqi/nei require perl 5.38+ (have $])"
        unless $] >= 5.038;
}

use Syntax::Infix::EqualityInsensitive;

# --- eqi: basic ASCII ---
ok('hello' eqi 'hello',  'eqi: identical strings');
ok('hello' eqi 'HELLO',  'eqi: all-caps RHS');
ok('HELLO' eqi 'hello',  'eqi: all-caps LHS');
ok('Hello' eqi 'hElLo',  'eqi: mixed case both sides');
ok(!('hello' eqi 'world'), 'eqi: different strings');
ok(!('hello' eqi 'hell'),  'eqi: prefix only — false');

# --- nei: basic ASCII ---
ok('hello' nei 'world',  'nei: different strings');
ok('hello' nei 'WORLD',  'nei: different strings, case variant');
ok(!('hello' nei 'HELLO'), 'nei: same strings case-insensitively');
ok(!('ABC' nei 'abc'),     'nei: all-case variants match, so nei is false');

# --- empty strings ---
ok('' eqi '',    'eqi: both empty');
ok(!( '' eqi 'a'), 'eqi: empty vs non-empty');
ok('' nei 'a',   'nei: empty vs non-empty');
ok(!( '' nei ''), 'nei: both empty');

# --- numbers treated as strings ---
ok(42  eqi '42', 'eqi: integer vs string "42"');
ok(42  eqi 42,   'eqi: integer vs integer');
ok(!( 42 eqi 43 ), 'eqi: different numbers');

# --- Unicode case-folding ---
{
    use utf8;

    # Basic Latin accented — fold-case handles these
    ok('café' eqi 'CAFÉ',   'eqi: accented Latin');
    ok('café' nei 'caffe',  'nei: different despite similar shape');

    # German sharp-s: ß folds to ss
    ok("stra\x{df}e" eqi 'STRASSE', 'eqi: sharp-s folds to ss');
    ok('STRASSE' eqi "stra\x{df}e", 'eqi: symmetric sharp-s');
    ok(!("stra\x{df}e" nei 'STRASSE'), 'nei: sharp-s match means nei is false');

    # Greek sigma: σ/ς/Σ all fold to σ
    ok("\x{3c3}" eqi "\x{3a3}", 'eqi: Greek small sigma eq capital sigma');
    ok("\x{3c2}" eqi "\x{3a3}", 'eqi: Greek final sigma eq capital sigma');

    # Turkish dotless-i — Unicode folding, not locale-sensitive lc()
    ok('istanbul' eqi 'ISTANBUL', 'eqi: ASCII i/I case fold');
}

# --- undef (stringifies to "") ---
{
    no warnings 'uninitialized';
    my $u;
    ok($u eqi '',   'eqi: undef eqi empty string');
    ok(!($u eqi 'x'), 'eqi: undef nei non-empty');
    ok($u nei 'x',  'nei: undef nei non-empty');
}

# --- overloaded stringify ---
{
    package My::Str;
    use overload '""' => sub { 'Hello' }, fallback => 1;
    sub new { bless {}, shift }

    package main;
    my $obj = My::Str->new;
    ok($obj eqi 'hello', 'eqi: overloaded object stringifies');
    ok($obj eqi 'HELLO', 'eqi: overloaded object case-insensitive');
    ok($obj nei 'world', 'nei: overloaded object different string');
}

# --- precedence: rel (peer of eq/ne) ---
# eqi should bind the same way eq does in boolean expressions
{
    my $x = 'yes';
    my $result = $x eqi 'YES' ? 'matched' : 'no';
    is($result, 'matched', 'eqi: works in ternary condition');

    ok(!('a' eqi 'b') && 1, 'eqi: usable in && expression');
}

# --- lexical scope: 'no' removes the operators ---
{
    no Syntax::Infix::EqualityInsensitive;
    my $err;
    { local $SIG{__WARN__} = sub {}; eval '"a" eqi "A"' }
    $err = $@;
    ok($err, 'eqi: parse error after no-import');

    { local $SIG{__WARN__} = sub {}; eval '"a" nei "B"' }
    $err = $@;
    ok($err, 'nei: parse error after no-import');
}

done_testing;
