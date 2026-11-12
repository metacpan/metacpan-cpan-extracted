use strict;
use warnings;
use Test::More;
use Object::Proto;

# PositiveInt: an Int greater than zero.

Object::Proto::define('TPositiveInt', 'v:PositiveInt');
my $o = TPositiveInt->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "PositiveInt accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected PositiveInt\b/, "PositiveInt rejects $what") }

accepts(1,          'one');
accepts('42',       'a numeric string');
accepts(2147483647, 'a large integer');
accepts(~0,         'the largest unsigned integer');

rejects(0,               'zero');
rejects('0',             'the string 0');
rejects('-0',            'the string -0');
rejects(-1,              'minus one');
rejects('-1',            'a negative string');
rejects(-(~0 >> 1) - 1,  'the smallest signed integer');
rejects(1.5,             'a float');
rejects('1.5',           'a float string');
rejects('abc',           'a word');
rejects('',              'the empty string');
rejects(undef,           'undef');
rejects([],              'an array ref');

$o->v(7);
eval { $o->v(-7) };
is($o->v, 7, 'a rejected value leaves the slot as it was');

ok(TPositiveInt->new(v => 3), 'new() accepts a PositiveInt');
eval { TPositiveInt->new(v => 0) };
like($@, qr/Type constraint failed for 'v' in new\(\): expected PositiveInt\b/, 'new() rejects zero');

ok(Object::Proto::has_type('PositiveInt'), 'has_type knows PositiveInt');
is(Object::Proto::slot_info('TPositiveInt', 'v')->{type}, 'PositiveInt', 'slot_info reports PositiveInt');

done_testing;
