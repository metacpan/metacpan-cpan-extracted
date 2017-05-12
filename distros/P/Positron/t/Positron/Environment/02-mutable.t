#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::Environment');
}

# changeable, no data

my $env;
lives_and {
    $env=Positron::Environment->new();
    ok($env);
} "Constructor worked";
lives_and { ok(!defined($env->get('test'))); } "No value for random key";
lives_ok { $env->set('test', 'value') } "Mutable lives on set";

# changeable, with data

lives_and {
    $env=Positron::Environment->new({
        key1 => 'value1',
        key2 => ['value2', 'value3'],
    });
    ok($env);
} "Constructor worked with data";

ok( !defined($env->get('key0')), "No value for random key");
is( $env->get('key1'), 'value1', "Scalar value retrieved");
is_deeply( $env->get('key2'), ['value2', 'value3'] , "Scalar value retrieved");

lives_ok { $env->set('key1', 'newvalue') } "Immutable lives on set";
is( $env->get('key1'), 'newvalue', "New scalar value retrieved");

lives_and {
    $env = Positron::Environment->new(
        "a string as data",
    );
    $env->set('string', 'new value');
    is($env->{'data'}, 'a string as data');
} "No change when setting on a string environment";

lives_and {
    $env = Positron::Environment->new(
        [2, 3, 5, 7, 11],
    );
    ok($env);
} "Constructor works with array data";
lives_and { $env->set(1, 13); is_deeply($env->{'data'}, [2, 13, 5, 7, 11]) } "Can set by index";
lives_and { $env->set('string', 13); is_deeply($env->{'data'}, [13, 13, 5, 7, 11]) } "Can implicitly set by non-numeric index";
lives_and { $env->set(3.2, 17); is_deeply($env->{'data'}, [13, 13, 5, 17, 11]) } "Can set by non-integer index";
lives_and { $env->set(-1, 19); is_deeply($env->{'data'}, [13, 13, 5, 17, 19]) } "Can set by negative index";
done_testing();

