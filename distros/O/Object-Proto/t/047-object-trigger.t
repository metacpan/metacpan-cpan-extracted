#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# ==== Test Trigger Callbacks ====
# Triggers fire on every set operation with ($self, $new_value)
# This includes during construction!

our @trigger_log;

# Define trigger callback in appropriate package
package TriggerTest;

sub _on_name_change {
    my ($self, $new) = @_;
    push @main::trigger_log, { new => $new };
}

sub _on_score_change {
    my ($self, $new) = @_;
    push @main::trigger_log, "score:$new";
}

package main;

# Class with trigger on a slot
Object::Proto::define('TriggerTest',
    'name:Str:trigger(_on_name_change)',
    'score:Int:trigger(_on_score_change)',
    'plain',
);

# Test 1: Trigger fires during construction
@trigger_log = ();
my $obj = TriggerTest->new(name => 'Alice', score => 10);
is(scalar @trigger_log, 2, 'Triggers fired during construction (name + score)');
is($trigger_log[0]{new}, 'Alice', 'First trigger receives name value');
is($trigger_log[1], 'score:10', 'Second trigger receives score value');

# Test 2: Trigger fires on setter
@trigger_log = ();
$obj->name('Bob');
is(scalar @trigger_log, 1, 'Trigger fired once on setter');
is($trigger_log[0]{new}, 'Bob', 'Trigger receives new value');

# Test 3: Multiple triggers on different slots
@trigger_log = ();
$obj->score(20);
is(scalar @trigger_log, 1, 'Score trigger fired');
is($trigger_log[0], 'score:20', 'Score trigger has correct value');

# Test 4: No trigger on getter
@trigger_log = ();
my $val = $obj->name;
is(scalar @trigger_log, 0, 'No trigger on getter');
is($val, 'Bob', 'Getter still returns correct value');

# Test 5: Trigger not fired on unrelated slot
@trigger_log = ();
$obj->plain('whatever');
is(scalar @trigger_log, 0, 'No trigger on slot without trigger defined');

# Test 6: Trigger + type checking (type check happens before trigger)
@trigger_log = ();
eval { $obj->score('not a number') };
like($@, qr/Type constraint failed/, 'Type check still enforced with trigger');
is(scalar @trigger_log, 0, 'Trigger NOT fired when type check fails');
is($obj->score, 20, 'Value unchanged after failed type check');

# Test 7: Trigger on frozen object should fail before trigger
Object::Proto::freeze($obj);
@trigger_log = ();
eval { $obj->name('NewName') };
like($@, qr/frozen|Cannot modify/i, 'Frozen check before trigger');
is(scalar @trigger_log, 0, 'Trigger NOT fired on frozen object');

done_testing();
