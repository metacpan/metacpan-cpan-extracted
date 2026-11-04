use strict;
use warnings;
use Test::More;
use Object::Proto;

Object::Proto::define('IE', 'a', 'b');
my $o = IE->new(a => 1);

eval { Object::Proto::has_own_property(42, 'a') };
like($@, qr/Not an object/, 'has_own_property wants an object');
ok(!Object::Proto::has_own_property(bless([], 'IE::Unknown'), 'a'), 'an object of an undefined class has no own property');
ok(!Object::Proto::has_own_property($o, 'nope'), 'nor an unknown property');
ok(Object::Proto::has_own_property($o, 'a'), 'a set slot is an own property');
ok(!Object::Proto::has_own_property($o, 'b'), 'an unset one is not');

ok(!defined Object::Proto::slot_info('IE::Unknown', 'a'), 'slot_info on an undefined class is undef');
ok(!defined Object::Proto::slot_info('IE', 'nope'), 'and on an unknown property');

my @parents = Object::Proto::parent('IE');
is_deeply(\@parents, [], 'parent in list context with no parents is empty');
ok(!defined scalar Object::Proto::parent('IE'), 'and undef in scalar context');
@parents = Object::Proto::parent('IE::Unknown');
is_deeply(\@parents, [], 'as for an undefined class');

my $n = Object::Proto::properties('IE::Unknown');
is($n, 0, 'properties of an undefined class counts zero');
my @props = Object::Proto::properties('IE::Unknown');
is_deeply(\@props, [], 'and lists nothing');

Object::Proto::define('DD', 'd');
Object::Proto::define('DB', extends => 'DD', 'b');
Object::Proto::define('DC', extends => 'DD', 'c');
Object::Proto::define('DA', extends => ['DB', 'DC'], 'a');
is_deeply([Object::Proto::ancestors('DA')], ['DB', 'DC', 'DD'], 'a diamond lists the shared grandparent once');
Object::Proto::define('DE', extends => 'DB', 'e');
Object::Proto::define('DF', extends => ['DB', 'DE'], 'f');
is_deeply([Object::Proto::ancestors('DF')], ['DB', 'DE', 'DD'], 'a parent reached again through a child of it is listed once');

my $hash = bless { k => [1, 2] }, 'IE::Hash';
my $hc = Object::Proto::clone($hash);
isa_ok($hc, 'IE::Hash', 'a cloned blessed hash');
is_deeply($hc, $hash, 'with its contents');
isnt($hc->{k}, $hash->{k}, 'copied deeply');
my $sref = bless \(my $s = 'inner'), 'IE::Scalar';
my $sc = Object::Proto::clone($sref);
isa_ok($sc, 'IE::Scalar', 'a cloned blessed scalar reference');
is($$sc, 'inner', 'with its value');
my $code = sub { 42 };
is(Object::Proto::clone($code), $code, 'a code reference is shared');
is(Object::Proto::clone([$code])->[0], $code, 'inside a structure too');

done_testing;
