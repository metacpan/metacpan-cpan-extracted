use strict;
use warnings;
use Test::More;
use Scalar::Util qw(dualvar);
use Object::Proto;

# NonEmptyStr: a Str whose length is greater than zero.

Object::Proto::define('TNonEmptyStr', 'v:NonEmptyStr');
my $o = TNonEmptyStr->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "NonEmptyStr accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected NonEmptyStr\b/, "NonEmptyStr rejects $what") }

my $empty_utf8 = '';
utf8::upgrade($empty_utf8);

accepts('a',              'a word');
accepts('0',              'the string 0');
accepts(0,                'the number 0');
accepts(1.5,              'a float');
accepts(' ',              'a single space');
accepts("\n",             'a newline');
accepts("\x{263A}",       'a UTF-8 string');
accepts(dualvar(0, 'x'),  'a dualvar with a string part');

rejects('',               'the empty string');
rejects($empty_utf8,      'a UTF-8 flagged empty string');
rejects(dualvar(5, ''),   'a dualvar with an empty string part');
rejects(undef,            'undef');
rejects(\'x',             'a scalar ref');
rejects([],               'an array ref');
rejects(qr/x/,            'a regexp');

ok(TNonEmptyStr->new(v => 'x'), 'new() accepts a NonEmptyStr');
eval { TNonEmptyStr->new(v => '') };
like($@, qr/Type constraint failed for 'v' in new\(\): expected NonEmptyStr\b/, 'new() rejects the empty string');

ok(Object::Proto::has_type('NonEmptyStr'), 'has_type knows NonEmptyStr');
is(Object::Proto::slot_info('TNonEmptyStr', 'v')->{type}, 'NonEmptyStr', 'slot_info reports NonEmptyStr');

done_testing;
