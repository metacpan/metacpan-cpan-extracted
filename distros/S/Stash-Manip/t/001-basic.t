use strict;
use warnings;

use Test::More;
use Test::Exception;

use Stash::Manip;

dies_ok { Stash::Manip->name } q{... can't call name() as a class method};

{
    package Foo;

    use constant SOME_CONSTANT => 1;
}

# ----------------------------------------------------------------------
## tests adding a HASH

my $foo_stash = Stash::Manip->new('Foo');
ok(!defined($Foo::{foo}), '... the %foo slot has not been created yet');
ok(!$foo_stash->has_package_symbol('%foo'), '... the object agrees');
ok(!defined($Foo::{foo}), '... checking doesn\' vivify');

lives_ok {
    $foo_stash->add_package_symbol('%foo' => { one => 1 });
} '... created %Foo::foo successfully';

# ... scalar should NOT be created here

ok(!$foo_stash->has_package_symbol('$foo'), '... SCALAR shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('@foo'), '... ARRAY shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('&foo'), '... CODE shouldnt have been created too');

ok(defined($Foo::{foo}), '... the %foo slot was created successfully');
ok($foo_stash->has_package_symbol('%foo'), '... the meta agrees');

# check the value ...

{
    no strict 'refs';
    ok(exists ${'Foo::foo'}{one}, '... our %foo was initialized correctly');
    is(${'Foo::foo'}{one}, 1, '... our %foo was initialized correctly');
}

my $foo = $foo_stash->get_package_symbol('%foo');
is_deeply({ one => 1 }, $foo, '... got the right package variable back');

# ... make sure changes propogate up

$foo->{two} = 2;

{
    no strict 'refs';
    is(\%{'Foo::foo'}, $foo_stash->get_package_symbol('%foo'), '... our %foo is the same as the metas');

    ok(exists ${'Foo::foo'}{two}, '... our %foo was updated correctly');
    is(${'Foo::foo'}{two}, 2, '... our %foo was updated correctly');
}

# ----------------------------------------------------------------------
## test adding an ARRAY

ok(!defined($Foo::{bar}), '... the @bar slot has not been created yet');

lives_ok {
    $foo_stash->add_package_symbol('@bar' => [ 1, 2, 3 ]);
} '... created @Foo::bar successfully';

ok(defined($Foo::{bar}), '... the @bar slot was created successfully');
ok($foo_stash->has_package_symbol('@bar'), '... the meta agrees');

# ... why does this not work ...

ok(!$foo_stash->has_package_symbol('$bar'), '... SCALAR shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('%bar'), '... HASH shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('&bar'), '... CODE shouldnt have been created too');

# check the value itself

{
    no strict 'refs';
    is(scalar @{'Foo::bar'}, 3, '... our @bar was initialized correctly');
    is(${'Foo::bar'}[1], 2, '... our @bar was initialized correctly');
}

# ----------------------------------------------------------------------
## test adding a SCALAR

ok(!defined($Foo::{baz}), '... the $baz slot has not been created yet');

lives_ok {
    $foo_stash->add_package_symbol('$baz' => 10);
} '... created $Foo::baz successfully';

ok(defined($Foo::{baz}), '... the $baz slot was created successfully');
ok($foo_stash->has_package_symbol('$baz'), '... the meta agrees');

ok(!$foo_stash->has_package_symbol('@baz'), '... ARRAY shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('%baz'), '... HASH shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('&baz'), '... CODE shouldnt have been created too');

is(${$foo_stash->get_package_symbol('$baz')}, 10, '... got the right value back');

{
    no strict 'refs';
    ${'Foo::baz'} = 1;

    is(${'Foo::baz'}, 1, '... our $baz was assigned to correctly');
    is(${$foo_stash->get_package_symbol('$baz')}, 1, '... the meta agrees');
}

# ----------------------------------------------------------------------
## test adding a CODE

ok(!defined($Foo::{funk}), '... the &funk slot has not been created yet');

lives_ok {
    $foo_stash->add_package_symbol('&funk' => sub { "Foo::funk" });
} '... created &Foo::funk successfully';

ok(defined($Foo::{funk}), '... the &funk slot was created successfully');
ok($foo_stash->has_package_symbol('&funk'), '... the meta agrees');

ok(!$foo_stash->has_package_symbol('$funk'), '... SCALAR shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('@funk'), '... ARRAY shouldnt have been created too');
ok(!$foo_stash->has_package_symbol('%funk'), '... HASH shouldnt have been created too');

{
    no strict 'refs';
    ok(defined &{'Foo::funk'}, '... our &funk exists');
}

is(Foo->funk(), 'Foo::funk', '... got the right value from the function');

# ----------------------------------------------------------------------
## test multiple slots in the glob

my $ARRAY = [ 1, 2, 3 ];
my $CODE = sub { "Foo::foo" };

lives_ok {
    $foo_stash->add_package_symbol('@foo' => $ARRAY);
} '... created @Foo::foo successfully';

ok($foo_stash->has_package_symbol('@foo'), '... the @foo slot was added successfully');
is($foo_stash->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');

lives_ok {
    $foo_stash->add_package_symbol('&foo' => $CODE);
} '... created &Foo::foo successfully';

ok($foo_stash->has_package_symbol('&foo'), '... the meta agrees');
is($foo_stash->get_package_symbol('&foo'), $CODE, '... got the right value for &Foo::foo');

lives_ok {
    $foo_stash->add_package_symbol('$foo' => 'Foo::foo');
} '... created $Foo::foo successfully';

ok($foo_stash->has_package_symbol('$foo'), '... the meta agrees');
my $SCALAR = $foo_stash->get_package_symbol('$foo');
is($$SCALAR, 'Foo::foo', '... got the right scalar value back');

{
    no strict 'refs';
    is(${'Foo::foo'}, 'Foo::foo', '... got the right value from the scalar');
}

lives_ok {
    $foo_stash->remove_package_symbol('%foo');
} '... removed %Foo::foo successfully';

ok(!$foo_stash->has_package_symbol('%foo'), '... the %foo slot was removed successfully');
ok($foo_stash->has_package_symbol('@foo'), '... the @foo slot still exists');
ok($foo_stash->has_package_symbol('&foo'), '... the &foo slot still exists');
ok($foo_stash->has_package_symbol('$foo'), '... the $foo slot still exists');

is($foo_stash->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');
is($foo_stash->get_package_symbol('&foo'), $CODE, '... got the right value for &Foo::foo');
is($foo_stash->get_package_symbol('$foo'), $SCALAR, '... got the right value for $Foo::foo');

{
    no strict 'refs';
    ok(!defined(*{"Foo::foo"}{HASH}), '... the %foo slot has been removed successfully');
    ok(defined(*{"Foo::foo"}{ARRAY}), '... the @foo slot has NOT been removed');
    ok(defined(*{"Foo::foo"}{CODE}), '... the &foo slot has NOT been removed');
    ok(defined(${"Foo::foo"}), '... the $foo slot has NOT been removed');
}

lives_ok {
    $foo_stash->remove_package_symbol('&foo');
} '... removed &Foo::foo successfully';

ok(!$foo_stash->has_package_symbol('&foo'), '... the &foo slot no longer exists');

ok($foo_stash->has_package_symbol('@foo'), '... the @foo slot still exists');
ok($foo_stash->has_package_symbol('$foo'), '... the $foo slot still exists');

is($foo_stash->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');
is($foo_stash->get_package_symbol('$foo'), $SCALAR, '... got the right value for $Foo::foo');

{
    no strict 'refs';
    ok(!defined(*{"Foo::foo"}{HASH}), '... the %foo slot has been removed successfully');
    ok(!defined(*{"Foo::foo"}{CODE}), '... the &foo slot has now been removed');
    ok(defined(*{"Foo::foo"}{ARRAY}), '... the @foo slot has NOT been removed');
    ok(defined(${"Foo::foo"}), '... the $foo slot has NOT been removed');
}

lives_ok {
    $foo_stash->remove_package_symbol('$foo');
} '... removed $Foo::foo successfully';

ok(!$foo_stash->has_package_symbol('$foo'), '... the $foo slot no longer exists');

ok($foo_stash->has_package_symbol('@foo'), '... the @foo slot still exists');

is($foo_stash->get_package_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');

{
    no strict 'refs';
    ok(!defined(*{"Foo::foo"}{HASH}), '... the %foo slot has been removed successfully');
    ok(!defined(*{"Foo::foo"}{CODE}), '... the &foo slot has now been removed');
    ok(!defined(${"Foo::foo"}), '... the $foo slot has now been removed');
    ok(defined(*{"Foo::foo"}{ARRAY}), '... the @foo slot has NOT been removed');
}

# check some errors

dies_ok {
    $foo_stash->add_package_symbol('@bar', {})
} "can't initialize a slot with the wrong type of value";

dies_ok {
    $foo_stash->add_package_symbol('bar', [])
} "can't initialize a slot with the wrong type of value";

dies_ok {
    $foo_stash->add_package_symbol('$bar', sub { })
} "can't initialize a slot with the wrong type of value";

{
    package Bar;
    open *foo, '<', $0;
}

dies_ok {
    $foo_stash->add_package_symbol('$bar', *Bar::foo{IO})
} "can't initialize a slot with the wrong type of value";

# check compile time manipulation

{
    package Baz;

    our $foo = 23;
    our @foo = "bar";
    our %foo = (baz => 1);
    sub foo { }
    open *foo, '<', $0;
    BEGIN { Stash::Manip->new(__PACKAGE__)->remove_package_symbol('&foo') }
}

{
    my $stash = Stash::Manip->new('Baz');
    is(${ $stash->get_package_symbol('$foo') }, 23, "got \$foo");
    is_deeply($stash->get_package_symbol('@foo'), ['bar'], "got \@foo");
    is_deeply($stash->get_package_symbol('%foo'), {baz => 1}, "got \%foo");
    ok(!$stash->has_package_symbol('&foo'), "got \&foo");
    is($stash->get_package_symbol('foo'), *Baz::foo{IO}, "got foo");
}

done_testing;
