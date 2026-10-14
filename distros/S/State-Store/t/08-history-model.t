#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use State::Store;

# Seeded random changes, undos and redos against a model in plain Perl: a
# list of what is behind, a list of what is ahead, and the value.

srand(20261014);

my $s = State::Store->new(0);
my (@past, @future);
my $value = 0;
my ($bad, $checks) = (0, 0);
my $next = 1;

for my $step (1 .. 50_000) {
    my $r = rand;
    if ($r < 0.40) {
        my $new = rand() < 0.1 ? $value : $next++;
        $s->set($new);
        if ($new ne $value) { push @past, $value; @future = (); $value = $new }
    }
    elsif ($r < 0.45) {
        my $add = int rand 3;
        $s->swap(sub { $_[0] + $add });
        my $new = $value + $add;
        if ($new != $value) { push @past, $value; @future = (); $value = $new }
    }
    elsif ($r < 0.70) {
        my $n = rand() < 0.7 ? 1 : int rand 6;
        my $took = $n == 1 && rand() < 0.5 ? $s->undo : $s->undo($n);
        my $want = $n < @past ? $n : @past;
        $bad++, diag("step $step: undo($n) took $took, wanted $want") if $took != $want;
        for (1 .. $want) { push @future, $value; $value = pop @past }
    }
    elsif ($r < 0.95) {
        my $n = rand() < 0.7 ? 1 : int rand 6;
        my $took = $s->redo($n);
        my $want = $n < @future ? $n : @future;
        $bad++, diag("step $step: redo($n) took $took, wanted $want") if $took != $want;
        for (1 .. $want) { push @past, $value; $value = pop @future }
    }
    elsif (rand() < 0.2) {
        $s->clear_history;
        @past = @future = ();
    }

    $bad++, diag("step $step: value " . $s->current . ", wanted $value") if $s->current != $value;
    next if $step % 100;
    $checks++;
    if ($s->undo_count != @past || $s->redo_count != @future) {
        $bad++;
        diag("step $step: counts " . $s->undo_count . '/' . $s->redo_count . ', wanted ' . @past . '/' . @future);
    }
    $bad++, diag("step $step: _check " . State::Store::_check($s)) if State::Store::_check($s);
    next if $step % 1000;
    my ($p, $f) = State::Store::_stacks($s);
    $bad++, diag("step $step: past differs") if "@$p" ne "@past";
    $bad++, diag("step $step: future differs") if "@$f" ne "@future";
}

is($bad, 0, '50,000 steps agree with the model throughout');
is($checks, 500, 'the counts and the stacks\' shape checked 500 times');

done_testing;
