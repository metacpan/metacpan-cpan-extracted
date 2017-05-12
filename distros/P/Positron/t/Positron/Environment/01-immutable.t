#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::Environment');
}

# non-changeable, no data

my $env;
lives_and {
    $env=Positron::Environment->new(
        undef,
        { immutable => 1 }
    );
    ok($env);
} "Constructor worked";
lives_and { ok(!defined($env->get('test'))); } "No value for random key";
dies_ok { $env->set('test', 'value') } "Immutable dies on set";

lives_and {
    $env=Positron::Environment->new({
        key1 => 'value1',
        key2 => ['value2', 'value3'],
    }, { 
        immutable => 1 
    });
    ok($env);
} "Constructor worked with data";

ok( !defined($env->get('key0')), "No value for random key");
is( $env->get('key1'), 'value1', "Scalar value retrieved");
is_deeply( $env->get('key2'), ['value2', 'value3'] , "Scalar value retrieved");

dies_ok { $env->set('key1', 'newvalue') } "Immutable dies on set";

lives_and {
    $env = Positron::Environment->new(
        "a string as data",
        { immutable => 1},
    );
    # This should always return undef
    ok( !defined($env->get('string')) );
} "Environment works with scalar data";

lives_and {
    $env = Positron::Environment->new(
        [2, 3, 5, 7, 11],
        { immutable => 1},
    );
    ok($env);
} "Constructor works with array data";
lives_and { is( $env->get(1), 3 ); } "Can access by index";
lives_and { is( $env->get('string'), 2 ); } "Can implicitly access by non-numeric index";
lives_and { is( $env->get(3.2), 7 ); } "Can implicitly access by non-integer index";
lives_and { is( $env->get(-1), 11 ); } "Can access by negative index";

done_testing();

