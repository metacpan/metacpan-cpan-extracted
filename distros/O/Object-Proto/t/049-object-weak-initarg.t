#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(isweak weaken);

use Object::Proto;

# ==== init_arg Tests ====

# init_arg basic usage
{
    Object::Proto::define('InitArgBasic',
        'internal_name:Str:arg(_public_name)',
    );

    # Constructor should use init_arg name
    my $obj = new InitArgBasic _public_name => 'test';
    is($obj->internal_name, 'test', 'value set via init_arg');
    
    # Accessor uses property name
    $obj->internal_name('changed');
    is($obj->internal_name, 'changed', 'accessor uses property name');
}
# init_arg does not accept property name
{
    Object::Proto::define('InitArgStrict',
        'secret:Str:arg(public)',
    );

    # Property name should NOT work in constructor
    my $obj = new InitArgStrict public => 'value';
    is($obj->secret, 'value', 'init_arg name works');
    
    my $obj2 = new InitArgStrict secret => 'ignored';
    ok(!defined($obj2->secret) || $obj2->secret eq '', 'original property name does not work in constructor');
}
# init_arg with types
{
    Object::Proto::define('InitArgTyped',
        'count:Int:arg(_count)',
    );

    my $obj = new InitArgTyped _count => 42;
    is($obj->count, 42, 'typed init_arg works');

    eval { new InitArgTyped _count => 'not a number' };
    like($@, qr/Type constraint failed/i, 'type constraint enforced with init_arg');
}
# init_arg with required
{
    Object::Proto::define('InitArgRequired',
        'name:Str:required:arg(_name)',
    );

    eval { new InitArgRequired };
    like($@, qr/Required slot/i, 'required still enforced with init_arg');

    my $obj = new InitArgRequired _name => 'Alice';
    is($obj->name, 'Alice', 'required init_arg works when provided');
}
# init_arg with default
{
    Object::Proto::define('InitArgDefault',
        'value:Str:default(fallback):arg(_value)',
    );

    my $obj1 = new InitArgDefault;
    is($obj1->value, 'fallback', 'default used when init_arg not provided');

    my $obj2 = new InitArgDefault _value => 'override';
    is($obj2->value, 'override', 'init_arg overrides default');
}
# init_arg introspection
{
    Object::Proto::define('InitArgIntrospect',
        'attr:Str:arg(constructor_name)',
    );

    my $info = Object::Proto::slot_info('InitArgIntrospect', 'attr');
    is($info->{init_arg}, 'constructor_name', 'slot_info returns init_arg');
    is($info->{name}, 'attr', 'slot_info returns property name');
}
# ==== weak Tests ====

# weak basic usage
{
    Object::Proto::define('WeakBasic',
        'parent:Object:weak',
    );

    my $target = bless {}, 'Target';
    my $obj = new WeakBasic parent => $target;
    
    # Check weak ref via Scalar::Util
    ok(isweak($obj->[1]), 'reference is weakened in constructor');
    is($obj->parent, $target, 'weak ref still accessible');
}
# weak ref clears when target destroyed
{
    Object::Proto::define('WeakClear',
        'ref:Object:weak',
    );

    my $obj;
    {
        my $target = bless {}, 'TempTarget';
        $obj = new WeakClear ref => $target;
        ok(defined($obj->ref), 'weak ref exists while target alive');
    }
    # Target is now out of scope
    ok(!defined($obj->ref), 'weak ref becomes undef when target destroyed');
}
# weak via setter
{
    Object::Proto::define('WeakSetter',
        'link:Object:weak',
    );

    my $obj = new WeakSetter;
    my $target = bless {}, 'SetterTarget';
    
    $obj->link($target);
    ok(isweak($obj->[1]), 'setter weakens reference');
    is($obj->link, $target, 'weak ref accessible after set');
}
# weak with writer
{
    Object::Proto::define('WeakWriter',
        'ptr:Object:weak:writer(set_ptr)',
    );

    my $obj = new WeakWriter;
    my $target = bless {}, 'WriterTarget';
    
    $obj->set_ptr($target);
    ok(isweak($obj->[1]), 'writer weakens reference');
    is($obj->ptr, $target, 'weak ref accessible via reader');
}
# weak introspection
{
    Object::Proto::define('WeakIntrospect',
        'ref:Object:weak',
    );

    my $info = Object::Proto::slot_info('WeakIntrospect', 'ref');
    ok($info->{is_weak}, 'slot_info shows is_weak');
}
# weak does not affect non-references
{
    Object::Proto::define('WeakNonRef',
        'val:Str:weak',  # weak on non-ref is harmless
    );

    my $obj = new WeakNonRef val => 'string';
    is($obj->val, 'string', 'non-ref stored normally even with weak');
}
# ==== Combined Tests ====

# weak with init_arg
{
    Object::Proto::define('WeakInitArg',
        'internal:Object:weak:arg(external)',
    );

    my $target = bless {}, 'CombinedTarget';
    my $obj = new WeakInitArg external => $target;
    
    ok(isweak($obj->[1]), 'weak works with init_arg');
    is($obj->internal, $target, 'accessor returns weakened value');
}
# init_arg with inheritance
{
    Object::Proto::define('InitArgParent',
        'base:Str:arg(_base)',
    );
    
    Object::Proto::define('InitArgChild',
        extends => 'InitArgParent',
        'child_val:Str:arg(_child)',
    );

    my $obj = new InitArgChild _base => 'from_parent', _child => 'from_child';
    is($obj->base, 'from_parent', 'inherited init_arg works');
    is($obj->child_val, 'from_child', 'child init_arg works');
}
done_testing;
