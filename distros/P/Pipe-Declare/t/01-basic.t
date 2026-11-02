#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 2: head + bareword steps (1, 2, 3 steps), statement and
# expression form. Each step is a bareword sub name; the topic is
# threaded as the sole argument.

sub double { $_[0] * 2 }
sub inc    { $_[0] + 1 }
sub square { $_[0] * $_[0] }

# --- expression form -------------------------------------------------------

is( (pipe { 21 |> double }),                 42, 'one step (literal head)' );
is( (pipe { 3  |> inc |> double }),           8, 'two steps' );
is( (pipe { 2  |> double |> inc |> square }), 25, 'three steps' );

# Head can be any term: a variable.
{
    my $x = 10;
    is( (pipe { $x |> inc |> double }), 22, 'variable head' );
}

# Head can be a call expression - parenthesised (the closed v0.01 head set:
# $var, literal, or (EXPR) for anything else; bareword-call head lands in
# milestone 3 with the unified term parser).
sub seed { 5 }
is( (pipe { (seed()) |> double }), 10, 'call-expression head (parenthesised)' );

# Head with parens.
is( (pipe { (1 + 2) |> double |> inc }), 7, 'parenthesised arithmetic head' );

# --- statement form --------------------------------------------------------

my $sink;
sub stash { $sink = $_[0]; $_[0] }

pipe { 100 |> stash };
is( $sink, 100, 'statement form runs for side effect' );

pipe { 7 |> inc |> stash };
is( $sink, 8, 'statement form, two steps' );

# --- inside an expression context (assigned, passed as argument) ----------

my @r;
push @r, pipe { 4 |> double };
push @r, pipe { 5 |> inc    };
is_deeply( \@r, [8, 6], 'pipe expressions used in a list' );

is( join(',', pipe { 1 |> double }, pipe { 2 |> double }),
    '2,4',
    'two pipe expressions side by side' );

# --- the topic temp does not leak as a named lexical ----------------------

{
    my $v = pipe { 9 |> inc };
    is( $v, 10, 'pipe value assigned to outer lexical' );
    # If the hidden $_Pipe_Declare_topic_N leaked, naming it here would
    # work; we just don't *test* that because the slot's name is an
    # implementation detail. The point is the construct doesn't
    # introduce any user-visible name.
}

# --- `our` variables resolve to the package scalar ------------------------

{
    package Elsewhere;
    our $seed = 20;
    our $step = sub { $_[0] + 2 };
    package main;
    our $seed = 30;
    is( (pipe { $Elsewhere::seed |> double }), 40, 'qualified our variable head' );
    is( (pipe { $seed |> double }),            60, 'our variable head' );
    is( (pipe { 1 |> $Elsewhere::step }),       3, 'our variable as a coderef step' );
}

done_testing;
