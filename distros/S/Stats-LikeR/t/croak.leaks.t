#!/usr/bin/env perl
# Argument-validation paths must not leak, and must not die by signal.
#
# Every case here is a defect that shipped in 0.314, found by running the
# suite under valgrind (--leak-check=full --errors-for-leak-kinds=definite) and
# by watching RSS over tens of thousands of failing calls. Two distinct faults:
#
#  * SIGSEGV / runaway. A hole in a sparse array -- what `delete $a[2]` leaves,
#    or `$a[0]=1; $a[3]=4` makes of indices 1 and 2 -- reached
#    SvNV(*av_fetch(...)) in five readers, which dereferenced NULL. None of it
#    was catchable, because eval does not see a signal. srv_read() did check
#    the pointer but mapped the hole to NaN, and a NaN survival time does not
#    fail a `t < 0` test, so survfit() and logrank_test() ran away instead.
#
#  * Leaks on croak. croak() longjmps past any Safefree() written after it, so
#    a validation failure that happened once the working set was allocated
#    dropped all of it. Measured per failing call, before the fix:
#
#        dunn_test  method => 'nope'            113 KB at n=2000, grows with n
#        scale      non-numeric element         8 bytes/element (160 KB at 20k)
#        aov        'y ~ a:b', no main effects  7.7 KB
#        col2col    unknown column              3.7 KB, grows with rows x cols
#        fisher_test non-numeric cell           3.2 KB, grows with the table
#        glm        response outside the family 2.9 KB
#
# 0.3213 adds four more, each found while making the XS functions keep the
# caller's hash iterator. Each freed its tables by hand on the paths it expected
# to fail and leaked them on every other: a croak raised by perl code it calls
# (overloading, a tied hash's FIRSTKEY) or one written after the hand-made
# frees. Each now puts its tables on the save stack or makes them mortal:
#
#        hoh2hoa      non-hash row, row_names collision: the result hash,
#                     both key arrays and the union hash
#        kruskal_test a label whose stringification dies: obs, the label
#                     table, every label and the label-to-id hash
#        prcomp       a croak other than its own: column names, data matrix
#        col2col      a tied row whose FIRSTKEY dies: row table, union hash
#
# The leak half needs Test::LeakTrace, which is optional; those subtests skip
# without it, exactly as the sibling suites do. The signal half needs nothing
# and always runs, because a segfault is the more serious of the two and a
# skipped check for it is a check that never runs on a smoker.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR ();

# Imported at compile time, because no_leaks_ok's block form needs its
# prototype visible when the file is parsed. Same shape as t/assign.t's header.
my $HAVE_LEAKTRACE;
BEGIN {
    if ( eval { require Test::LeakTrace; 1 } ) {
        Test::LeakTrace->import('no_leaks_ok');
        $HAVE_LEAKTRACE = 1;
    }
    else {
        *no_leaks_ok = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
        $HAVE_LEAKTRACE = 0;
    }
}

# fixtures
sub hole_at {                     # a 4-element array with index $i missing
    my $i = shift;
    my @a = ( 10, 20, 30, 40 );
    delete $a[$i];
    return \@a;
}

my @tm = ( 2, 3, 5, 5, 5, 6, 8, 8, 9, 11, 12, 14, 15, 15, 17, 20 );
my @st = ( 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0 );
my @xv = ( 1, 4, 2, 6, 3, 8, 5, 7, 2, 9, 4, 6, 8, 1, 3, 5 );

my @dunn_x = map { $_ / 7 } 1 .. 60;
my @dunn_g = map { 'g' . ( $_ % 5 ) } 1 .. 60;

my %c2c = map { ( "c$_" => [ map { $_ / 3 } 1 .. 40 ] ) } 1 .. 6;

my %glm_bin  = ( y => [ 0, 2, 0, 1, 0, 1, 0, 1 ], x => [ 1 .. 8 ] );
my %glm_neg  = ( y => [ -1, 2, 0, 3, 0, 1, 0, 1 ], x => [ 1 .. 8 ] );
my %glm_zero = ( y => [ 0, 0, 0, 0, 0, 0, 0, 0 ], x => [ 1 .. 8 ] );

my %aov_d = ( y => [ 1 .. 8 ], a => [qw(x x y y x x y y)], b => [qw(p q p q p q p q)] );

# a group label that dies when kruskal_test reads it, and a row that dies when
# col2col walks it: croaks from perl code, mid-way through the C tables
{
    package DieStr;
    use overload '""' => sub { die "label refused\n" }, 'fallback' => 1;
}
{
    package DieFirstKey;
    require Tie::Hash;
    our @ISA = ('Tie::StdHash');
    sub FIRSTKEY { die "no keys today\n" }
}
my @kw_g = ( 'a', 'a', 'b', bless( {}, 'DieStr' ) );
tie my %dying_row, 'DieFirstKey';
my @c2c_aoh = ( { x => 1, y => 2 }, { x => 3, y => 5 }, \%dying_row );

# Each: [ label, code, qr/expected message/ ]
my @cases = (
    # -- the SIGSEGV set
    [ 'epi_2x2 flat hole',   sub { Stats::LikeR::epi_2x2( hole_at(2) ) },
        qr/epi_2x2: cell at index 2 is undef/ ],
    [ 'epi_2x2 flat undef',  sub { Stats::LikeR::epi_2x2( [ 1, 2, undef, 4 ] ) },
        qr/epi_2x2: cell at index 2 is undef/ ],
    [ 'epi_2x2 non-numeric', sub { Stats::LikeR::epi_2x2( [ 1, 2, 'abc', 4 ] ) },
        qr/epi_2x2: cell at index 2 is not a number/ ],
    [ 'epi_2x2 nested hole', sub { my @r; $r[1] = 4;
            Stats::LikeR::epi_2x2( [ [ 1, 2 ], \@r ] ) },
        qr/epi_2x2: row 1 cell at index 0 is undef/ ],
    [ 'cmh_test flat hole',  sub { Stats::LikeR::cmh_test( [ hole_at(2) ] ) },
        qr/cmh_test: cell at index 2 is undef/ ],
    [ 'binom_test hole',     sub { my @x; $x[1] = 5; Stats::LikeR::binom_test( \@x ) },
        qr/binom_test: successes is undef/ ],
    # A hole in the middle: `delete $r[-1]` would shorten the array instead,
    # and be caught by the column-count check rather than by the cell reader.
    [ 'fisher_test AoA hole', sub { my @r; $r[0] = 3; $r[2] = 5; $#r = 1;
            Stats::LikeR::fisher_test( [ [ 1, 2 ], \@r ] ) },
        qr/fisher_test: array cell is undef/ ],
    [ 'coxph time hole',     sub { my @t = @tm; delete $t[3];
            Stats::LikeR::coxph( \@t, \@st, \@xv ) }, qr/coxph: time at index 3/ ],
    [ 'coxph status hole',   sub { my @s = @st; delete $s[4];
            Stats::LikeR::coxph( \@tm, \@s, \@xv ) }, qr/coxph: status at index 4/ ],
    [ 'coxph covariate hole', sub { my @x = @xv; delete $x[5];
            Stats::LikeR::coxph( \@tm, \@st, \@x ) }, qr/coxph: covariate value at index 5/ ],
    [ 'survfit time hole',   sub { my @t = @tm; delete $t[2];
            Stats::LikeR::survfit( \@t, \@st ) }, qr/survfit: time at index 2/ ],
    [ 'survfit time undef',  sub { my @t = @tm; $t[2] = undef;
            Stats::LikeR::survfit( \@t, \@st ) }, qr/survfit: time at index 2 is undef/ ],
    [ 'logrank time hole',   sub { my @t = @tm; delete $t[2];
            Stats::LikeR::logrank_test( \@t, \@st, [ map { $_ % 2 ? 'a' : 'b' } 1 .. 16 ] ) },
        qr/logrank_test: time at index 2/ ],

    # -- the leaking-croak set
    [ 'dunn_test unknown method',
        sub { Stats::LikeR::dunn_test( \@dunn_x, \@dunn_g, method => 'nope' ) },
        qr/dunn_test: unknown method 'nope'/ ],
    [ 'scale non-numeric element',
        sub { Stats::LikeR::scale( [ 1 .. 50, 'notanumber' ] ) },
        qr/scale: non-numeric value/ ],
    [ 'aov too few complete rows, after the design is built',
        sub { Stats::LikeR::aov( { y => [ 1, undef, undef ], g => [qw(p q r)] }, 'y ~ g' ) },
        qr/aov: fewer than 2 complete observations/ ],
    [ 'col2col unknown column',
        sub { Stats::LikeR::col2col( \%c2c, 'sum', 'nosuchcolumn' ) },
        qr/col2col: column 'nosuchcolumn' not found/ ],
    [ 'col2col undef in column list',
        sub { Stats::LikeR::col2col( \%c2c, 'sum', [undef] ) },
        qr/col2col: column list contains an undefined entry/ ],
    [ 'fisher_test non-numeric cell',
        sub { Stats::LikeR::fisher_test( [ [ 1, 2 ], [ 3, 'zz' ] ] ) },
        qr/fisher_test: array cell is not a number/ ],
    [ 'glm binomial response out of range',
        sub { Stats::LikeR::glm( data => \%glm_bin, formula => 'y ~ x', family => 'binomial' ) },
        qr/binomial family requires response between 0 and 1/ ],
    [ 'glm poisson negative response',
        sub { Stats::LikeR::glm( data => \%glm_neg, formula => 'y ~ x', family => 'poisson' ) },
        qr/poisson\/negbin family requires a non-negative response/ ],
    [ 'glm poisson all-zero response',
        sub { Stats::LikeR::glm( data => \%glm_zero, formula => 'y ~ x', family => 'poisson' ) },
        qr/poisson\/negbin family requires some positive counts/ ],

    # -- 0.3213
    [ 'hoh2hoa non-hash row',
        sub { Stats::LikeR::hoh2hoa( { a => { x => 1 }, b => 5 } ) },
        qr/hoh2hoa: every value must be a hash ref/ ],
    [ 'hoh2hoa row_names collision',
        sub { Stats::LikeR::hoh2hoa( { a => { x => 1 } }, 'row_names' => 'x' ) },
        qr/hoh2hoa: row_names column 'x' collides/ ],
    [ 'kruskal_test label dies mid-scan',
        sub { Stats::LikeR::kruskal_test( x => [ 1, 2, 3, 4 ], g => \@kw_g ) },
        qr/label refused/ ],
    [ 'kruskal_test empty group',
        sub { Stats::LikeR::kruskal_test( h => { a => [ 1, 2 ], b => [] } ) },
        qr/all groups must contain data/ ],
    [ 'kruskal_test one group',
        sub { Stats::LikeR::kruskal_test( x => [ 1, 2, 3 ], g => [qw(a a a)] ) },
        qr/all observations are in the same group/ ],
    [ 'prcomp constant column under scale',
        sub { Stats::LikeR::prcomp( { a => [ 1, 2, 3 ], b => [ 5, 5, 5 ] }, scale => 1 ) },
        qr/prcomp: cannot rescale a constant\/zero column/ ],
    [ 'prcomp no complete row',
        sub { Stats::LikeR::prcomp( { a => [ undef, undef ], b => [ 'x', 'y' ] } ) },
        qr/prcomp: 0 valid observations/ ],
    [ 'col2col tied row whose FIRSTKEY dies',
        sub { Stats::LikeR::col2col( \@c2c_aoh, 'cor' ) },
        qr/no keys today/ ],
);

# 1. every case croaks, with the message that names what went wrong. A signal
#    would take the whole process out here, so reaching the next test at all is
#    part of what is being checked.
for my $c (@cases) {
    my ( $label, $cb, $re ) = @$c;
    my $lived = eval { $cb->(); 1 };
    if ($lived) { fail("$label: should have croaked, returned instead"); next }
    like( $@, $re, "$label: croaks with the expected message" );
}

# 2. and does so without leaking. Test::LeakTrace counts SVs, which catches a
#    leaked SV or refcount but not a leaked malloc block; the C buffers are
#    covered by running this file under valgrind, which is how they were found.
#    Both are worth having: the SV count is what a smoker can check.
for my $c (@cases) {
    my ( $label, $cb ) = @$c;
    no_leaks_ok { eval { $cb->() } } "$label: no SV leak on the croak path";
}

# 3. the ordinary call still works. Without this the whole file could pass by
#    breaking every function outright.
{
    my $e = Stats::LikeR::epi_2x2( [ 10, 20, 30, 40 ] );
    ok( abs( $e->{'odds_ratio'} - ( 10 * 40 ) / ( 20 * 30 ) ) < 1e-12, 'epi_2x2 still correct' );

    my $f = Stats::LikeR::fisher_test( [ [ 1, 2 ], [ 3, 4 ] ] );
    ok( defined $f->{'p_value'}, 'fisher_test still returns a p-value' );

    my $b = Stats::LikeR::binom_test( [ 3, 7 ] );
    ok( defined $b->{'p_value'}, 'binom_test still returns a p-value' );

    my $d = Stats::LikeR::dunn_test( \@dunn_x, \@dunn_g, method => 'holm' );
    ok( ref $d eq 'ARRAY' && @$d == 10, 'dunn_test still returns 10 pairwise rows' );

    my @s = Stats::LikeR::scale( [ 1 .. 50 ] );
    ok( @s == 50 && abs( $s[0] + $s[-1] ) < 1e-12, 'scale still centres symmetrically' );

    my $cc = Stats::LikeR::col2col( \%c2c, 'sum', 'c1' );
    ok( ref $cc eq 'HASH', 'col2col still returns a frame' );

    my $g = Stats::LikeR::glm(
        data => { y => [ 0, 1, 0, 1, 0, 1, 0, 1 ], x => [ 1 .. 8 ] },
        formula => 'y ~ x', family => 'binomial' );
    ok( ref $g eq 'HASH', 'glm still fits a binomial model' );

    my $a = Stats::LikeR::aov( \%aov_d, 'y ~ a + b + a:b' );
    ok( ref $a eq 'HASH', 'aov still fits an interaction when the main effects are present' );

    my $cx = Stats::LikeR::coxph( \@tm, \@st, \@xv );
    ok( defined $cx->{coef}[0], 'coxph still returns a coefficient' );

    ok( ref Stats::LikeR::survfit( \@tm, \@st ), 'survfit still returns a fit' );
    ok( defined Stats::LikeR::logrank_test( \@tm, \@st,
            [ map { $_ % 2 ? 'a' : 'b' } 1 .. 16 ] )->{'p_value'},
        'logrank_test still returns a p-value' );

    is_deeply( Stats::LikeR::hoh2hoa( { a => { x => 1 }, b => { x => 2 } } ), { x => [ 1, 2 ] },
        'hoh2hoa still converts' );
    ok( defined Stats::LikeR::kruskal_test( h => { a => [ 1, 2, 5 ], b => [ 3, 4, 6 ] } )->{'p_value'},
        'kruskal_test (h) still returns a p-value' );
    ok( defined Stats::LikeR::kruskal_test( x => [ 1, 2, 5, 3, 4, 6 ], g => [qw(a a a b b b)] )->{'p_value'},
        'kruskal_test (x, g) still returns a p-value' );
    is_deeply( Stats::LikeR::prcomp( [ { A => 2, B => 4 }, { A => 4, B => 2 }, { A => 6, B => 6 } ] )->{varnames},
        [ 'A', 'B' ], 'prcomp still names its columns' );
    ok( ref Stats::LikeR::col2col( [ { x => 1, y => 2 }, { x => 3, y => 5 }, { x => 4, y => 4 } ], 'cor' ) eq 'HASH',
        'col2col still correlates an AoH' );
    if ($HAVE_LEAKTRACE) {
        no_leaks_ok { Stats::LikeR::kruskal_test( x => [ 1, 2, 5, 3, 4, 6 ], g => [qw(a a a b b b)] ) }
            'kruskal_test: no leak on success';
        no_leaks_ok { Stats::LikeR::prcomp( { a => [ 1, 2, 3, 5 ], b => [ 2, 1, 4, 4 ] } ) }
            'prcomp: no leak on success';
    }
}

done_testing;
