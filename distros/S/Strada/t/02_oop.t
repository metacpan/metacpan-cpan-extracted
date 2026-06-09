#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch";

BEGIN { use_ok('Strada') }

# Uses the current example library (single-underscore C naming, built from
# example/math_lib.strada). Build it with:
#   cd example && ../../../strada --shared math_lib.strada
my $lib_path = "$Bin/../example/math_lib.so";
unless (-f $lib_path) {
    plan skip_all =>
        "example/math_lib.so not built " .
        "(cd example && ../../../strada --shared math_lib.strada)";
}

my $lib = Strada::Library->new($lib_path);

# A Strada object returned from the runtime should come back as a blessed
# Strada::Object wrapper, not a flattened hashref.
subtest 'construction and class' => sub {
    my $c = $lib->new_object('Counter', 'count', 10, 'name', 'hits');
    isa_ok($c, 'Strada::Object', 'constructed object is a Strada::Object');
    is($c->strada_class, 'Counter', 'strada_class() reports the Strada package');
    ok($c->isa('Counter'), 'isa("Counter") dispatches through the runtime');
    ok(!$c->isa('Nope'),   'isa("Nope") is false');
};

# Constructor arguments (named pairs) must be applied — they are packed into the
# variadic args array, exercising the variadic calling convention.
subtest 'constructor arguments are applied' => sub {
    my $c = $lib->new_object('Counter', 'count', 10, 'name', 'hits');
    is($c->describe, 'hits=10', 'rw + ro attributes set from constructor args');

    my $d = $lib->new_object('Counter');   # all defaults
    is($d->describe, 'counter=0', 'defaults applied when no args given');
};

# Method dispatch: no-arg, with-arg, and string-returning.
subtest 'method dispatch' => sub {
    my $c = $lib->new_object('Counter', 'count', 10, 'name', 'hits');
    is($c->increment, 11, 'no-arg method mutates state and returns');
    is($c->add(5),    16, 'method with an integer argument');
    is($c->describe,  'hits=16', 'method returning a string built from attributes');
};

# Each object is independent.
subtest 'object independence' => sub {
    my $a = $lib->new_object('Counter', 'count', 100);
    my $b = $lib->new_object('Counter', 'count', 1);
    $a->increment;
    is($a->describe, 'counter=101', 'a advanced');
    is($b->describe, 'counter=1',   'b unaffected by a');
};

# Round-trip: pass one Strada::Object as an argument to another object's method
# (the sv_to_strada Strada::Object passthrough).
subtest 'object passed back into the runtime' => sub {
    my $a = $lib->new_object('Counter', 'count', 40);
    my $b = $lib->new_object('Counter', 'count', 2);
    is($a->merge($b), 42, 'merge(other) reads the passed objects attributes');
    is($b->describe, 'counter=2', 'the passed object is unchanged');
};

$lib->unload();
done_testing();
