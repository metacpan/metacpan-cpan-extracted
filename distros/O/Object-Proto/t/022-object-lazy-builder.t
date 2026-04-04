#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test builder (eager) and lazy builder support

# Counters to track builder invocations
our $eager_build_count = 0;
our $lazy_build_count = 0;
our $typed_eager_count = 0;
our $typed_lazy_count = 0;
our $default_build_count = 0;

# === Test 1: Eager builder (called at construction) ===
package EagerPerson;

sub _build_greeting {
    my ($self) = @_;
    $main::eager_build_count++;
    return "Hello, " . $self->name . "!";
}

package main;

Object::Proto::define('EagerPerson',
    'name:Str:required',
    'greeting:Str:builder(_build_greeting)'  # No :lazy, so called at new()
);

$eager_build_count = 0;
my $ep = EagerPerson->new(name => "Alice");
is($eager_build_count, 1, 'Eager builder called at construction');
is($ep->greeting, 'Hello, Alice!', 'Eager builder set correct value');

# Second access doesn't call builder again
my $g2 = $ep->greeting;
is($eager_build_count, 1, 'Builder not called on subsequent access');

# === Test 2: Lazy builder (called on first access) ===
package LazyPerson;

sub _build_greeting {
    my ($self) = @_;
    $main::lazy_build_count++;
    return "Hi, " . $self->name . "!";
}

package main;

Object::Proto::define('LazyPerson',
    'name:Str:required',
    'greeting:Str:lazy:builder(_build_greeting)'  # :lazy = deferred to first access
);

$lazy_build_count = 0;
my $lp = LazyPerson->new(name => "Bob");
is($lazy_build_count, 0, 'Lazy builder NOT called at construction');

# First access triggers builder
my $lazy_greeting = $lp->greeting;
is($lazy_build_count, 1, 'Lazy builder called on first access');
is($lazy_greeting, 'Hi, Bob!', 'Lazy builder returned correct value');

# Value is cached
my $lazy_greeting2 = $lp->greeting;
is($lazy_build_count, 1, 'Lazy builder not called on second access (cached)');

# === Test 3: Different objects get their own built values ===
my $lp2 = LazyPerson->new(name => "Carol");
is($lazy_build_count, 1, 'Lazy builder not called for new object until accessed');
my $g3 = $lp2->greeting;
is($lazy_build_count, 2, 'Lazy builder called for second object');
is($g3, 'Hi, Carol!', 'Second object has correct greeting');

# === Test 4: Lazy with default (no builder) ===
Object::Proto::define('LazyWithDefault',
    'value:Int:lazy:default(42)'
);

my $lwd = LazyWithDefault->new();
my $val = $lwd->value;
is($val, 42, 'Lazy default value works');

# === Test 5: Eager builder with type checking ===
package TypedEager;

sub _build_count {
    my ($self) = @_;
    $main::typed_eager_count++;
    return 100;
}

package main;

Object::Proto::define('TypedEager',
    'count:Int:builder(_build_count)'  # Eager, typed
);

$typed_eager_count = 0;
my $te = TypedEager->new();
is($typed_eager_count, 1, 'Typed eager builder called at construction');
is($te->count, 100, 'Typed eager builder returns correct value');

# === Test 6: Lazy builder with type checking ===
package TypedLazy;

sub _build_score {
    my ($self) = @_;
    $main::typed_lazy_count++;
    return 200;
}

package main;

Object::Proto::define('TypedLazy',
    'score:Int:lazy:builder(_build_score)'  # Lazy, typed
);

$typed_lazy_count = 0;
my $tl = TypedLazy->new();
is($typed_lazy_count, 0, 'Typed lazy builder NOT called at construction');
my $s = $tl->score;
is($s, 200, 'Typed lazy builder returns correct value');
is($typed_lazy_count, 1, 'Typed lazy builder called once');

# === Test 7: Default builder name (_build_propname) ===
package DefaultBuilderName;

sub _build_answer {
    my ($self) = @_;
    $main::default_build_count++;
    return 42;
}

package main;

Object::Proto::define('DefaultBuilderName',
    'answer:Int:builder()'  # Empty parens = use default _build_answer, eager
);

$default_build_count = 0;
my $dbn = DefaultBuilderName->new();
is($default_build_count, 1, 'Default-named eager builder called at construction');
is($dbn->answer, 42, 'Default-named builder works');

# === Test 8: Providing value bypasses eager builder ===
package DirectSet;
our $direct_build_count = 0;

sub _build_data {
    $DirectSet::direct_build_count++;
    return "built";
}

package main;

Object::Proto::define('DirectSet',
    'data:Str:builder(_build_data)'
);

$DirectSet::direct_build_count = 0;
my $ds = DirectSet->new(data => "manual");  # Provide value directly
is($ds->data, "manual", 'Directly provided value is used');
is($DirectSet::direct_build_count, 0, 'Builder not called when value provided');

# === Test 9: Providing value bypasses lazy builder ===
package DirectSetLazy;
our $direct_lazy_count = 0;

sub _build_info {
    $DirectSetLazy::direct_lazy_count++;
    return "lazy-built";
}

package main;

Object::Proto::define('DirectSetLazy',
    'info:Str:lazy:builder(_build_info)'
);

$DirectSetLazy::direct_lazy_count = 0;
my $dsl = DirectSetLazy->new(info => "provided");
is($dsl->info, "provided", 'Directly provided value used (lazy)');
is($DirectSetLazy::direct_lazy_count, 0, 'Lazy builder not called when value provided');

# === Test 10: Builder order reversed (:builder:lazy same as :lazy:builder) ===
package BuilderOrderTest;
our $order_count = 0;

sub _build_val {
    $BuilderOrderTest::order_count++;
    return "ordered";
}

package main;

Object::Proto::define('BuilderOrderTest',
    'val:Str:builder(_build_val):lazy'  # :builder before :lazy
);

$BuilderOrderTest::order_count = 0;
my $bot = BuilderOrderTest->new();
is($BuilderOrderTest::order_count, 0, 'Builder with trailing :lazy is lazy');
$bot->val;
is($BuilderOrderTest::order_count, 1, 'Builder called on access');

# === Test 11: Eager builder with coercion ===
package CoerceEager;

sub _build_amount {
    return "99";  # String that should work with Int
}

package main;

Object::Proto::define('CoerceEager',
    'amount:Int:builder(_build_amount)'
);

my $ce = CoerceEager->new();
is($ce->amount, 99, 'Eager builder with string coerced to Int');

done_testing();
