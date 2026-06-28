#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('PDF::Make::Arena');
    use_ok('PDF::Make::Obj');
}

my $arena = PDF::Make::Arena->new;
isa_ok($arena, 'PDF::Make::Arena', 'Arena created');

my $stream = $arena->stream;
isa_ok($stream, 'PDF::Make::Obj', 'stream() returns Obj');
ok($stream->is_stream, 'stream object reports is_stream');
ok(!$stream->is_array, 'stream object is not array');
ok(!$stream->is_dict, 'stream object is not dict');
ok(!defined $stream->value, 'stream composite value is undef');

my $text = $arena->str('abcde');
is($text->len, 5, 'string len() returns byte length');

ok($arena->int(7)->is_numeric, 'int object is_numeric true');
ok($arena->real(1.25)->is_numeric, 'real object is_numeric true');
ok(!$arena->name('Type')->is_numeric, 'name object is_numeric false');

my $array = $arena->array;
$array->push($arena->int(10));
$array->push($arena->int(20));
ok(!defined $array->get(99), 'array get() returns undef for missing index');

my $dict = $arena->dict;
$dict->set('First', $arena->int(1));
$dict->set('Second', $arena->int(2));
ok(!defined $dict->get('Missing'), 'dict get() returns undef for missing key');
is($dict->del('First'), 1, 'del() returns true for existing key');
ok(!$dict->has('First'), 'deleted key is gone');
is($dict->len, 1, 'dict len() updates after delete');
is($dict->del('Missing'), 0, 'del() returns false for missing key');

{
    local $@;
    eval { $array->has('oops') };
    like($@, qr/not a dict/i, 'has() on array croaks');
}

{
    local $@;
    eval { $dict->push($arena->int(3)) };
    like($@, qr/not an array/i, 'push() on dict croaks');
}

{
    local $@;
    eval { $stream->len };
    like($@, qr/not an array, dict, or string/i, 'len() on stream croaks');
}

done_testing;
