#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 3 / call-step: bareword call with arglist, with optional `_`
# placeholder for the topic position.

sub add  { $_[0] + $_[1] }
sub mul  { $_[0] * $_[1] }
sub max3 { my @s = sort { $b <=> $a } @_; $s[0] }
sub join3 { join '|', @_ }

# --- no placeholder: topic is prepended to the arglist --------------------

is( (pipe { 5 |> add(3) }),           8, 'add(3): topic prepended -> add(5, 3)' );
is( (pipe { 5 |> add(3) |> mul(2) }), 16, 'two arg-steps chain through topic' );
is( (pipe { 1 |> join3(2, 3) }),  '1|2|3', 'three positional args, topic first' );

# --- `_` placeholder: topic woven in at every occurrence ------------------

is( (pipe { 7 |> max3(_, 10, 3) }),     10, '_ in first position' );
is( (pipe { 7 |> max3(10, _, 3) }),     10, '_ in second position' );
is( (pipe { 7 |> max3(10, 3, _) }),     10, '_ in last position' );

is( (pipe { 5 |> join3(_, 9, _) }),  '5|9|5', 'multiple _ all see the same topic' );
is( (pipe { 5 |> join3(_, _, _) }),  '5|5|5', 'three _ all see the same topic' );

# --- a multi-_ step spills the topic in place ------------------------------

{
    my $calls = 0;
    sub counted { $calls++; $_[0] + 1 }
    sub len     { length $_[0] }
    my $r = pipe { 1 |> counted |> join3(_, 0, _) |> len };
    is( $r, 5,     'multi-_ step mid-pipeline feeds the next step' );
    is( $calls, 1, 'the step before a multi-_ step ran once' );
}

{
    my $r = pipe { 2 |> mul(_, _) |> add(_, _) |> mul(_, _) };
    is( $r, 64, 'three multi-_ steps in a row' );
}

{
    my $n = 9;
    is( (pipe { 5 |> join3(_, $n + 1, _) }), '5|10|5', 'other args beside two _' );
}

{
    my @ctx;
    sub note_ctx_once { push @ctx, wantarray ? 'L' : 'S'; $_[0] }
    pipe { 3 |> note_ctx_once |> add(_, _) };
    is_deeply( \@ctx, ['S'], 'the step feeding a multi-_ step runs in scalar context' );
}

{
    sub both { @_ }
    my @r = pipe { 4 |> both(_, _) };
    is_deeply( \@r, [4, 4], 'a multi-_ final step inherits list context' );
}

{
    my @got;
    for my $i (1 .. 3) {
        push @got, pipe { $i |> add(_, _) };
    }
    is_deeply( \@got, [2, 4, 6], 'a multi-_ pipe in a loop body' );
}

{
    sub pair_refs { [ $_[0], $_[1] ] }
    my $r = pipe { [1, 2] |> map { $_ * 3 } |> pair_refs(_, _) |> map { scalar @$_ } };
    is_deeply( $r, [2, 2], 'block steps either side of a multi-_ step' );
}

# --- empty arglist: topic only --------------------------------------------

sub triple { $_[0] * 3 }
is( (pipe { 4 |> triple() }), 12, 'empty arglist == bareword nullary' );

# --- qualified bareword ---------------------------------------------------

package Foo::Bar;
sub quad { $_[0] * 4 }
sub seven { 7 }
sub clamp { my ($x, $lo, $hi) = @_; $x < $lo ? $lo : $x > $hi ? $hi : $x }
package main;

is( (pipe { 5 |> Foo::Bar::quad }),         20, 'qualified bareword, nullary' );
is( (pipe { 5 |> Foo::Bar::quad() }),       20, 'qualified bareword, empty args' );
is( (pipe { 5 |> Foo::Bar::clamp(0, 10) }),  5, 'qualified bareword + args, topic first' );
is( (pipe { -5 |> Foo::Bar::clamp(0, 10) }), 0, 'clamp negative -> 0' );
is( (pipe { 15 |> Foo::Bar::clamp(_, 0, 10) }), 10, 'qualified + _ placeholder' );

# --- args carry arbitrary expressions -------------------------------------

is( (pipe { 1 |> add(2 + 3) }),     6, 'arg can be an arithmetic expression' );
is( (pipe { 1 |> add(add(2, 3)) }), 6, 'arg can itself be a call' );

{
    my $n = 4;
    is( (pipe { 1 |> add($n) }), 5, 'arg can be a variable' );
}

# --- trailing comma allowed in arglist ------------------------------------

is( (pipe { 1 |> join3(2, 3,) }), '1|2|3', 'trailing comma in arglist is fine' );

done_testing;
