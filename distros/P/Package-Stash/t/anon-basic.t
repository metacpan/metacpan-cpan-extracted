#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;

use Package::Stash;

BEGIN {
    plan skip_all => "Anonymous stashes in PP need at least perl 5.14"
        if $] < 5.014
        && $Package::Stash::IMPLEMENTATION eq 'PP';
}

use Test::Requires 'Package::Anon';
use Symbol;

my $Foo = Package::Anon->new('Foo');
$Foo->{SOME_CONSTANT} = \1;

# ----------------------------------------------------------------------
## tests adding a HASH

my $foo_stash = Package::Stash->new($Foo);
ok(!defined($Foo->{foo}), '... the %foo slot has not been created yet');
ok(!$foo_stash->has_symbol('%foo'), '... the object agrees');
ok(!defined($Foo->{foo}), '... checking doesn\'t vivify');

is(exception {
    $foo_stash->add_symbol('%foo' => { one => 1 });
}, undef, '... created %Foo::foo successfully');

# ... scalar should NOT be created here

ok(!$foo_stash->has_symbol('$foo'), '... SCALAR shouldnt have been created too');
ok(!$foo_stash->has_symbol('@foo'), '... ARRAY shouldnt have been created too');
ok(!$foo_stash->has_symbol('&foo'), '... CODE shouldnt have been created too');

ok(defined($Foo->{foo}), '... the %foo slot was created successfully');
ok($foo_stash->has_symbol('%foo'), '... the meta agrees');

# check the value ...

ok(exists $Foo->{foo}{one}, '... our %foo was initialized correctly');
is($Foo->{foo}{one}, 1, '... our %foo was initialized correctly');

my $foo = $foo_stash->get_symbol('%foo');
is_deeply({ one => 1 }, $foo, '... got the right package variable back');

# ... make sure changes propogate up

$foo->{two} = 2;

is(\%{ $Foo->{foo} }, $foo_stash->get_symbol('%foo'), '... our %foo is the same as the metas');

ok(exists ${ $Foo->{foo} }{two}, '... our %foo was updated correctly');
is(${ $Foo->{foo} }{two}, 2, '... our %foo was updated correctly');

# ----------------------------------------------------------------------
## test adding an ARRAY

ok(!defined($Foo->{bar}), '... the @bar slot has not been created yet');

is(exception {
    $foo_stash->add_symbol('@bar' => [ 1, 2, 3 ]);
}, undef, '... created @Foo::bar successfully');

ok(defined($Foo->{bar}), '... the @bar slot was created successfully');
ok($foo_stash->has_symbol('@bar'), '... the meta agrees');

# ... why does this not work ...

ok(!$foo_stash->has_symbol('$bar'), '... SCALAR shouldnt have been created too');
ok(!$foo_stash->has_symbol('%bar'), '... HASH shouldnt have been created too');
ok(!$foo_stash->has_symbol('&bar'), '... CODE shouldnt have been created too');

# check the value itself

is(scalar @{ $Foo->{bar} }, 3, '... our @bar was initialized correctly');
is($Foo->{bar}[1], 2, '... our @bar was initialized correctly');

# ----------------------------------------------------------------------
## test adding a SCALAR

ok(!defined($Foo->{baz}), '... the $baz slot has not been created yet');

is(exception {
    $foo_stash->add_symbol('$baz' => 10);
}, undef, '... created $Foo::baz successfully');

ok(defined($Foo->{baz}), '... the $baz slot was created successfully');
ok($foo_stash->has_symbol('$baz'), '... the meta agrees');

ok(!$foo_stash->has_symbol('@baz'), '... ARRAY shouldnt have been created too');
ok(!$foo_stash->has_symbol('%baz'), '... HASH shouldnt have been created too');
ok(!$foo_stash->has_symbol('&baz'), '... CODE shouldnt have been created too');

is(${$foo_stash->get_symbol('$baz')}, 10, '... got the right value back');

${ $Foo->{baz} } = 1;

is(${ $Foo->{baz} }, 1, '... our $baz was assigned to correctly');
is(${$foo_stash->get_symbol('$baz')}, 1, '... the meta agrees');

# ----------------------------------------------------------------------
## test adding a CODE

ok(!defined($Foo->{funk}), '... the &funk slot has not been created yet');

is(exception {
    $foo_stash->add_symbol('&funk' => sub { "Foo::funk" });
}, undef, '... created &Foo::funk successfully');

ok(defined($Foo->{funk}), '... the &funk slot was created successfully');
ok($foo_stash->has_symbol('&funk'), '... the meta agrees');

ok(!$foo_stash->has_symbol('$funk'), '... SCALAR shouldnt have been created too');
ok(!$foo_stash->has_symbol('@funk'), '... ARRAY shouldnt have been created too');
ok(!$foo_stash->has_symbol('%funk'), '... HASH shouldnt have been created too');

ok(defined &{ $Foo->{funk} }, '... our &funk exists');

is($Foo->bless({})->funk(), 'Foo::funk', '... got the right value from the function');

# ----------------------------------------------------------------------
## test multiple slots in the glob

my $ARRAY = [ 1, 2, 3 ];
my $CODE = sub { "Foo::foo" };

is(exception {
    $foo_stash->add_symbol('@foo' => $ARRAY);
}, undef, '... created @Foo::foo successfully');

ok($foo_stash->has_symbol('@foo'), '... the @foo slot was added successfully');
is($foo_stash->get_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');

is(exception {
    $foo_stash->add_symbol('&foo' => $CODE);
}, undef, '... created &Foo::foo successfully');

ok($foo_stash->has_symbol('&foo'), '... the meta agrees');
is($foo_stash->get_symbol('&foo'), $CODE, '... got the right value for &Foo::foo');

is(exception {
    $foo_stash->add_symbol('$foo' => 'Foo::foo');
}, undef, '... created $Foo::foo successfully');

ok($foo_stash->has_symbol('$foo'), '... the meta agrees');
my $SCALAR = $foo_stash->get_symbol('$foo');
is($$SCALAR, 'Foo::foo', '... got the right scalar value back');

is(${ $Foo->{foo} }, 'Foo::foo', '... got the right value from the scalar');

is(exception {
    $foo_stash->remove_symbol('%foo');
}, undef, '... removed %Foo::foo successfully');

ok(!$foo_stash->has_symbol('%foo'), '... the %foo slot was removed successfully');
ok($foo_stash->has_symbol('@foo'), '... the @foo slot still exists');
ok($foo_stash->has_symbol('&foo'), '... the &foo slot still exists');
ok($foo_stash->has_symbol('$foo'), '... the $foo slot still exists');

is($foo_stash->get_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');
is($foo_stash->get_symbol('&foo'), $CODE, '... got the right value for &Foo::foo');
is($foo_stash->get_symbol('$foo'), $SCALAR, '... got the right value for $Foo::foo');

ok(!defined(*{ $Foo->{foo} }{HASH}), '... the %foo slot has been removed successfully');
ok(defined(*{ $Foo->{foo} }{ARRAY}), '... the @foo slot has NOT been removed');
ok(defined(*{ $Foo->{foo} }{CODE}), '... the &foo slot has NOT been removed');
ok(defined(${ $Foo->{foo} }), '... the $foo slot has NOT been removed');

is(exception {
    $foo_stash->remove_symbol('&foo');
}, undef, '... removed &Foo::foo successfully');

ok(!$foo_stash->has_symbol('&foo'), '... the &foo slot no longer exists');

ok($foo_stash->has_symbol('@foo'), '... the @foo slot still exists');
ok($foo_stash->has_symbol('$foo'), '... the $foo slot still exists');

is($foo_stash->get_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');
is($foo_stash->get_symbol('$foo'), $SCALAR, '... got the right value for $Foo::foo');

ok(!defined(*{ $Foo->{foo} }{HASH}), '... the %foo slot has been removed successfully');
ok(!defined(*{ $Foo->{foo} }{CODE}), '... the &foo slot has now been removed');
ok(defined(*{ $Foo->{foo} }{ARRAY}), '... the @foo slot has NOT been removed');
ok(defined(${ $Foo->{foo} }), '... the $foo slot has NOT been removed');

is(exception {
    $foo_stash->remove_symbol('$foo');
}, undef, '... removed $Foo::foo successfully');

ok(!$foo_stash->has_symbol('$foo'), '... the $foo slot no longer exists');

ok($foo_stash->has_symbol('@foo'), '... the @foo slot still exists');

is($foo_stash->get_symbol('@foo'), $ARRAY, '... got the right values for @Foo::foo');

ok(!defined(*{ $Foo->{foo} }{HASH}), '... the %foo slot has been removed successfully');
ok(!defined(*{ $Foo->{foo} }{CODE}), '... the &foo slot has now been removed');
ok(!defined(${ $Foo->{foo} }), '... the $foo slot has now been removed');
ok(defined(*{ $Foo->{foo} }{ARRAY}), '... the @foo slot has NOT been removed');

{
    my $syms = $foo_stash->get_all_symbols;
    is_deeply(
        [ sort keys %{ $syms } ],
        [ sort $foo_stash->list_all_symbols ],
        '... the fetched symbols are the same as the listed ones'
    );
}

{
    my $syms = $foo_stash->get_all_symbols('CODE');

    is_deeply(
        [ sort keys %{ $syms } ],
        [ sort $foo_stash->list_all_symbols('CODE') ],
        '... the fetched symbols are the same as the listed ones'
    );

    foreach my $symbol (keys %{ $syms }) {
        is($syms->{$symbol}, $foo_stash->get_symbol('&' . $symbol), '... got the right symbol');
    }
}

{
    $foo_stash->add_symbol('%bare');
    ok(!$foo_stash->has_symbol('$bare'),
       "add_symbol with single argument doesn't vivify scalar slot");
}

{
    $foo_stash->add_symbol('%zork', {});

    my $syms = $foo_stash->get_all_symbols('HASH');

    is_deeply(
        [ sort keys %{ $syms } ],
        [ sort $foo_stash->list_all_symbols('HASH') ],
        '... the fetched symbols are the same as the listed ones'
    );

    foreach my $symbol (keys %{ $syms }) {
        is($syms->{$symbol}, $foo_stash->get_symbol('%' . $symbol), '... got the right symbol');
    }

    is_deeply(
        $syms,
        {
            zork => *{ $Foo->{zork} }{HASH},
            bare => *{ $Foo->{bare} }{HASH},
        },
        "got the right ones",
    );
}

# check some errors

like(exception {
    $foo_stash->add_symbol('@bar', {})
}, qr/HASH.*is not of type ARRAY/, "can't initialize a slot with the wrong type of value");

like(exception {
    $foo_stash->add_symbol('bar', [])
}, qr/ARRAY.*is not of type IO/, "can't initialize a slot with the wrong type of value");

like(exception {
    $foo_stash->add_symbol('$bar', sub { })
}, qr/CODE.*is not of type SCALAR/, "can't initialize a slot with the wrong type of value");

like(exception {
    $foo_stash->add_symbol('$bar', *{ Symbol::geniosym() }{IO})
}, qr/IO.*is not of type SCALAR/, "can't initialize a slot with the wrong type of value");

is_deeply([Package::Stash->new('Foo')->list_all_symbols], [],
          "Foo:: isn't touched");

# *{ $Quux->{foo} } = \23 doesn't work on 5.12 and lower, apparently
my $Quux = Package::Anon->new('Quux');
{
    my $gv = Symbol::gensym;
    *$gv = \23;
    *$gv = ["bar"];
    *$gv = { baz => 1 };
    *$gv = sub { };
    *$gv = *{ Symbol::geniosym() }{IO};
    $Quux->{foo} = *$gv;
}

{
    my $stash = Package::Stash->new($Quux);

    my %expect = (
        '$foo' => \23,
        '@foo' => ["bar"],
        '%foo' => { baz => 1 },
        '&foo' => \&{ $Quux->{foo} },
        'foo'  => *{ $Quux->{foo} }{IO},
    );

    for my $sym ( sort keys %expect ) {
        is_deeply(
            $stash->get_symbol($sym),
            $expect{$sym},
            "got expected value for $sym"
        );
    }

    $stash->add_symbol('%bar' => {x => 42});

    $expect{'%bar'} = {x => 42};

    for my $sym ( sort keys %expect ) {
        is_deeply(
            $stash->get_symbol($sym),
            $expect{$sym},
            "got expected value for $sym"
        );
    }

    $stash->add_symbol('%bar' => {x => 43});

    $expect{'%bar'} = {x => 43};

    for my $sym ( sort keys %expect ) {
        is_deeply(
            $stash->get_symbol($sym),
            $expect{$sym},
            "got expected value for $sym"
        );
    }
}

is_deeply([Package::Stash->new('Quux')->list_all_symbols], [],
          "Quux:: isn't touched");

my $Quuux = Package::Anon->new('Quuux');

{
    my $gv = Symbol::gensym;
    *$gv = \(my $scalar);
    *$gv = [];
    $Quuux->{foo} = *$gv;
}

{
    my $gv = Symbol::gensym;
    *$gv = [];
    $Quuux->{bar} = *$gv;
}

{
    my $gv = Symbol::gensym;
    *$gv = {};
    *$gv = sub { };
    $Quuux->{baz} = *$gv;
}

$Quuux->{quux} = \1;

$Quuux->{quuux} = \[];

$Quuux->{quuuux} = -1;

{
    my $quuux = Package::Stash->new($Quuux);
    is_deeply(
        # Package::Anon adds a couple methods
        [grep { $_ ne 'isa' && $_ ne 'can' } sort $quuux->list_all_symbols],
        [qw(bar baz foo quuuux quuux quux)],
        "list_all_symbols",
    );
    { local $TODO = $] < 5.010
          ? "undef scalars aren't visible on 5.8"
          : undef;
    is_deeply(
        [sort $quuux->list_all_symbols('SCALAR')],
        [qw(foo)],
        "list_all_symbols SCALAR",
    );
    }
    is_deeply(
        [sort $quuux->list_all_symbols('ARRAY')],
        [qw(bar foo)],
        "list_all_symbols ARRAY",
    );
    is_deeply(
        [sort $quuux->list_all_symbols('HASH')],
        [qw(baz)],
        "list_all_symbols HASH",
    );
    is_deeply(
        # Package::Anon adds a couple methods
        [grep { $_ ne 'isa' && $_ ne 'can' } sort $quuux->list_all_symbols('CODE')],
        [qw(baz quuuux quuux quux)],
        "list_all_symbols CODE",
    );
}

is_deeply([Package::Stash->new('Quuux')->list_all_symbols], [],
          "Quuux:: isn't touched");

done_testing;
