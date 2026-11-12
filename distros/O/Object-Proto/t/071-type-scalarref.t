use strict;
use warnings;
use Test::More;
use Tie::Scalar;
use Tie::Hash;
use Object::Proto;

# ScalarRef: a reference to a plain scalar or to another reference - what
# ref() calls SCALAR or REF - blessed or not.

Object::Proto::define('TScalarRef', 'v:ScalarRef');
my $o = TScalarRef->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "ScalarRef accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected ScalarRef\b/, "ScalarRef rejects $what") }

my $glob_copy = *STDOUT;
tie my $tied_scalar, 'Tie::StdScalar';
tie my %tied_hash, 'Tie::StdHash';
%tied_hash = (n => 1, r => []);
my $elem_with_ref = \$tied_hash{r};
my $fetch = $$elem_with_ref;                   # ref() now calls it REF

accepts(\1,                                  'a ref to a number');
accepts(\1.5,                                'a ref to a float');
accepts(\'str',                              'a ref to a string');
accepts(\undef,                              'a ref to undef');
accepts(\(my $var = 1),                      'a ref to a variable');
accepts(\\1,                                 'a ref to a ref');
accepts(\[],                                 'a ref to an array ref');
accepts(bless(\(my $sv = 1), 'TScalarRef::S'), 'a blessed scalar ref');
accepts(\$tied_scalar,                       'a ref to a tied scalar');
accepts(\$tied_hash{n},                      'a ref to a tied hash element');
accepts($elem_with_ref,                      'a ref to a tied element holding a ref');

rejects([],                      'an array ref');
rejects({},                      'a hash ref');
rejects(sub { 1 },               'a code ref');
rejects(qr/x/,                   'a regexp');
rejects(\*STDOUT,                'a glob ref');
rejects(\$glob_copy,             'a ref to a scalar holding a glob');
rejects(*STDOUT{IO},             'an IO ref');
rejects(\substr(my $s = 'abc', 0, 1), 'an LVALUE ref');
rejects(\v1.2.3,                 'a VSTRING ref');
rejects(TScalarRef->new,         'an Object::Proto object');
rejects(undef,                   'undef');
rejects('SCALAR(0x1234)',        'a string');

ok(TScalarRef->new(v => \1), 'new() accepts a ScalarRef');
eval { TScalarRef->new(v => []) };
like($@, qr/Type constraint failed for 'v' in new\(\): expected ScalarRef\b/, 'new() rejects an array ref');

ok(Object::Proto::has_type('ScalarRef'), 'has_type knows ScalarRef');
is(Object::Proto::slot_info('TScalarRef', 'v')->{type}, 'ScalarRef', 'slot_info reports ScalarRef');

done_testing;
