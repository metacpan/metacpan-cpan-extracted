#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# ==== Accessor Return Values ====

# getter returns current value
{
    Object::Proto::define('GetterTest', 'val:Str');

    my $obj = new GetterTest val => 'initial';
    is($obj->val, 'initial', 'getter returns value');

    # Chained assignment
    my $ret = $obj->val('updated');
    is($ret, 'updated', 'setter returns new value');
    is($obj->val, 'updated', 'value was actually set');
}
# method chaining
{
    Object::Proto::define('ChainTest', 'a:Str', 'b:Int', 'c:Num');

    my $obj = new ChainTest a => '', b => 0, c => 0.0;

    # Value is returned, allowing use in expressions
    my $res = $obj->a('hello');
    is($res, 'hello', 'setter returns value for chaining');
}
# ==== Constructor Variations ====

# new with hash
{
    Object::Proto::define('HashNew', 'x:Int', 'y:Int');

    my %args = (x => 10, y => 20);
    my $obj = new HashNew %args;
    is($obj->x, 10, 'hash args x');
    is($obj->y, 20, 'hash args y');
}
# new with partial args
{
    Object::Proto::define('PartialNew',
        'required:Str:required',
        'optional:Str:default(none)',
    );

    my $obj = new PartialNew required => 'yes';
    is($obj->required, 'yes', 'required field set');
    is($obj->optional, 'none', 'optional uses default');
}
# ==== Error Message Quality ====

# type error messages
{
    Object::Proto::define('ErrorMsg', 'num:Int');

    eval { new ErrorMsg num => 'not a number' };
    like($@, qr/Int/, 'error mentions expected type');
    like($@, qr/num/, 'error mentions property name');
}
# required field error
{
    Object::Proto::define('RequiredError', 'must_have:Str:required');

    eval { new RequiredError };
    like($@, qr/required|must_have/i, 'error for missing required field');
}
# readonly error
{
    Object::Proto::define('ReadonlyError', 'fixed:Str:readonly');

    my $obj = new ReadonlyError fixed => 'immutable';
    eval { $obj->fixed('change') };
    like($@, qr/readonly|cannot|modify/i, 'error for modifying readonly');
}
# ==== Property Name Edge Cases ====

# property names with underscores
{
    Object::Proto::define('UnderscoreProps',
        'my_value:Str',
        'another_one:Int',
        '_private:Str',
    );

    my $obj = new UnderscoreProps
        my_value => 'test',
        another_one => 42,
        _private => 'secret';

    is($obj->my_value, 'test', 'underscore property works');
    is($obj->another_one, 42, 'multiple underscores work');
    is($obj->_private, 'secret', 'leading underscore works');
}
# single letter properties
{
    Object::Proto::define('SingleLetter', 'x:Int', 'y:Int', 'z:Int');

    my $obj = new SingleLetter x => 1, y => 2, z => 3;
    is($obj->x, 1, 'single letter x');
    is($obj->y, 2, 'single letter y');
    is($obj->z, 3, 'single letter z');
}
# ==== Mixed Modifiers ====

# type with coerce and default
{
    Object::Proto::define('MixedModifiers',
        'count:Int:default(0):coerce',
    );

    # Default should work
    my $obj1 = new MixedModifiers;
    is($obj1->count, 0, 'default works with type+coerce');

    # Coerce should work
    my $obj2 = new MixedModifiers count => '42';
    is($obj2->count, 42, 'coerce works with type+default');
}
# ==== Introspection ====

# object blessed correctly
{
    Object::Proto::define('BlessCheck', 'val:Str');

    my $obj = new BlessCheck val => 'test';
    isa_ok($obj, 'BlessCheck', 'object has correct class');
    ok(ref($obj), 'object is a reference');
}
# can call accessors
{
    Object::Proto::define('CanCheck', 'prop:Str');

    my $obj = new CanCheck prop => 'value';
    ok($obj->can('prop'), 'object can call prop');
}
# ==== Undef vs Empty ====

# undef handling in optional fields
{
    # Use Any type which allows undef
    Object::Proto::define('UndefOptional', 'maybe:Any');

    my $obj = new UndefOptional;
    ok(!defined($obj->maybe), 'uninitialized optional is undef');

    $obj->maybe('set');
    is($obj->maybe, 'set', 'can set optional');

    $obj->maybe(undef);
    ok(!defined($obj->maybe), 'can set back to undef');
}
# ==== Numeric Edge Cases ====

# numeric precision
{
    Object::Proto::define('NumPrecision', 'val:Num');

    my $obj = new NumPrecision val => 3.14159265358979;
    ok(abs($obj->val - 3.14159265358979) < 1e-10, 'float precision maintained');

    $obj->val(1e308);
    ok($obj->val > 1e307, 'large float works');

    $obj->val(-1e308);
    ok($obj->val < -1e307, 'negative large float works');
}
# integer bounds
{
    Object::Proto::define('IntBounds', 'val:Int');

    # Use values that are definitely integers
    my $big = 1000000000;  # 1 billion
    my $obj = new IntBounds val => $big;
    is($obj->val, $big, 'large int works');

    $obj->val(-$big);
    is($obj->val, -$big, 'large negative int works');

    # Zero
    $obj->val(0);
    is($obj->val, 0, 'zero works');
}
# ==== Required Cannot Be Set To Undef ====

# required field cannot be set to undef via setter
{
    Object::Proto::define('RequiredNoUndef', 'name:Str:required');

    my $obj = new RequiredNoUndef name => 'initial';
    is($obj->name, 'initial', 'required field set at construction');

    eval { $obj->name(undef) };
    ok($@, 'error for setting required field to undef');
    is($obj->name, 'initial', 'value unchanged after failed set');
}
# required field cannot be passed undef in constructor
{
    Object::Proto::define('RequiredNoUndefCtor', 'title:Str:required');

    eval { new RequiredNoUndefCtor title => undef };
    ok($@, 'error for passing undef to required in constructor');
}
# required with writer cannot be set to undef
{
    Object::Proto::define('RequiredWriter', 'code:Str:required:writer(set_code)');

    my $obj = new RequiredWriter code => 'ABC';
    is($obj->code, 'ABC', 'required field set');

    eval { $obj->set_code(undef) };
    ok($@, 'writer cannot set required to undef');
    is($obj->code, 'ABC', 'value unchanged after failed write');
}
# required untyped field cannot be set to undef
{
    # Required field without a type constraint
    Object::Proto::define('RequiredUntyped', 'value:required');

    my $obj = new RequiredUntyped value => 'anything';
    is($obj->value, 'anything', 'untyped required field set');

    eval { $obj->value(undef) };
    ok($@, 'untyped required cannot be set to undef');
    is($obj->value, 'anything', 'value unchanged');
}
done_testing;
