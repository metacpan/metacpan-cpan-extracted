use strict;
use warnings;
use Test::More;
use Object::Proto;

# RegexpRef: a qr// regular expression, whatever class it is blessed into.

Object::Proto::define('TRegexpRef', 'v:RegexpRef');
my $o = TRegexpRef->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "RegexpRef accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected RegexpRef\b/, "RegexpRef rejects $what") }

my $re = qr/x/;
my $bare = ${ qr/z/ };                 # a regexp copied out of its qr// ref

accepts($re,                            'a qr//');
accepts(qr/x/ims,                       'a qr// with flags');
accepts(bless(qr/y/, 'TRegexpRef::P'),  'a qr// blessed into another class');
accepts(\$bare,                         'a ref to a copied regexp');

rejects('x',                     'a pattern string');
rejects("$re",                   'a stringified qr//');
rejects(bless({}, 'Regexp'),     'a hash blessed into Regexp');
rejects(\1,                      'a scalar ref');
rejects([],                      'an array ref');
rejects(sub { 1 },               'a code ref');
rejects(undef,                   'undef');

ok(TRegexpRef->new(v => qr/z/), 'new() accepts a RegexpRef');
eval { TRegexpRef->new(v => 'z') };
like($@, qr/Type constraint failed for 'v' in new\(\): expected RegexpRef\b/, 'new() rejects a string');

ok(Object::Proto::has_type('RegexpRef'), 'has_type knows RegexpRef');
is(Object::Proto::slot_info('TRegexpRef', 'v')->{type}, 'RegexpRef', 'slot_info reports RegexpRef');

done_testing;
