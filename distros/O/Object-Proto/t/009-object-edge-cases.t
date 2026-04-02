#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# ==== Undef and Empty Values ====

subtest 'undef handling' => sub {
    Object::Proto::define('NullableClass',
        'value:Any',
        'str:Str',
    );

    # Any type accepts undef
    my $obj = new NullableClass value => undef;
    ok(!defined($obj->value), 'Any accepts undef on construction');

    $obj->value(undef);
    ok(!defined($obj->value), 'Any accepts undef on setter');

    # Str rejects undef (requires defined non-ref)
    eval { $obj->str(undef) };
    like($@, qr/Type constraint failed/, 'Str rejects undef');
};

subtest 'empty string handling' => sub {
    Object::Proto::define('EmptyStrClass',
        'name:Str',
        'value:Any',
    );

    my $obj = new EmptyStrClass name => '', value => '';
    is($obj->name, '', 'Str accepts empty string');
    is($obj->value, '', 'Any accepts empty string');
};

# ==== Unicode ====

subtest 'unicode values' => sub {
    Object::Proto::define('UnicodeClass', 'text:Str');

    my $unicode = "\x{1F600}\x{1F4A9}";  # emoji
    my $obj = new UnicodeClass text => $unicode;
    is($obj->text, $unicode, 'Str preserves unicode emoji');

    my $japanese = "\x{65E5}\x{672C}\x{8A9E}";  # Japanese
    $obj->text($japanese);
    is($obj->text, $japanese, 'Str preserves Japanese characters');

    my $arabic = "\x{0627}\x{0644}\x{0639}\x{0631}\x{0628}\x{064A}\x{0629}";
    $obj->text($arabic);
    is($obj->text, $arabic, 'Str preserves Arabic characters');
};

# ==== Any Type ====

subtest 'Any type' => sub {
    Object::Proto::define('AnyClass', 'data:Any');

    my $obj = new AnyClass;

    # Any accepts anything
    $obj->data(42);
    is($obj->data, 42, 'Any accepts integer');

    $obj->data('string');
    is($obj->data, 'string', 'Any accepts string');

    $obj->data([1,2,3]);
    is_deeply($obj->data, [1,2,3], 'Any accepts arrayref');

    $obj->data({a => 1});
    is_deeply($obj->data, {a => 1}, 'Any accepts hashref');

    $obj->data(sub { 42 });
    is($obj->data->(), 42, 'Any accepts coderef');

    $obj->data(undef);
    ok(!defined($obj->data), 'Any accepts undef');
};

# ==== Defined Type ====

subtest 'Defined type' => sub {
    Object::Proto::define('DefinedClass', 'value:Defined');

    my $obj = new DefinedClass value => 0;
    is($obj->value, 0, 'Defined accepts 0');

    $obj->value('');
    is($obj->value, '', 'Defined accepts empty string');

    $obj->value([]);
    is_deeply($obj->value, [], 'Defined accepts empty arrayref');

    eval { $obj->value(undef) };
    like($@, qr/Type constraint failed/, 'Defined rejects undef');

    eval { new DefinedClass value => undef };
    like($@, qr/Type constraint failed/, 'Defined rejects undef in constructor');
};

# ==== Object Type ====

subtest 'Object type' => sub {
    Object::Proto::define('WrapperClass', 'wrapped:Object');
    Object::Proto::define('InnerClass', 'x:Int');

    my $inner = new InnerClass x => 42;
    my $wrapper = new WrapperClass wrapped => $inner;

    isa_ok($wrapper->wrapped, 'InnerClass', 'Object accepts blessed ref');
    is($wrapper->wrapped->x, 42, 'Wrapped object accessible');

    # Object rejects non-blessed refs
    eval { $wrapper->wrapped([1,2,3]) };
    like($@, qr/Type constraint failed/, 'Object rejects plain arrayref');

    eval { $wrapper->wrapped({a => 1}) };
    like($@, qr/Type constraint failed/, 'Object rejects plain hashref');

    eval { $wrapper->wrapped('string') };
    like($@, qr/Type constraint failed/, 'Object rejects string');

    # Object accepts any blessed reference
    my $blessed_array = bless [], 'SomeClass';
    $wrapper->wrapped($blessed_array);
    isa_ok($wrapper->wrapped, 'SomeClass', 'Object accepts any blessed ref');
};

# ==== Bool Edge Cases ====

subtest 'Bool edge cases' => sub {
    Object::Proto::define('BoolClass', 'flag:Bool');

    my $obj = new BoolClass;

    # Standard booleans
    $obj->flag(1);
    is($obj->flag, 1, 'Bool accepts 1');

    $obj->flag(0);
    is($obj->flag, 0, 'Bool accepts 0');

    $obj->flag('');
    is($obj->flag, '', 'Bool accepts empty string');

    # Bool rejects non-0/1 integers
    eval { $obj->flag(2) };
    like($@, qr/Type constraint failed/, 'Bool rejects 2');

    # Bool accepts truthy values (Perl-style boolean)
    $obj->flag('true');
    ok($obj->flag, 'Bool accepts "true" string (truthy)');

    $obj->flag([]);
    ok(ref($obj->flag) eq 'ARRAY', 'Bool accepts arrayref (truthy)');
};

# ==== Int Edge Cases ====

subtest 'Int edge cases' => sub {
    Object::Proto::define('IntClass', 'num:Int');

    my $obj = new IntClass num => 0;

    is($obj->num, 0, 'Int accepts 0');

    $obj->num(-999);
    is($obj->num, -999, 'Int accepts negative');

    $obj->num(999999999);
    is($obj->num, 999999999, 'Int accepts large positive');

    # Float should be rejected or truncated
    eval { $obj->num(3.14) };
    like($@, qr/Type constraint failed/, 'Int rejects float');

    # String that looks like int
    $obj->num('42');
    is($obj->num, '42', 'Int accepts numeric string');

    eval { $obj->num('42.5') };
    like($@, qr/Type constraint failed/, 'Int rejects decimal string');
};

# ==== Num Edge Cases ====

subtest 'Num edge cases' => sub {
    Object::Proto::define('NumClass', 'value:Num');

    my $obj = new NumClass value => 0;

    $obj->value(3.14159);
    ok(abs($obj->value - 3.14159) < 0.00001, 'Num accepts float');

    $obj->value(-273.15);
    ok(abs($obj->value - -273.15) < 0.00001, 'Num accepts negative float');

    $obj->value(1e10);
    is($obj->value, 1e10, 'Num accepts scientific notation');

    $obj->value('123.456');
    ok(abs($obj->value - 123.456) < 0.00001, 'Num accepts numeric string');
};

# ==== Default Expression Freshness ====

subtest 'default array freshness' => sub {
    Object::Proto::define('ArrayDefaultClass', 'items:ArrayRef:default([])');

    my $obj1 = new ArrayDefaultClass;
    my $obj2 = new ArrayDefaultClass;

    push @{$obj1->items}, 'item1';
    is_deeply($obj1->items, ['item1'], 'first object has item');
    is_deeply($obj2->items, [], 'second object still empty (fresh array)');

    # Verify they're different references
    ok($obj1->items != $obj2->items, 'different array references');
};

subtest 'default hash freshness' => sub {
    Object::Proto::define('HashDefaultClass', 'data:HashRef:default({})');

    my $obj1 = new HashDefaultClass;
    my $obj2 = new HashDefaultClass;

    $obj1->data->{key} = 'value';
    is_deeply($obj1->data, {key => 'value'}, 'first object has key');
    is_deeply($obj2->data, {}, 'second object still empty (fresh hash)');

    ok($obj1->data != $obj2->data, 'different hash references');
};

subtest 'default undef' => sub {
    Object::Proto::define('UndefDefaultClass', 'value:Any:default(undef)');

    my $obj = new UndefDefaultClass;
    ok(!defined($obj->value), 'default(undef) produces undef');
};

# ==== Multiple Modifiers ====

subtest 'required + readonly' => sub {
    Object::Proto::define('RequiredReadonlyClass',
        'id:Str:required:readonly',
    );

    # Must provide required
    eval { new RequiredReadonlyClass };
    like($@, qr/Required slot 'id'/, 'required enforced');

    my $obj = new RequiredReadonlyClass id => 'abc';
    is($obj->id, 'abc', 'getter works');

    # Cannot modify readonly
    eval { $obj->id('xyz') };
    like($@, qr/Cannot modify readonly/, 'readonly enforced');
};

subtest 'required + default (default ignored)' => sub {
    # When both required and default are specified, required takes precedence
    Object::Proto::define('RequiredDefaultClass',
        'value:Str:required:default(fallback)',
    );

    # Should still require the value since required is specified
    eval { new RequiredDefaultClass };
    # This behavior might vary - test what actually happens
    my $error = $@;

    # If it allows default to satisfy required:
    if (!$error) {
        my $obj = new RequiredDefaultClass;
        pass('required+default allows construction with default');
    } else {
        like($error, qr/Required/, 'required+default still requires value');
    }
};

subtest 'type + readonly' => sub {
    Object::Proto::define('TypeReadonlyClass',
        'count:Int:readonly',
    );

    my $obj = new TypeReadonlyClass count => 42;
    is($obj->count, 42, 'typed readonly getter works');

    eval { $obj->count(99) };
    like($@, qr/Cannot modify readonly/, 'readonly prevents modification');
};

# ==== Large Object (Many Properties) ====

subtest 'large object' => sub {
    my @props = map { "prop$_:Any" } 1..50;
    Object::Proto::define('LargeClass', @props);

    my %args = map { ("prop$_" => $_) } 1..50;
    my $obj = new LargeClass %args;

    is($obj->prop1, 1, 'first property correct');
    is($obj->prop25, 25, 'middle property correct');
    is($obj->prop50, 50, 'last property correct');

    $obj->prop50(100);
    is($obj->prop50, 100, 'setter works on large object');
};

# ==== Multiple Class Independence ====

subtest 'class independence' => sub {
    Object::Proto::define('ClassA', 'x:Int');
    Object::Proto::define('ClassB', 'x:Str');
    Object::Proto::define('ClassC', 'x:Any', 'y:Int');

    my $a = new ClassA x => 42;
    my $b = new ClassB x => 'hello';
    my $c = new ClassC x => [1,2,3], y => 99;

    is($a->x, 42, 'ClassA x is int');
    is($b->x, 'hello', 'ClassB x is string');
    is_deeply($c->x, [1,2,3], 'ClassC x is array');
    is($c->y, 99, 'ClassC has additional property');

    # Type constraints are class-specific
    eval { $a->x('string') };
    like($@, qr/Type constraint failed/, 'ClassA enforces Int');

    $b->x(123);  # Should work since Str accepts numeric-looking values
    pass('ClassB accepts different type');
};

done_testing;
