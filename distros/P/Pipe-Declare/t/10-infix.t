use strict;
use warnings;
use Test::More;

# The global infix `|>` operator needs PL_infix_plugin which landed in
# 5.37.7 and stabilised in 5.38.0. On older perls the block form
# `pipe { ... }` is still the only way to use Pipe::Declare.
BEGIN {
    if ($] < 5.038) {
        plan skip_all => "global infix |> requires perl 5.38+";
    }
}

use Pipe::Declare;

# ---- helpers --------------------------------------------------------------
sub add1     { $_[0] + 1 }
sub double   { $_[0] * 2 }
sub join_ws  { join(' ', @_) }
sub sum      { my $s = 0; $s += $_ for @_; $s }

package Greeter;
sub new   { bless { name => $_[1] }, $_[0] }
sub hello { "hello, $_[0]->{name}" }
sub greet { "$_[1] $_[0]->{name}" }
sub tag   { "[$_[1]] $_[2] $_[0]->{name}" }   # ($self, $first, $second)
package main;

# ---- 1. bareword call, no args -------------------------------------------
{
    my $r = 5 |> add1;
    is($r, 6, "infix: \$x |> bareword runs the sub on \$x");
}

# ---- 2. bareword call WITH args (LHS prepended) --------------------------
{
    my $r = 10 |> join_ws('plus', 'one');
    is($r, "10 plus one", "infix: LHS becomes the first positional arg");
}

# ---- 3. left-associative chaining ----------------------------------------
{
    my $r = 3 |> add1 |> double |> add1;
    is($r, 9, "infix: |> chains left-to-right: ((3+1)*2)+1 = 9");
}

# ---- 4. coderef in a scalar ----------------------------------------------
{
    my $cv = sub { $_[0] * 100 };
    my $r  = 4 |> $cv;
    is($r, 400, "infix: \$x |> \$cv calls coderef with \$x");
}

# ---- 5. \&named -----------------------------------------------------------
{
    my $r = 7 |> \&double;
    is($r, 14, "infix: \$x |> \\&name calls referenced sub");
}

# ---- 6. anon sub ----------------------------------------------------------
{
    my $r = 11 |> sub { $_[0] + 100 };
    is($r, 111, "infix: anon sub on RHS gets LHS as its arg");
}

# ---- 7. method call, no args ---------------------------------------------
{
    my $g = Greeter->new("world");
    # `Ignored |> $g->hello`: hello() ignores any args, so the LHS just
    # gets spliced in as the first positional and silently discarded.
    # This confirms the method-call shape is being detected (no parse
    # error, no runtime "Can't use string as subroutine ref").
    my $r = "ignored" |> $g->hello;
    is($r, "hello, world", "infix: method-call RHS, no explicit args");
}

# ---- 8. method call WITH args (LHS inserted after invocant) --------------
{
    my $g = Greeter->new("alice");
    my $r = "[!]" |> $g->tag("greetings");
    # tag($self, $first, $second) -> $self->tag("[!]", "greetings")
    # ...wait: invocant=$g, explicit args=("greetings"). Insert LHS after
    # invocant -> $g->tag("[!]", "greetings"). $self=$g, $first="[!]",
    # $second="greetings".
    is($r, "[[!]] greetings alice",
       "infix: method call - LHS goes after invocant, before explicit args");
}

# ---- 9. precedence: |> is LOWER than arithmetic --------------------------
{
    my $r = 5 + 1 |> double;
    is($r, 12, "infix: \$x + 1 |> f parses as (\$x + 1) |> f = 12");
}

# ---- 10. precedence: |> is LOWER than '=' --------------------------------
{
    my $r = 5 |> double;
    is($r, 10, "infix: my \$r = \$x |> f assigns the piped result");
}

# ---- 11. precedence: same as 'or' (left-assoc, very loose) ---------------
{
    # `1 |> add1 or DIE` should parse as `(1 |> add1) or DIE`. Since
    # the pipe yields 2 (truthy), `or` short-circuits and DIE never runs.
    my $reached_or = 0;
    my $r = 1 |> add1 or $reached_or = 1;
    is($r,          2, "infix: \$x |> f or DEFAULT - pipe binds first");
    is($reached_or, 0, "infix: short-circuits via 'or' as expected");
}

# ---- 12. piping an arrayref into a regular sub ---------------------------
# The block-form `map { B }` / `grep { B }` / `tap { B }` steps are
# specific to `pipe { ... }`. The infix form is for value pipelines.
# An arrayref LHS is passed as ONE arg (the ref) - the standard idiom
# for sending a collection through a pipeline.
#
# NOTE: perl builtins (`ref`, `length`, `defined`, ...) don't parse as
# OP_ENTERSUB; they're dedicated ops. So `$x |> ref` falls into the
# coderef path and fails at runtime. Wrap them in an anon sub instead:
{
    my $count = [1, 2, 3] |> sub { my $aref = shift; scalar @$aref };
    is($count, 3, "infix: arrayref LHS feeds an anon sub that derefs");

    my $j = [qw/a b c/] |> sub { join(',', @{ $_[0] }) };
    is($j, "a,b,c", "infix: arrayref through join via an anon sub");
}

# ---- 13. scope: |> outside `use Pipe::Declare` is a parse error ----------
{
    my $err;
    {
        local $@;
        eval q{
            no Pipe::Declare;
            my $x = 5 |> double;
            1;
        } or $err = $@;
    }
    ok(defined $err && length $err,
       "infix: |> outside the pragma is a syntax error");
}

# ---- 14. mixed: block-form `pipe { }` and infix `|>` coexist -------------
{
    my $r = pipe { 5 |> add1 |> double };
    is($r, 12, "infix |> works INSIDE a pipe { } block too");
}

# ---- 15. chain a method into a regular sub -------------------------------
# (perl builtins like `length` don't parse as OP_ENTERSUB - see test 12
#  for the workaround. Here we pipe into a real sub.)
sub mylen { length $_[0] }
{
    my $g = Greeter->new("bob");
    my $r = $g->hello |> mylen;
    is($r, length("hello, bob"),
       "infix: chain a method's return value into a regular sub");
}

done_testing();
