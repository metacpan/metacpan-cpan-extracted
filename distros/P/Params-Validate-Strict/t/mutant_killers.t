#!/usr/bin/env perl
# Mutant-killing tests for 5 surviving mutants from 2026-05-25 run.
# Each subtest is designed to fail when its target mutant is applied.

use strict;
use warnings;
use Test::Most;

use Params::Validate::Strict qw(validate_strict);

################################################################
# FILE: lib/Params/Validate/Strict.pm
################################################################

# --- NUM_BOUNDARY_1159_26_> (HIGH) line 1161 in validate_strict() ---
# Source:  if(scalar(@{$args}) < $rules->{'position'}) {
# Kills:   < → <=  and  < → >=
# When array length equals position, the missing element uses the default (no error).
# Flipping to <= or >= turns the false condition true → error raised → test fails → killed.
subtest 'positional boundary: array length == position uses default, no error' => sub {
    my $r;
    lives_ok {
        $r = validate_strict(
            schema => {
                first  => { type => 'string', position => 0 },
                second => { type => 'string', position => 1, optional => 1, default => 'FALLBACK' },
            },
            input => ['x'],   # length 1 == position 1; element at index 1 is undef
        );
    } 'length == position: optional param gets default without error';
    is(ref($r), 'ARRAY', 'positional mode returns arrayref');
    is($r->[0], 'x',        'first positional value correct');
    is($r->[1], 'FALLBACK', 'default applied for element at boundary position');
};

# --- NUM_BOUNDARY_1159_26_> (HIGH) line 1161 — continued ---
# Kills:   < → >
# The boundary check is inside the $is_optional block; the array must be shorter
# than position (not just equal) for the error path to fire.
# Flipping to > turns "0 < 1 = true" into "0 > 1 = false" → no error → test fails → killed.
subtest 'positional boundary: array length 0 with optional param at position 1 raises error' => sub {
    throws_ok {
        validate_strict(
            schema => {
                first  => { type => 'string', position => 0, optional => 1 },
                second => { type => 'string', position => 1, optional => 1 },
            },
            input => [],    # length 0 < position 1 → error even for optional param
        );
    } qr/Required parameter .* is missing/i,
      'array length < position: error raised even for optional positional param';
};

# --- COND_INV_1352_8 (MEDIUM) line 1345 in validate_strict() ---
# Source:  if($custom_type->{'transform'}) {
# Mutant:  unless($custom_type->{'transform'}) {
# When transform IS set, the mutant skips it → value unchanged → matches check fails.
subtest 'custom type transform: applied before matches — value only passes after transform' => sub {
    # 'HELLO' fails /^[a-z]+$/; lc transform produces 'hello' which passes.
    # unless-mutant skips the transform → 'HELLO' still fails matches → error raised → killed.
    my $r;
    lives_ok {
        $r = validate_strict(
            schema       => { word => { type => 'lc_word' } },
            input        => { word => 'HELLO' },
            custom_types => {
                lc_word => {
                    type      => 'string',
                    transform => sub { lc $_[0] },
                    matches   => qr/^[a-z]+$/,
                },
            },
        );
    } 'transform lc applied: HELLO becomes hello and passes /^[a-z]+$/';
    is($r->{word}, 'hello', 'returned value is the transformed lowercase string');
};

# When transform is NOT set, the mutant enters the block anyway and tries to invoke
# undef as a CODE ref → "transforms must be a code ref" error → test fails → killed.
subtest 'custom type without transform: valid value accepted' => sub {
    lives_ok {
        validate_strict(
            schema       => { tag => { type => 'simple_tag' } },
            input        => { tag => 'hello' },
            custom_types => { simple_tag => { type => 'string', matches => qr/^[a-z]+$/ } },
        );
    } 'custom type with no transform key: valid value passes without error';
};

# --- COND_INV_1416_8 (MEDIUM) line 1411 in validate_strict() ---
# Source:  if($rules->{'error_msg'}) {  (inside hashref min handler)
# Mutant:  unless($rules->{'error_msg'}) {
# When error_msg IS set, mutant uses default text instead → custom pattern fails → killed.
subtest 'hashref min: custom error_msg used when provided' => sub {
    throws_ok {
        validate_strict(
            schema => { h => { type => 'hashref', min => 3, error_msg => 'Custom hashref min error' } },
            input  => { h => { a => 1 } },   # 1 key < min 3
        );
    } qr/Custom hashref min error/,
      'custom error_msg appears in error for hashref min violation';
};

# When error_msg is NOT set, mutant calls _error($logger, undef) → "Died" message,
# not the default "must contain at least" text → pattern fails → killed.
subtest 'hashref min: default error message when no error_msg set' => sub {
    throws_ok {
        validate_strict(
            schema => { h => { type => 'hashref', min => 2 } },
            input  => { h => { x => 1 } },   # 1 key < min 2
        );
    } qr/must contain at least/,
      'default "must contain at least" error for hashref min without error_msg';
};

# --- COND_INV_1453_8 (MEDIUM) line 1452 in validate_strict() ---
# Source:  if(exists($custom_types->{$type}->{'max'})) {
# Mutant:  unless(exists($custom_types->{$type}->{'max'})) {
# When custom type has max, the mutant skips the override: $type stays as the custom
# type name (not a base type) so no length branch matches → validation passes when it
# should fail → test fails → killed.
subtest 'custom type max: custom-type max overrides schema max (stricter wins)' => sub {
    # custom max=3, schema max=10; 'hello' has length 5 → custom max should fire.
    # unless-mutant: $type stays 'short_id' → no string branch → passes → killed.
    throws_ok {
        validate_strict(
            schema       => { code => { type => 'short_id', max => 10 } },
            input        => { code => 'hello' },   # length 5 > custom max 3
            custom_types => { short_id => { type => 'string', max => 3 } },
        );
    } qr/too long|no more than|must be no longer/i,
      'custom-type max=3 overrides schema max=10; length-5 string is rejected';
};

subtest 'custom type max: value within custom-type max is accepted' => sub {
    # Positive companion: 'hi' (length 2) <= custom max 3 → should pass.
    my $r;
    lives_ok {
        $r = validate_strict(
            schema       => { code => { type => 'short_id', max => 10 } },
            input        => { code => 'hi' },
            custom_types => { short_id => { type => 'string', max => 3 } },
        );
    } 'custom-type max=3; length-2 string passes';
    is($r->{code}, 'hi', 'accepted value returned unchanged');
};

# --- COND_INV_1494_8 (MEDIUM) line 1493 in validate_strict() ---
# Source:  if($rules->{'error_msg'}) {  (inside hashref max handler)
# Mutant:  unless($rules->{'error_msg'}) {
# Mirrors COND_INV_1416_8 for the max side.
subtest 'hashref max: custom error_msg used when provided' => sub {
    throws_ok {
        validate_strict(
            schema => { h => { type => 'hashref', max => 1, error_msg => 'Custom hashref max error' } },
            input  => { h => { a => 1, b => 2 } },   # 2 keys > max 1
        );
    } qr/Custom hashref max error/,
      'custom error_msg appears in error for hashref max violation';
};

subtest 'hashref max: default error message when no error_msg set' => sub {
    throws_ok {
        validate_strict(
            schema => { h => { type => 'hashref', max => 1 } },
            input  => { h => { a => 1, b => 2 } },   # 2 keys > max 1
        );
    } qr/must contain no more than/,
      'default "must contain no more than" error for hashref max without error_msg';
};

done_testing();
