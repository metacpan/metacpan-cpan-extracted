#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Template::Stencil;

sub inspect { Template::Stencil::_inspect($_[0]) }

# SHORT for <= 31 bytes, LONG above.
{
    my $o31 = inspect('x' x 31)->{ops};
    is($o31->[0]{op}, 'SOP_LITERAL_SHORT', '31 bytes stays SHORT');
    my $o32 = inspect('x' x 32)->{ops};
    is($o32->[0]{op}, 'SOP_LITERAL_LONG', '32 bytes goes LONG');
    is($o32->[0]{len}, 32, 'LONG length');
}

# Const-fold: a template with no tags is one literal + END, even large.
{
    my $i = inspect("no tags here\n" x 500);
    is(scalar @{ $i->{ops} }, 2, 'const-fold to one literal op');
    is($i->{ops}[0]{op}, 'SOP_LITERAL_LONG', 'folded op is LONG');
}

# Adjacent merge across a comment boundary.
{
    my $long = 'y' x 20;
    my $i = inspect($long . '{%# gone %}' . $long);
    is(scalar @{ $i->{ops} }, 2, 'comment-split literals merge');
    is($i->{ops}[0]{len}, 40, 'merged length');
}

# Literal pool dedup: identical LONG literals share one pool offset.
{
    my $chunk = 'z' x 64;
    my $i = inspect($chunk . '{% v %}' . $chunk);
    my @longs = grep { $_->{op} eq 'SOP_LITERAL_LONG' } @{ $i->{ops} };
    is(scalar @longs, 2, 'two LONG literals');
    is($longs[0]{off}, $longs[1]{off}, 'deduped to one pool offset');
}

# Static stack high-water.
{
    is(inspect('{% v %}')->{max_stack}, 1, 'plain output max_stack 1');
    is(inspect('{% if a == b %}x{% end %}')->{max_stack}, 2,
       'comparison max_stack 2');
    is(inspect('{% if a %}x{% end %}')->{max_stack}, 1,
       'truthy test max_stack 1');
}

# Frames / binds high-water.
{
    my $i = inspect('{% for a in x %}{% for b in a %}{% set c = b %}{% end %}{% end %}');
    is($i->{max_frames}, 2, 'nested for frames');
    is($i->{max_binds}, 1, 'set binds');
}

# is_wrapper flag.
is(inspect('{% content %}')->{is_wrapper}, 1, 'content flags wrapper');
is(inspect('{% x %}')->{is_wrapper}, 0, 'no content, no wrapper');

# Golden op sequence for the draft-test fixture.
{
    open my $fh, '<', 't/template/loops.tmpl' or die $!;
    my $src = do { local $/; <$fh> };
    my $got = join "\n", map $_->{op}, @{ inspect($src)->{ops} };
    open my $gf, '<', 't/corpus/loops.ops' or die $!;
    my $want = do { local $/; <$gf> };
    chomp $want;
    is($got, $want, 'loops.tmpl golden op sequence');
}

# Cold-compile budget. An absolute microsecond bound is not a property of
# the compiler, it is a property of the smoker: a 1000us ceiling that holds
# on a laptop fails on an ARMv6 Pi that is simply ~5x slower at everything.
# What we actually want to catch is the compiler going non-linear, so
# measure the same template at two sizes and assert the ratio. That is
# scale-free - a slow box slows both halves equally - and a quadratic
# regression shows up as ~100x where linear shows ~10x.
{
    my $unit = '<li>' . ('x' x 20) . '{% item.name %}</li>';
    my $tail = '{% if a %}{% for i in items %}{% i %}{% end %}{% end %}';

    # Time the compiler, not _inspect. _inspect walks the finished program
    # and builds one Perl hash per op, so the big template pays ~10x the SV
    # churn of the small one on top of the compile - and that half is at the
    # mercy of the allocator, which is exactly what varies on a loaded
    # smoker. A FreeBSD box reported 43.9x here on a compiler that is
    # provably sublinear. _compile_handle/_free_handle is the same compile
    # with none of the SV building, and drops the measurement to a fifth.
    #
    # Take the best of several rounds rather than an average, too: timing
    # noise is one-sided, so the minimum is the closest thing to the real
    # cost that a shared machine will ever show us.
    #
    # Size the iteration count against the clock, not by hand. A fixed
    # count times a round that may be shorter than the clock can resolve,
    # and then the ratio is a quotient of two rounding errors: a FreeBSD
    # smoker timed the small template at 0.06us, which is 15 bytes of
    # template parsed per nanosecond, and reported 59.3x for 10x input off
    # the back of it. Grow the count until a round spans enough ticks that
    # the quantisation is far below the margin we are asserting on. 5ms is
    # some thousands of ticks on a microsecond clock; the 200-tick rule
    # covers a coarser one, and the 100ms ceiling keeps a millisecond clock
    # from turning this into a ten-second test.
    my $tick = do {
        my $best;
        for (1 .. 20) {
            my $t0 = Time::HiRes::time();
            my $d;
            1 while (($d = Time::HiRes::time() - $t0) <= 0);
            $best = $d if !defined $best || $d < $best;
        }
        $best;
    };
    my $floor = $tick * 200;
    $floor = 0.005 if $floor < 0.005;
    $floor = 0.100 if $floor > 0.100;

    # (us per compile, whether a round ever cleared the floor, count used)
    sub time_compile {
        my ($tmpl, $floor) = @_;
        my $n = 32;
        my $elapsed;
        while (1) {
            my $t0 = Time::HiRes::time();
            for (1 .. $n) {
                Template::Stencil::_free_handle(
                    Template::Stencil::_compile_handle($tmpl));
            }
            $elapsed = Time::HiRes::time() - $t0;
            last if $elapsed >= $floor;
            # jump straight to the count the floor asks for, with headroom
            my $want = $elapsed > 0
                     ? int($n * $floor / $elapsed * 1.3) + 1 : $n * 8;
            last if $want > 1_000_000;   # a clock this broken gets a skip
            $n = $want;
        }
        my $best = $elapsed;
        for (1 .. 2) {
            my $t0 = Time::HiRes::time();
            for (1 .. $n) {
                Template::Stencil::_free_handle(
                    Template::Stencil::_compile_handle($tmpl));
            }
            my $e = Time::HiRes::time() - $t0;
            $best = $e if $e < $best;
        }
        return ($best / $n * 1e6, $elapsed >= $floor, $n);
    }

    my $small = ($unit x 20)  . $tail;
    my $big   = ($unit x 200) . $tail;
    my ($us_small, $small_ok, $n_small) = time_compile($small, $floor);
    my ($us_big,   $big_ok,   $n_big)   = time_compile($big,   $floor);
    my $ratio = $us_big / ($us_small || 1e-9);

    diag(sprintf 'cold compile: %d bytes %.3f us (n=%d), %d bytes %.3f us '
               . '(n=%d), %.1fx for 10x input, clock tick %.3f us',
         length $small, $us_small, $n_small,
         length $big,   $us_big,   $n_big, $ratio, $tick * 1e6);

    # 10x the input for <=40x the time. Linear lands near 10x - in practice
    # nearer 5x, since the fixed tail amortises and interning folds the
    # repeated unit - and anything quadratic lands near 100x and trips this
    # on any machine.
    SKIP: {
        skip 'clock too coarse to time the compiler on this box', 1
            unless $small_ok && $big_ok;
        cmp_ok($ratio, '<', 40, 'compile time scales linearly with input');
    }

    # The absolute budget is a real number worth defending, but only on
    # hardware we control - it says nothing on a random smoker.
    if ($ENV{AUTHOR_TESTING} || $ENV{EXTENDED_TESTING}) {
        cmp_ok($us_small, '<', 200, 'compile time within absolute budget');
    }
}

done_testing;
