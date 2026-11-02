#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 5: context propagation.
#  - The last step of a pipe inherits the calling context of the whole
#    `pipe { ... }` expression (scalar / list / void).
#  - Intermediate steps are always scalar (the topic is a single pad slot).

# --- scalar context -------------------------------------------------------

sub three_things { wantarray ? (1, 2, 3) : 'scalar' }

{
    my $s = pipe { 0 |> three_things };
    is( $s, 'scalar',
        'last step in scalar context (my $s = pipe { ... }) sees wantarray false' );
}

# --- list context ---------------------------------------------------------

{
    my @list = pipe { 0 |> three_things };
    is_deeply( \@list, [1, 2, 3],
        'last step in list context (my @l = pipe { ... }) sees wantarray true' );
}

# --- void context --------------------------------------------------------

{
    my $ctx = '';
    sub note_ctx {
        $ctx = defined(wantarray) ? (wantarray ? 'list' : 'scalar') : 'void';
        return 99;
    }

    pipe { 0 |> note_ctx };
    is( $ctx, 'void',
        'last step in void context (statement form) sees wantarray undef' );

    my $r = pipe { 0 |> note_ctx };
    is( $ctx, 'scalar',
        'after a scalar-context use, the recorded context is scalar' );
    is( $r, 99, '...and the value still flows correctly' );

    my @r = pipe { 0 |> note_ctx };
    is( $ctx, 'list',
        'after a list-context use, the recorded context is list' );
}

# --- intermediate steps are always scalar --------------------------------

sub which_ctx { wantarray ? 'L' : defined(wantarray) ? 'S' : 'V' }

{
    my @ctx;
    sub stash_ctx {
        push @ctx, defined(wantarray) ? (wantarray ? 'L' : 'S') : 'V';
        return $_[0];
    }

    # Three steps: the first two are intermediate (must be scalar),
    # the third inherits the outer context.
    my @outer = pipe { 1 |> stash_ctx |> stash_ctx |> stash_ctx };

    is( $ctx[0], 'S', 'step 1 (intermediate) is scalar' );
    is( $ctx[1], 'S', 'step 2 (intermediate) is scalar' );
    is( $ctx[2], 'L', 'step 3 (final) inherits the outer list context' );
}

done_testing;
