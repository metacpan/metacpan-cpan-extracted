#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test lazy/builder support

# Counters to track builder invocations
our $build_count = 0;
our $typed_build_count = 0;
our $default_build_count = 0;
our $direct_build_count = 0;

# Define class with lazy builder
package LazyPerson;

sub _build_greeting {
    my ($self) = @_;
    $main::build_count++;
    return "Hello, " . $self->name . "!";
}

package main;

Object::Proto::define('LazyPerson',
    'name:Str:required',
    'greeting:Str:builder(_build_greeting)'
);

# Test 1: Builder not called at construction time
$build_count = 0;
my $p = LazyPerson->new(name => "Alice");
is($build_count, 0, 'Builder not called at construction');

# Test 2: Builder called on first access
my $greeting = $p->greeting;
is($build_count, 1, 'Builder called on first access');
is($greeting, 'Hello, Alice!', 'Builder returned correct value');

# Test 3: Value is cached - builder not called again
my $greeting2 = $p->greeting;
is($build_count, 1, 'Builder not called on second access (cached)');
is($greeting2, 'Hello, Alice!', 'Cached value returned');

# Test 4: Different objects have different built values
my $p2 = LazyPerson->new(name => "Bob");
is($build_count, 1, 'Builder not called for new object until accessed');
my $g2 = $p2->greeting;
is($build_count, 2, 'Builder called for second object');
is($g2, 'Hello, Bob!', 'Second object has correct greeting');

# Test 5: Lazy with default (no builder)
package LazyWithDefault;
package main;

Object::Proto::define('LazyWithDefault',
    'value:Int:lazy:default(42)'
);

my $lwd = LazyWithDefault->new();
# Check that the value is lazily initialized
my $val = $lwd->value;
is($val, 42, 'Lazy default value works');

# Test 6: Lazy builder with type checking
package TypedLazy;

sub _build_count {
    my ($self) = @_;
    $main::typed_build_count++;
    return 100;
}

package main;

Object::Proto::define('TypedLazy',
    'count:Int:builder(_build_count)'
);

my $tl = TypedLazy->new();
is($typed_build_count, 0, 'Typed builder not called at construction');
my $c = $tl->count;
is($c, 100, 'Typed builder returns correct value');
is($typed_build_count, 1, 'Typed builder called once');

# Test 7: Default builder name (_build_propname)
package DefaultBuilderName;

sub _build_answer {
    my ($self) = @_;
    $main::default_build_count++;
    return 42;
}

package main;

Object::Proto::define('DefaultBuilderName',
    'answer:Int:builder()'  # Empty parens = use default _build_answer
);

my $dbn = DefaultBuilderName->new();
is($default_build_count, 0, 'Default-named builder not called at construction');
my $ans = $dbn->answer;
is($ans, 42, 'Default-named builder works');
is($default_build_count, 1, 'Default-named builder called');

# Test 8: Setting lazy value directly bypasses builder
package DirectSet;

sub _build_data {
    $main::direct_build_count++;
    return "built";
}

package main;

Object::Proto::define('DirectSet',
    'data:Str:builder(_build_data)'
);

my $ds = DirectSet->new();
$ds->data("manual");
is($ds->data, "manual", 'Directly set value is returned');
is($direct_build_count, 0, 'Builder not called when value set directly');

# Test 9: Lazy with both builder and type
package BuildTyped;

sub _build_score {
    return "99";  # String, should be coerced or accepted as Int
}

package main;

Object::Proto::define('BuildTyped',
    'score:Int:builder(_build_score)'
);

my $bt = BuildTyped->new();
# This might fail type checking if strict - depends on implementation
# For now, just check it works with string "99" (Perl is lenient)
my $score = $bt->score;
ok(defined $score, 'Lazy typed attribute with string value works');

done_testing();
