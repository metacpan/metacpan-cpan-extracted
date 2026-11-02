#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

# Milestone 6: the `pipe` keyword is recognised ONLY where
# $^H{'Pipe::Declare'} is set, and that hint is itself lexical.
#
# `use Pipe::Declare;` sets the hint at COMPILE time for the enclosing
# block; `no Pipe::Declare;` clears it; after the block ends the hint is
# gone again and `pipe` reverts to CORE::pipe.

# --- top of file: pragma not in scope -------------------------------------
{
    my $r = eval { pipe(my $rh, my $wh) };
    ok( defined $r, 'CORE::pipe at top of file (no pragma)' )
        or diag $@;
}

# --- inside a block that `use`s the pragma --------------------------------
{
    use Pipe::Declare;
    is( (pipe { 5 |> sub { $_[0] * 2 } }), 10,
        'pipe { ... } recognised after `use Pipe::Declare` in this block' );
}

# --- after the block: pragma scope is gone --------------------------------
{
    my $r = eval { pipe(my $rh, my $wh) };
    ok( defined $r, 'CORE::pipe after the `use` block ends' )
        or diag $@;
}

# --- nested: use / no / use round-trip -----------------------------------
{
    use Pipe::Declare;
    is( (pipe { 1 |> sub { $_[0] + 1 } }), 2, 'pipe { } in outer use scope' );
    {
        no Pipe::Declare;
        my $r = eval { pipe(my $rh, my $wh) };
        ok( defined $r, '`no Pipe::Declare` inside `use` restores CORE::pipe' )
            or diag $@;
    }
    is( (pipe { 10 |> sub { $_[0] - 1 } }), 9,
        'after the inner `no` block ends, pipe { } is back' );
}

# --- a sub compiled inside the pragma keeps the pipe forever --------------
# Because pipe { ... } is parsed at compile time and lowered to a plain
# optree, the resulting CV doesn't care whether the pragma is in scope at
# CALL time - the parse already happened.
{
    use Pipe::Declare;
    sub compiled_pipe { pipe { 3 |> sub { $_[0] * 4 } } }
}

{
    # No pragma here at all.
    is( compiled_pipe(), 12,
        'a sub that uses pipe { } at compile time stays callable from any scope' );
}

# --- compiling pipe { } outside the pragma scope fails --------------------
{
    my $ok = eval q{
        my $x = pipe { 1 |> sub { $_[0] + 1 } };
        1;
    };
    ok( !$ok, 'pipe { ... } in an eval without `use` does not compile' );
}

done_testing;
