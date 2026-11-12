use strict;
use warnings;
use Test::More;
use Object::Proto;

# Undef: an undefined value.

Object::Proto::define('TUndef', 'v:Undef', 'd:Undef:default(undef)');
my $o = TUndef->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "Undef accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected Undef\b/, "Undef rejects $what") }

my $unset;

accepts(undef,   'undef');
accepts($unset,  'a variable holding undef');

rejects(0,       'zero');
rejects('',      'the empty string');
rejects('undef', 'the string undef');
rejects(\undef,  'a ref to undef');
rejects([],      'an array ref');

ok(!defined $o->d, 'an Undef slot can default to undef');

ok(TUndef->new(v => undef), 'new() accepts undef');
eval { TUndef->new(v => 1) };
like($@, qr/Type constraint failed for 'v' in new\(\): expected Undef\b/, 'new() rejects a defined value');

ok(Object::Proto::has_type('Undef'), 'has_type knows Undef');
is(Object::Proto::slot_info('TUndef', 'v')->{type}, 'Undef', 'slot_info reports Undef');

done_testing;
