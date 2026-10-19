package Peta::Synth::Engine::Perl;
# ABSTRACT: the voices rendered in Perl

# The engine in Perl: the reference every other engine is measured against,
# and on pperl a fast one, since its loops are what the JIT compiles: plain
# lexical arrays of floats, float arithmetic, sin and exp, no calls.
#
# A partial is a rotating phasor: (c, s) turned by the partial's angle per
# sample, which costs four multiplications where sin() would cost a call;
# its angle and starting phase are set anew at each control block, so the
# pitch follows the voice's controls and the error never accumulates.

use v5.36;
use Peta::Synth::Voice;

our $VERSION = '0.2610180';

use constant BLOCK  => 64;
use constant TWO_PI => 6.283185307179586;

sub new ($class, %arg) { return bless { %arg }, $class }
sub name ($self) { return 'perl' }

# The voices' next $n samples, mixed: (\@left, \@right, \@send). For each
# voice its partials (or its wave sequences), string, FM and noise summed,
# then mixed under its envelope and gains. One loop over the voices with
# the partials and the mix written into it: as subs of their own, with the
# samples passed by reference, they take a tenth longer under pperl's JIT.
sub render ($self, $voices, $n, $rate) {
    my $B  = BLOCK;
    my $nb = $n / $B;
    my @left  = (0.0) x $n;
    my @right = (0.0) x $n;
    my @send  = (0.0) x $n;
    my $dt    = $B / $rate;

    for my $voice (@$voices) {
        my @x = (0.0) x $n;
        my $first = $voice->{first};
        my $t0    = $voice->{t0};
        my @w     = @{ $voice->{w} };
        my @ratio  = @{ $voice->{ratio} };
        my @amp    = @{ $voice->{amp} };
        my @decay  = @{ $voice->{decay} };
        my @attack = @{ $voice->{attack} };
        my @phase  = @{ $voice->{phase} };
        my $count  = $voice->{wave} ? 0 : scalar @ratio;     # read from wave sequences instead
        # The filter's gain at every partial's edges, H[(nb + 1) k + j]
        # (Peta::Synth::Voice::filter_gain written out: no calls, which
        # pperl's JIT would not compile).
        my $fmode = $voice->{fmode} // 0;
        my $edges = $nb + 1;
        my @H = (1.0) x ($fmode ? $count * $edges : 0);
        if ($fmode) {
            my @fx = @{ $voice->{fx} };
            my @fq = @{ $voice->{fq} };
            for my $k (0 .. $count - 1) {
                my $r = $ratio[$k];
                for my $j ($first .. $nb) {
                    my $x  = $r * $fx[$j];
                    my $q  = $fq[$j];
                    my $x2 = $x * $x;
                    my $u  = 1.0 - $x2;
                    my $d  = sqrt($u * $u + $x2 / ($q * $q));
                    my $h = 1.0;
                    if    ($fmode == 1) { $h = 1.0 / $d }
                    elsif ($fmode == 2) { $h = 1.0 / ($d * sqrt(1.0 + $x2 * $x2)) }
                    elsif ($fmode == 3) { $h = $x2 / $d }
                    elsif ($fmode == 4) { $h = $x2 * $x2 / ($d * sqrt(1.0 + $x2 * $x2)) }
                    else                { $h = $x / $q / $d }
                    $H[ $k * $edges + $j ] = $h;
                }
            }
        }

        # The partials, each a rotating phasor, its angle and phase set anew at
        # each block; its amplitude at the edges, interpolated across a block.
        for my $k (0 .. $count - 1) {
            my $r   = $ratio[$k];
            my $a   = $amp[$k];
            my $d   = $decay[$k];
            my $att = $attack[$k];
            my $p   = $phase[$k];
            my $t   = $t0 + $first * $dt;
            my $a0  = $a * exp(-$d * $t);
            $a0 *= 1.0 - exp(-$t / $att) if $att > 0.0;
            $a0 *= $H[ $k * $edges + $first ] if $fmode;
            for my $j ($first .. $nb - 1) {
                my $t1 = $t + $dt;
                my $a1 = $a * exp(-$d * $t1);
                $a1 *= 1.0 - exp(-$t1 / $att) if $att > 0.0;
                $a1 *= $H[ $k * $edges + $j + 1 ] if $fmode;
                my $wk = $r * $w[$j];
                my $c  = cos($p);
                my $s  = sin($p);
                my $cw = cos($wk);
                my $sw = sin($wk);
                my $g  = $a0;
                my $dg = ($a1 - $a0) / $B;
                my $i  = $j * $B;
                my $end = $i + $B;
                while ($i < $end) {
                    $x[$i] += $g * $s;
                    my $c2 = $c * $cw - $s * $sw;
                    $s = $s * $cw + $c * $sw;
                    $c = $c2;
                    $g += $dg;
                    $i++;
                }
                $p += $wk * $B;
                $p -= TWO_PI * int($p / TWO_PI);
                $a0 = $a1;
                $t  = $t1;
            }
            $phase[$k] = $p;
        }
        $voice->{phase} = \@phase;

        if ($voice->{wave}) {
            my $waves = waves($voice, $n, $nb, $rate);
            for my $i ($first * $B .. $n - 1) { $x[$i] += $waves->[$i] }
        }
        if ($voice->{string}) {
            my $string = string($voice, $n, $nb);
            for my $i ($first * $B .. $n - 1) { $x[$i] += $string->[$i] }
        }
        if ($voice->{fm}) {
            my $fm = fm($voice, $n, $nb);
            for my $i ($first * $B .. $n - 1) { $x[$i] += $fm->[$i] }
        }
        if ($voice->{rough}) {
            my $am = rough($voice, $n, $nb);
            for my $i ($first * $B .. $n - 1) { $x[$i] *= $am->[$i] }
        }
        if ($voice->{noise}) {
            my $noise = noise($voice, $n, $nb);
            for my $i ($first * $B .. $n - 1) { $x[$i] += $noise->[$i] }
        }

        # The envelope and the channel's gains, interpolated across each block.
        my @env = @{ $voice->{env} };
        my @gl  = @{ $voice->{gl} };
        my @gr  = @{ $voice->{gr} };
        my @gs  = @{ $voice->{gs} };
        for my $j ($first .. $nb - 1) {
            my $e0 = $env[$j];
            my $de = ($env[ $j + 1 ] - $e0) / $B;
            my $l  = $gl[$j];
            my $dl = ($gl[ $j + 1 ] - $l) / $B;
            my $r  = $gr[$j];
            my $dr = ($gr[ $j + 1 ] - $r) / $B;
            my $s  = $gs[$j];
            my $ds = ($gs[ $j + 1 ] - $s) / $B;
            my $i  = $j * $B;
            my $end = $i + $B;
            while ($i < $end) {
                my $y = $x[$i] * $e0;
                $left[$i]  += $y * $l;
                $right[$i] += $y * $r;
                $send[$i]  += $y * $s;
                $e0 += $de;
                $l  += $dl;
                $r  += $dr;
                $s  += $ds;
                $i++;
            }
        }
    }
    return (\@left, \@right, \@send);
}

# A voice's noise for a quantum: white noise from the table through each
# band's filter (a state-variable one: band-, high- or low-pass; with four
# poles, a second the same after it), under its level, summed into a fresh
# array of $n samples; zero before the voice's first block. The filters'
# states are carried on. The PDL engine uses it as it is.
sub noise ($voice, $n, $nb) {
    my $B     = BLOCK;
    my $table = Peta::Synth::Voice::noise_table();
    my $tsize = scalar @$table;
    my $first = $voice->{first};
    my @out   = (0.0) x $n;
    for my $band (@{ $voice->{bands} }) {
        if ($band->{poles} == 4) {
            _band4(\@out, $band, $first, $nb);
            next;
        }
        my @nenv = @{ $band->{env} };
        my ($ic1, $ic2, $index, $jc1, $jc2) = @{ $band->{state} };
        my $g    = $band->{g};
        my $kq   = $band->{k};
        my $mode = $band->{mode};
        my $a1 = 1.0 / (1.0 + $g * ($g + $kq));
        my $a2 = $g * $a1;
        my $a3 = $g * $a2;
        for my $j ($first .. $nb - 1) {
            my $level = $nenv[$j];
            my $step  = ($nenv[ $j + 1 ] - $level) / $B;
            my $i     = $j * $B;
            my $end   = $i + $B;
            while ($i < $end) {
                my $v0 = $table->[$index];
                $index++;
                $index = 0 if $index >= $tsize;
                my $v3 = $v0 - $ic2;
                my $v1 = $a1 * $ic1 + $a2 * $v3;
                my $v2 = $ic2 + $a2 * $ic1 + $a3 * $v3;
                $ic1 = 2.0 * $v1 - $ic1;
                $ic2 = 2.0 * $v2 - $ic2;
                my $out = $mode == 0 ? $kq * $v1 : $mode == 1 ? $v0 - $kq * $v1 - $v2 : $v2;
                $out[$i] += $level * $out;
                $level += $step;
                $i++;
            }
        }
        $band->{state} = [ $ic1, $ic2, $index, $jc1, $jc2 ];
    }
    return \@out;
}

# A band of four poles: its filter twice. A sub of its own: inside the loop
# above, the bands of two poles, which nearly every noise has, render some
# 6% slower on pperl (percussion.mid: 2.52 s against 2.38).
sub _band4 ($out, $band, $first, $nb) {
    my $B     = BLOCK;
    my $table = Peta::Synth::Voice::noise_table();
    my $tsize = scalar @$table;
    my @nenv  = @{ $band->{env} };
    my ($ic1, $ic2, $index, $jc1, $jc2) = @{ $band->{state} };
    my $g    = $band->{g};
    my $kq   = $band->{k};
    my $mode = $band->{mode};
    my $a1 = 1.0 / (1.0 + $g * ($g + $kq));
    my $a2 = $g * $a1;
    my $a3 = $g * $a2;
    for my $j ($first .. $nb - 1) {
        my $level = $nenv[$j];
        my $step  = ($nenv[ $j + 1 ] - $level) / $B;
        my $i     = $j * $B;
        my $end   = $i + $B;
        while ($i < $end) {
            my $v0 = $table->[$index];
            $index++;
            $index = 0 if $index >= $tsize;
            my $v3 = $v0 - $ic2;
            my $v1 = $a1 * $ic1 + $a2 * $v3;
            my $v2 = $ic2 + $a2 * $ic1 + $a3 * $v3;
            $ic1 = 2.0 * $v1 - $ic1;
            $ic2 = 2.0 * $v2 - $ic2;
            my $u0 = $mode == 0 ? $kq * $v1 : $mode == 1 ? $v0 - $kq * $v1 - $v2 : $v2;
            my $u3 = $u0 - $jc2;
            my $u1 = $a1 * $jc1 + $a2 * $u3;
            my $u2 = $jc2 + $a2 * $jc1 + $a3 * $u3;
            $jc1 = 2.0 * $u1 - $jc1;
            $jc2 = 2.0 * $u2 - $jc2;
            my $y = $mode == 0 ? $kq * $u1 : $mode == 1 ? $u0 - $kq * $u1 - $u2 : $u2;
            $out->[$i] += $level * $y;
            $level += $step;
            $i++;
        }
    }
    $band->{state} = [ $ic1, $ic2, $index, $jc1, $jc2 ];
    return;
}

# A voice's wave sequences (Peta::Synth::Wavetable), copy by copy, block by
# block, for a quantum: the table each block reads (the next one is
# crossfaded to: the last one holds), the crossfade where the block begins
# and its step a sample, the read step (table samples a sample, the copy's
# pitch) and where in the period the block begins (table samples, in
# double precision, so that no engine drifts); each copy's place and table
# carried on to the quantum's end. Every engine reads its samples from these.
sub wave_blocks ($voice, $nb, $rate) {
    my $B     = BLOCK;
    my $dt    = $B / $rate;
    my $first = $voice->{first};
    my $t0    = $voice->{t0};
    my @w     = @{ $voice->{w} };
    my @copies;
    for my $copy (@{ $voice->{wave} }) {
        my ($shift, $sequence, $p, $k) = @$copy;
        my $size  = $sequence->{size};
        my @times = @{ $sequence->{times} };
        my $last  = $#times;
        my $scale = $size / TWO_PI;
        my @table = (0) x $nb;
        my @mix   = (0.0) x $nb;
        my @dmix  = (0.0) x $nb;
        my @step  = (0.0) x $nb;
        my @start = (0.0) x $nb;
        my $t  = $t0 + $first * $dt;
        my $at = $p * $scale;
        for my $j ($first .. $nb - 1) {
            $k++ while $k < $last && $times[ $k + 1 ] <= $t;
            $table[$j] = $k;
            if ($k < $last) {
                my $span = $times[ $k + 1 ] - $times[$k];
                my $m1   = ($t + $dt - $times[$k]) / $span;
                $mix[$j]  = ($t - $times[$k]) / $span;
                $dmix[$j] = (($m1 > 1.0 ? 1.0 : $m1) - $mix[$j]) / $B;
            }
            $step[$j]  = $w[$j] * $shift * $scale;
            $start[$j] = $at;
            $at += $step[$j] * $B;
            $at -= $size * int($at / $size);
            $t  += $dt;
        }
        $copy->[2] = $at / $scale;
        $copy->[3] = $k;
        push @copies, {
            sequence => $sequence,
            size     => $size,
            last     => $last,
            table    => \@table,
            mix      => \@mix,
            dmix     => \@dmix,
            step     => \@step,
            start    => \@start,
        };
    }
    return \@copies;
}

# A voice's partials read from its wave sequences for a quantum, as a fresh
# array of $n samples (zero before its first block): for each copy of the
# unison, each block's two tables crossfaded across it, read at the copy's
# pitch, between samples linearly (wave_blocks says where); a run of blocks
# with the same two tables at a time (_read_tables). The PDL engine uses it
# as it is.
sub waves ($voice, $n, $nb, $rate) {
    my @x = (0.0) x $n;
    my $first = $voice->{first};
    for my $c (@{ wave_blocks($voice, $nb, $rate) }) {
        my $tables = $c->{sequence}{tables};
        my @table  = @{ $c->{table} };
        my $last   = $c->{last};
        my $j0     = $first;
        while ($j0 < $nb) {
            my $kr = $table[$j0];
            my $j1 = $j0 + 1;
            $j1++ while $j1 < $nb && $table[$j1] == $kr;
            _read_tables(\@x, $tables->[$kr], $tables->[ $kr < $last ? $kr + 1 : $kr ], @$c{qw(mix dmix step start size)}, $j0, $j1);
            $j0 = $j1;
        }
    }
    return \@x;
}

# The samples of the blocks j0 .. j1 - 1 of one copy, read from two tables
# (references: a table is not copied) and added into x. A sub of its own:
# inside the loop over the copies pperl's JIT leaves the loop at the
# interpreter's speed (some ten times slower; reported).
sub _read_tables ($x, $ta, $tb, $mixes, $dmixes, $steps, $starts, $size, $j0, $j1) {
    my $B     = BLOCK;
    my @mix   = @$mixes;
    my @dmix  = @$dmixes;
    my @step  = @$steps;
    my @start = @$starts;
    for my $j ($j0 .. $j1 - 1) {
        my $m   = $mix[$j];
        my $dm  = $dmix[$j];
        my $inc = $step[$j];
        my $pos = $start[$j];
        my $i   = $j * $B;
        my $end = $i + $B;
        while ($i < $end) {
            my $at = int($pos);
            my $f  = $pos - $at;
            my $a  = $ta->[$at] + $f * ($ta->[ $at + 1 ] - $ta->[$at]);
            my $b  = $tb->[$at] + $f * ($tb->[ $at + 1 ] - $tb->[$at]);
            $x->[$i] += $a + $m * ($b - $a);
            $m   += $dm;
            $pos += $inc;
            $pos -= $size if $pos >= $size;
            $i++;
        }
    }
    return;
}

# A voice's string for a quantum, as a fresh array of $n samples (zero
# before its first block): the delay line read the block's period back
# (less the rest of the loop's delay): a whole number of samples, the rest
# (0.1 .. 1.1) through a first-order allpass, which delays without
# damping; a stiff string's four allpasses; low-passed, times the loop's
# gain, the pluck added while it is fed in, written again. The line, where
# it writes, the low-pass's last input, the allpasses' last inputs and
# outputs and how much of the pluck is fed are carried on. The PDL engine
# uses it as it is.
sub string ($voice, $n, $nb) {
    my $B     = BLOCK;
    my $first = $voice->{first};
    my @out   = (0.0) x $n;
    my $st    = $voice->{string};
    my @buf   = @{ $st->{buf} };
    my $size  = scalar @buf;
    my $level = $st->{level};
    my $g     = $st->{g};
    my $s1    = $st->{s1};
    my $s0    = 1.0 - $s1;
    my $off   = $st->{off};
    my $stiff = $st->{stages};
    my $a     = $st->{a};
    my ($x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4) = @{ $st->{disp} };
    my @exc   = @{ $st->{exc} };
    my $todo  = scalar @exc;
    my $fed   = $st->{fed};
    my $pos   = $st->{pos};
    my $prev  = $st->{prev};
    my $ax    = $st->{ax};
    my $ay    = $st->{ay};
    my @w     = @{ $voice->{w} };
    for my $j ($first .. $nb - 1) {
        my $d = TWO_PI / $w[$j] - $off;
        $d = 1.1 if $d < 1.1;
        $d = $size - 2.0 if $d > $size - 2.0;
        my $whole = int($d - 0.1);
        my $frac  = $d - $whole;
        my $eta   = (1.0 - $frac) / (1.0 + $frac);
        my $i     = $j * $B;
        my $end   = $i + $B;
        while ($i < $end) {
            my $r = $pos - $whole;
            $r += $size if $r < 0;
            my $in = $buf[$r];
            my $v  = $eta * $in + $ax - $eta * $ay;
            $ax = $in;
            $ay = $v;
            if ($stiff) {
                # The stiffness: four first-order allpasses.
                my $u = $a * ($v - $y1) + $x1;
                $x1 = $v;
                $y1 = $u;
                $v  = $a * ($u - $y2) + $x2;
                $x2 = $u;
                $y2 = $v;
                $u  = $a * ($v - $y3) + $x3;
                $x3 = $v;
                $y3 = $u;
                $v  = $a * ($u - $y4) + $x4;
                $x4 = $u;
                $y4 = $v;
            }
            my $o = $g * ($s0 * $v + $s1 * $prev);
            if ($fed < $todo) { $o += $exc[$fed]; $fed++ }
            $prev = $v;
            $buf[$pos] = $o;
            $pos++;
            $pos = 0 if $pos >= $size;
            $out[$i] = $level * $o;
            $i++;
        }
    }
    $st->{buf}  = \@buf;
    $st->{pos}  = $pos;
    $st->{prev} = $prev;
    $st->{ax}   = $ax;
    $st->{ay}   = $ay;
    $st->{disp} = [ $x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4 ];
    $st->{fed}  = $fed;
    $st->{exc}  = [] if $fed >= $todo;
    return \@out;
}

# A voice's FM for a quantum, as a fresh array of $n samples (zero before
# its first block): operators 4, 3, 2, 1, each a sine of its phase plus
# what modulates it (the algorithm's coefficients times the others'
# outputs; operator 4 its own last two, averaged, times the feedback), its
# level interpolated across each block; the carriers summed. The phases and
# operator 4's last outputs are carried on. The PDL engine uses it as it is.
sub fm ($voice, $n, $nb) {
    my $B     = BLOCK;
    my $first = $voice->{first};
    my @out   = (0.0) x $n;
    my $fm    = $voice->{fm};
    my $level = $fm->{level};
    my $fb    = $fm->{fb};
    my ($r1, $r2, $r3, $r4) = @{ $fm->{ratio} };
    my ($a34, $a24, $a23, $a14, $a13, $a12) = @{ $fm->{coef} };
    my ($c1, $c2, $c3, $c4) = @{ $fm->{carrier} };
    my ($p1, $p2, $p3, $p4) = @{ $fm->{phase} };
    my ($h1, $h2) = @{ $fm->{hist} };
    my @l1 = @{ $fm->{lv}[0] };
    my @l2 = @{ $fm->{lv}[1] };
    my @l3 = @{ $fm->{lv}[2] };
    my @l4 = @{ $fm->{lv}[3] };
    my @w  = @{ $voice->{w} };
    for my $j ($first .. $nb - 1) {
        my $w0 = $w[$j];
        my ($d1, $d2, $d3, $d4) = ($w0 * $r1, $w0 * $r2, $w0 * $r3, $w0 * $r4);
        my $e1 = $l1[$j];
        my $e2 = $l2[$j];
        my $e3 = $l3[$j];
        my $e4 = $l4[$j];
        my $s1 = ($l1[ $j + 1 ] - $e1) / $B;
        my $s2 = ($l2[ $j + 1 ] - $e2) / $B;
        my $s3 = ($l3[ $j + 1 ] - $e3) / $B;
        my $s4 = ($l4[ $j + 1 ] - $e4) / $B;
        my $i   = $j * $B;
        my $end = $i + $B;
        while ($i < $end) {
            my $u4 = sin($p4 + $fb * 0.5 * ($h1 + $h2));
            $h2 = $h1;
            $h1 = $u4;
            my $o4 = $e4 * $u4;
            my $o3 = $e3 * sin($p3 + $a34 * $o4);
            my $o2 = $e2 * sin($p2 + $a24 * $o4 + $a23 * $o3);
            my $o1 = $e1 * sin($p1 + $a14 * $o4 + $a13 * $o3 + $a12 * $o2);
            $out[$i] = $level * ($c1 * $o1 + $c2 * $o2 + $c3 * $o3 + $c4 * $o4);
            $p1 += $d1;
            $p2 += $d2;
            $p3 += $d3;
            $p4 += $d4;
            $e1 += $s1;
            $e2 += $s2;
            $e3 += $s3;
            $e4 += $s4;
            $i++;
        }
        $p1 -= TWO_PI * int($p1 / TWO_PI);
        $p2 -= TWO_PI * int($p2 / TWO_PI);
        $p3 -= TWO_PI * int($p3 / TWO_PI);
        $p4 -= TWO_PI * int($p4 / TWO_PI);
    }
    $fm->{phase} = [ $p1, $p2, $p3, $p4 ];
    $fm->{hist}  = [ $h1, $h2 ];
    return \@out;
}

# A voice's noise on its partials for a quantum: the factor their sum is
# taken times, 1 + depth * (white noise through a one-pole low-pass), as a
# fresh array of $n samples (1 before the voice's first block). The PDL
# engine uses it as it is.
sub rough ($voice, $n, $nb) {
    my $B     = BLOCK;
    my $table = Peta::Synth::Voice::noise_table();
    my $tsize = scalar @$table;
    my $first = $voice->{first};
    my @out   = (1.0) x $n;
    my ($depth, $a) = @{ $voice->{rough} };
    my ($y, $index) = @{ $voice->{rstate} };
    for my $i ($first * $B .. $n - 1) {
        $y += $a * ($table->[$index] - $y);
        $index++;
        $index = 0 if $index >= $tsize;
        $out[$i] = 1.0 + $depth * $y;
    }
    $voice->{rstate} = [ $y, $index ];
    return \@out;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Engine::Perl - the voices rendered in Perl

=head1 VERSION

version 0.2610180

=head1 DESCRIPTION

The reference engine: what L<Peta::Synth::Voice> describes, computed in
plain Perl. On perl5 it is the engine that is always there; on pperl its
loops are compiled by the JIT. See L<Peta::Synth::Engine> for the
interface.

=head1 METHODS

=head2 new, name

C<new(%arg)> makes the engine (it dies where it cannot run here); C<name> is C<perl>.

=head2 render

C<render(\@voices, $n, $rate)>: the voices' next C<$n> samples, mixed, as
array references: left, right and the reverb send.

=head1 FUNCTIONS

=head2 noise, waves, wave_blocks, string, fm, rough

A voice's parts for a quantum, C<($voice, $n, $nb)> (C<waves> and
C<wave_blocks> with the rate): its noise bands; its partials read from
wave sequences, and where each block reads (which every engine reads by);
its string; its FM; the noise on its partials (the factor their sum is
taken times). Each a fresh array of C<$n> samples, what they carry on kept
in the voice; the PDL engine uses them as they are.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
