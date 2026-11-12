use strict;
use warnings;
use Test::More;
use Object::Proto;

# NegativeInt: an Int less than zero.

Object::Proto::define('TNegativeInt', 'v:NegativeInt');
my $o = TNegativeInt->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "NegativeInt accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected NegativeInt\b/, "NegativeInt rejects $what") }

accepts(-1,              'minus one');
accepts('-42',           'a negative string');
accepts(-2147483648,     'a large negative integer');
accepts(-(~0 >> 1) - 1,  'the smallest signed integer');

rejects(0,       'zero');
rejects('0',     'the string 0');
rejects('-0',    'the string -0');
rejects(1,       'one');
rejects('1',     'a positive string');
rejects(~0,      'the largest unsigned integer');
rejects(-1.5,    'a negative float');
rejects('-1.5',  'a negative float string');
rejects('abc',   'a word');
rejects('',      'the empty string');
rejects(undef,   'undef');
rejects([],      'an array ref');

ok(TNegativeInt->new(v => -3), 'new() accepts a NegativeInt');
eval { TNegativeInt->new(v => 0) };
like($@, qr/Type constraint failed for 'v' in new\(\): expected NegativeInt\b/, 'new() rejects zero');

ok(Object::Proto::has_type('NegativeInt'), 'has_type knows NegativeInt');
is(Object::Proto::slot_info('TNegativeInt', 'v')->{type}, 'NegativeInt', 'slot_info reports NegativeInt');

done_testing;
