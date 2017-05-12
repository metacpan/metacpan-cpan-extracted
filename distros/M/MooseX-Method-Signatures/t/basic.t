use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;

use lib 't/lib';

use TestClass;
use TestClassWithMxTypes;

ok(exception { TestClass->new });
ok(exception { TestClass->new('moo', 23) });
ok(exception { TestClass->new('moo', 8) });
is(exception { TestClass->new('moo', 52) }, undef);

my $o = TestClass->new('foo');
isa_ok($o, 'TestClass');

is($o->{foo}, 'foo');
is($o->{bar}, 42);

is(exception { $o->set_bar(23) }, undef);
is($o->{bar}, 23);

ok(exception { $o->set_bar('bar') });

{
    my $test_hash = { foo => 1 };
    is(exception { $o->affe($test_hash) }, undef);
    is_deeply($o->{baz}, $test_hash);
}

{
    my $test_array = [qw/a b c/];
    is(exception { $o->affe($test_array) }, undef);
    is_deeply($o->{baz}, $test_array);
}

ok(exception { $o->affe('foo') });

ok(exception { $o->named });
ok(exception { $o->named(optional => 42) });
like(exception { $o->named }, qr/\b at \b .* \b line \s+ \d+/x, "dies with proper exception");

is(exception {
    is_deeply(
        [$o->named(required => 23)],
        [undef, 23],
    );
}, undef);

is(exception {
    is_deeply(
        [$o->named(optional => 42, required => 23)],
        [42, 23],
    );
}, undef);

ok(exception { $o->combined(1, 2) });
ok(exception { $o->combined(1, required => 2) });

is(exception {
    is_deeply(
        [$o->combined(1, 2, 3, required => 4, optional => 5)],
        [1, 2, 3, 5, 4],
    );
}, undef);

is(exception { $o->with_coercion({}) }, undef);
ok(exception { $o->without_coercion({}) });
is(exception { $o->named_with_coercion(foo => bless({}, 'MyType')) }, undef);
is(exception { $o->named_with_coercion(foo => {}) }, undef);

is(exception { $o->optional_with_coercion() }, undef);
{
    is(exception {
        $o->default_with_coercion()
    }, undef, 'Complex default with coercion' );
}

# MooseX::Meta::Signature::Combined bug? optional positional can't be omitted
#lives_ok(sub { $o->combined(1, 2, required => 3) });
#lives_ok(sub { $o->combined(1, 2, required => 3, optional => 4) });

use MooseX::Method::Signatures;

my $anon = method ($foo, $bar) { };
isa_ok($anon, 'Moose::Meta::Method');

my $mxt =  TestClassWithMxTypes->new();

ok(exception { $mxt->with_coercion() });
is(exception { $mxt->with_coercion('Str') }, undef);

isa_ok( $mxt->with_coercion('Str'), q/Moose::Meta::TypeConstraint/ );
is(exception { $mxt->optional_with_coercion() }, undef);
is(exception { $mxt->optional_with_coercion('Str') }, undef);

done_testing;
