#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Pipe::Declare;

# Milestone 4: block steps map / grep / tap.
#
# Lowering:  |> map  { B } -> [ map  { B } @$topic ]
#            |> grep { B } -> [ grep { B } @$topic ]
#            |> tap  { B } -> do { my $t = $topic; for ($t) { B } $t }
#
# map/grep treat the topic as an arrayref and yield a fresh arrayref;
# consecutive map/grep steps fuse into one list expression. tap aliases
# $_ to a private copy of the topic inside B and yields that copy.

# --- map ------------------------------------------------------------------

{
    my $r = pipe { [1, 2, 3, 4] |> map { $_ * 2 } };
    is_deeply( $r, [2, 4, 6, 8], 'map { $_ * 2 } doubles every element' );
}

{
    my $r = pipe { [qw/a b c/] |> map { uc $_ } };
    is_deeply( $r, [qw/A B C/], 'map { uc $_ } uppercases' );
}

# --- grep -----------------------------------------------------------------

{
    my $r = pipe { [1..10] |> grep { $_ % 2 == 0 } };
    is_deeply( $r, [2, 4, 6, 8, 10], 'grep { $_ % 2 == 0 } keeps evens' );
}

{
    my $r = pipe { [qw/apple banana cherry date/] |> grep { length($_) > 4 } };
    is_deeply( $r, [qw/apple banana cherry/], 'grep by length' );
}

# --- tap ------------------------------------------------------------------

{
    my @seen;
    my $r = pipe { 42 |> tap { push @seen, $_ } };
    is( $r, 42,            'tap yields the topic unchanged' );
    is_deeply( \@seen, [42], 'tap block ran with $_ aliased to topic' );
}

# tap can be sprinkled mid-pipeline without disturbing values
{
    my @trace;
    sub double { $_[0] * 2 }
    sub inc    { $_[0] + 1 }
    my $r = pipe {
        3
            |> double
            |> tap { push @trace, "after double: $_" }
            |> inc
            |> tap { push @trace, "after inc: $_" }
    };
    is( $r, 7, 'tap does not alter the topic' );
    is_deeply(
        \@trace,
        ['after double: 6', 'after inc: 7'],
        'two tap blocks captured the intermediate topics',
    );
}

# --- map |> grep |> a count step --------------------------------------------

{
    sub count_aref { scalar @{ $_[0] } }
    my $r = pipe {
        [1..10]
            |> map  { $_ * $_ }
            |> grep { $_ > 20 }
            |> count_aref
    };
    # squares > 20 from 1..10 are 25, 36, 49, 64, 81, 100 -> 6
    is( $r, 6, 'map |> grep |> bareword count: end-to-end arrayref flow' );
}

# --- map block can refer to outer lexicals (closure) ----------------------

{
    my $factor = 10;
    my $r = pipe { [1, 2, 3] |> map { $_ * $factor } };
    is_deeply( $r, [10, 20, 30], 'map block closes over outer $factor' );
}

# --- chained map: arrayref in, arrayref out, arrayref in again ------------

{
    my $r = pipe {
        [1, 2, 3]
            |> map  { $_ + 1 }     # [2,3,4]
            |> map  { $_ * 10 }    # [20,30,40]
            |> grep { $_ > 25 }    # [30,40]
    };
    is_deeply( $r, [30, 40], 'two maps and a grep chain through arrayrefs' );
}

# --- mixed with method/deref steps ----------------------------------------

{
    my $deep = { items => [{n=>1},{n=>2},{n=>3},{n=>4}] };
    my $r = pipe {
        $deep
            |> ->{items}              # arrayref of hashes
            |> map  { $_->{n} }       # extract n
            |> grep { $_ % 2 == 1 }   # keep odd
    };
    is_deeply( $r, [1, 3], 'method/deref |> map |> grep chain' );
}

# --- empty input -----------------------------------------------------------

{
    is_deeply( (pipe { [] |> map  { $_ } }),  [], 'empty map  yields empty arrayref' );
    is_deeply( (pipe { [] |> grep { $_ } }),  [], 'empty grep yields empty arrayref' );
    my $v = pipe { "x" |> tap { 1 } };
    is( $v, "x", 'tap on a scalar passes the scalar through' );
}

# --- tap works on a private copy -------------------------------------------

{
    my $orig = 5;
    my $r = pipe { $orig |> tap { $_ = 50 } };
    is( $r, 50,   'assigning to $_ in tap changes what flows on' );
    is( $orig, 5, '...but the head variable is untouched' );
}

{
    my @seen;
    my $r = pipe { 3 |> tap { push @seen, $_ } |> tap { $_ *= 2 } |> inc };
    is( $r, 7, 'tap copy feeds the next step' );
    is_deeply( \@seen, [3], 'first tap saw the original' );
}

# --- tap and map/grep in the sassign fallback ------------------------------

{
    sub pair { [ $_[0], $_[1] ] }
    my @seen;
    my $r = pipe {
        [1, 2, 3]
            |> map  { $_ * 2 }
            |> grep { $_ > 2 }
            |> tap  { push @seen, scalar @$_ }
            |> pair(_, _)
    };
    is_deeply( $r, [[4, 6], [4, 6]], 'block steps feed a multi-_ step (fallback path)' );
    is_deeply( \@seen, [2], 'tap ran once in the fallback path' );
}

# --- fused runs keep arrayref boundaries where a non-list step sits ---------

{
    my @sizes;
    my $r = pipe {
        [1..6]
            |> map  { $_ * 3 }
            |> grep { $_ % 2 == 0 }
            |> map  { $_ + 1 }
            |> tap  { push @sizes, scalar @$_ }
            |> grep { $_ > 10 }
            |> map  { "n$_" }
    };
    is_deeply( $r, [qw/n13 n19/], 'map |> grep |> map |> tap |> grep |> map' );
    is_deeply( \@sizes, [3], 'tap between two fused runs saw an arrayref' );
}

{
    my $r = pipe { [3, 1, 2] |> map { $_ } |> grep { 1 } |> map { $_ * 10 } };
    is_deeply( $r, [30, 10, 20], 'a run of three list steps preserves order' );
}

{
    my @src = (1, 2, 3);
    my $r = pipe { [@src] |> map { $_ } |> grep { $_++ } };
    is_deeply( $r, [2, 3, 4], 'grep after an identity map can modify $_' );
    is_deeply( \@src, [1, 2, 3], '...without reaching the head array' );
}

done_testing;
