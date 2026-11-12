use strict;
use warnings;
use Test::More;
use Object::Proto;

# Ref: any reference, blessed or not.

Object::Proto::define('TRef', 'v:Ref');
my $o = TRef->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "Ref accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected Ref\b/, "Ref rejects $what") }

accepts(\1,                     'a scalar ref');
accepts([],                     'an array ref');
accepts({},                     'a hash ref');
accepts(sub { 1 },              'a code ref');
accepts(qr/x/,                  'a regexp');
accepts(\*STDOUT,               'a glob ref');
accepts(*STDOUT{IO},            'an IO ref');
accepts(\\1,                    'a ref to a ref');
accepts(bless({}, 'TRef::Obj'), 'a blessed ref');
accepts(TRef->new,              'an Object::Proto object');

rejects(undef,           'undef');
rejects(0,               'zero');
rejects('',              'the empty string');
rejects('ARRAY(0x1234)', 'a string that looks like a ref');
rejects(*STDOUT,         'a bare glob');

ok(TRef->new(v => []), 'new() accepts a Ref');
eval { TRef->new(v => 'x') };
like($@, qr/Type constraint failed for 'v' in new\(\): expected Ref\b/, 'new() rejects a non-ref');

ok(Object::Proto::has_type('Ref'), 'has_type knows Ref');
is(Object::Proto::slot_info('TRef', 'v')->{type}, 'Ref', 'slot_info reports Ref');

done_testing;
