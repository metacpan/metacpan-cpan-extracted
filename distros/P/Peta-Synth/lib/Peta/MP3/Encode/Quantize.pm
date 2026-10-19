package Peta::MP3::Encode::Quantize;
# ABSTRACT: a granule's lines into Layer III's integers and codes

# Turns a granule's 576 frequency lines into integers and Huffman codes,
# within a number of bits and, where the bits allow, within the noise each
# band may take.
#
# A line x is quantized with a step 2^((q - 210) / 4) as
#
#   ix = int( (|x| / step)^(3/4) + 0.4054 )
#
# where q is the global gain, less 2 (or 4, with scalefac_scale) for each
# step of the band's scalefactor, and in a short block less 8 for each step
# of the window's subblock gain. The lines come in groups that share a q:
# the 22 bands of a long block, or the 13 bands times 3 windows of a short
# one. The steps:
#
#   1. Each group's coarsest q whose noise stays within what it may take.
#   2. The global gain the coarsest group needs, as far as the scalefactors
#      (and subblock gains) can make the others finer: in a long block bands
#      0-10 by up to 15 steps, 11-20 by 7, 21 not at all; in a short one
#      bands 0-5 by 15, 6-11 by 7, 12 not at all, and each window by up to 7
#      steps of subblock gain. Where a band wants finer than its scalefactor
#      reaches, all the others are made finer with it. Then steps of 4
#      (scalefac_scale) and, in a long block, preflag (bands 11-20 finer by
#      the decoder's table) are tried, and the plan that takes the fewest
#      bits wins (1-2% fewer than the coarsest global gain alone).
#   3. If that takes more bits than there are, a coarser global gain until
#      it fits: all groups' noise rises together. If it takes fewer than
#      must be used, a finer one.
#   4. MPEG-1, in the second granule of a frame, long blocks after long
#      blocks: the groups of scalefactors (bands 0-5, 6-10, 11-15, 16-20)
#      the first granule already sent are not sent again (scfsi).
#   5. The Huffman coding: the big values in regions, each with the table
#      that codes it shortest (a normal long block chooses where its three
#      regions end; the others have two, split after 36 lines, or a start or
#      stop block's at the 8th long band's end); then the quadruples of ones
#      and zeros; then nothing for the zeros at the top.
#
# Written for pperl's JIT: flat lexical arrays, plain loops.

use v5.36;
use List::Util qw(max min);
use Peta::MP3::Encode::Tables;

our $VERSION = '0.2610180';

use constant LARGEST => 8206;      # the largest value: 15 plus what 13 linbits hold
use constant ROUND   => 0.4054;
use constant SHORT   => 2;         # the block type of short blocks

# A group of lines: [ LO, HI ] its lines, SF its scalefactor (-1: none),
# MOST that scalefactor's largest, WINDOW its short window (-1: none).
use constant {
    LO     => 0,
    HI     => 1,
    SF     => 2,
    MOST   => 3,
    WINDOW => 4,
};

my @POW43         = map { $_**(4 / 3) } 0 .. LARGEST;
my @HUFFMAN       = @Peta::MP3::Encode::Tables::HUFFMAN;
my @SLEN1         = @Peta::MP3::Encode::Tables::SLEN1;
my @SLEN2         = @Peta::MP3::Encode::Tables::SLEN2;
my @PRETAB        = @Peta::MP3::Encode::Tables::PRETAB;
my @LSF_PARTS     = @Peta::MP3::Encode::Tables::LSF_PARTS;
my @LSF_SLEN_MOST = @Peta::MP3::Encode::Tables::LSF_SLEN_MOST;

# The tables without linbits, by the largest value they hold.
my @SMALL = ([1], [1], [2, 3], [5, 6], [7, 8, 9], [7, 8, 9], [10, 11, 12], [10, 11, 12], map { [13, 15] } 8 .. 15);

# The tables with linbits, in their two families, fewest linbits first.
my @ESCAPE = ([16 .. 23], [24 .. 31]);

# The tables with code lengths of their own; where each table finds its
# lengths among them; and their lengths side by side, LENGTHS[256 c + 16 x + y].
my @CODED = (1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 24);
my @CODED_AT;
$CODED_AT[ $CODED[$_] ] = $_ for 0 .. $#CODED;
$CODED_AT[$_] = $CODED_AT[16] for 17 .. 23;
$CODED_AT[$_] = $CODED_AT[24] for 25 .. 31;
my @LENGTHS = map { @{ $HUFFMAN[$_][2] } } @CODED;

# The scalefactors scfsi shares between granules, in four groups.
my @SCFSI = ([ 0, 6 ], [ 6, 11 ], [ 11, 16 ], [ 16, 21 ]);

sub new ($class, $rate) {
    my $bands = $Peta::MP3::Encode::Tables::BANDS{$rate} // die "no scalefactor bands for $rate Hz\n";
    my @long  = @{ $bands->{long} };
    my @short = @{ $bands->{short} };

    # Long blocks: the 22 bands.
    my @long_groups;
    for my $b (0 .. 21) {
        my $most = $b < 11 ? 15 : $b < 21 ? 7 : 0;
        push @long_groups, [ $long[$b], $long[$b + 1], $b < 21 ? $b : -1, $most, -1 ];
    }

    # Short blocks: band b, window w is group 3 b + w, its lines in the
    # bitstream's order.
    my @short_groups;
    for my $b (0 .. 12) {
        my $width = $short[$b + 1] - $short[$b];
        my $most  = $b < 6 ? 15 : $b < 12 ? 7 : 0;
        for my $w (0 .. 2) {
            my $lo = 3 * $short[$b] + $w * $width;
            push @short_groups, [ $lo, $lo + $width, $b < 12 ? 3 * $b + $w : -1, $most, $w ];
        }
    }

    return bless {
        long   => \@long,
        groups => { long => \@long_groups, short => \@short_groups },
        lsf    => exists $Peta::MP3::Encode::Tables::LSF_RATE_CODE{$rate} ? 1 : 0,
    }, $class;
}

# Quantizes and codes a granule. $allowed is the noise each group may take;
# $budget the most bits it may take, $least the fewest where it would take
# fewer (the bits are there, and would otherwise go unused); $type its
# block type. $before is the first granule's result for this channel, when
# this is the second: its scalefactors may be reused.
#
# Returns { ix, scalefac (as sent), preflag, subblock_gain, global_gain,
# scalefac_scale, scalefac_compress, block_type, big_values, count1,
# table_select, region0_count, region1_count, count1table, part2_length,
# part2_3_length, scfsi }.
sub granule ($self, $xr, $allowed, $budget, $least, $type, $before = undef) {
    $budget = 4095 if $budget > 4095;

    my @a34  = (0.0) x 576;    # |x|^(3/4)
    my $loud = 0.0;
    for my $i (0 .. 575) {
        my $a = abs $xr->[$i];
        $a34[$i] = $a**0.75;
        $loud = $a if $a > $loud;
    }
    return _silent($type) if $loud < 1e-12;

    my $reuse = $before && $type != SHORT && $before->{block_type} != SHORT ? $before->{scalefac} : undef;

    my ($want, $finest) = $self->_wanted($xr, \@a34, $allowed, $type);
    my @plans = $self->_plans($want, $finest, $type);
    my ($plan, $priced) = $self->_cheapest(\@plans, \@a34, $type, $reuse);

    return $self->_fit(\@a34, $type, @$plan, $budget, $least, $reuse, $priced);
}

# Step 1: each group's coarsest q within its noise, and its finest possible
# (no line beyond LARGEST). A group of zeros wants none.
sub _wanted ($self, $xr, $a34, $allowed, $type) {
    my $groups = $self->_groups($type);
    my (@want, @finest);

    for my $g (0 .. $#$groups) {
        my ($lo, $hi) = @{ $groups->[$g] }[ LO, HI ];

        my $top = 0.0;
        for my $i ($lo .. $hi - 1) {
            my $a = abs $xr->[$i];
            $top = $a if $a > $top;
        }
        if ($top == 0.0) {
            push @want,   255;
            push @finest, 0;
            next;
        }

        my $low  = _finest($top);
        my $high = 255;
        push @finest, $low;

        if    (_noise($xr, $a34, $lo, $hi, $high) <= $allowed->[$g]) { push @want, $high; next }
        elsif (_noise($xr, $a34, $lo, $hi, $low)  >  $allowed->[$g]) { push @want, $low;  next }

        while ($high - $low > 1) {
            my $mid = int(($low + $high) / 2);
            if (_noise($xr, $a34, $lo, $hi, $mid) <= $allowed->[$g]) { $low = $mid } else { $high = $mid }
        }
        push @want, $low;
    }
    return (\@want, \@finest);
}

# Step 2: the plans worth trying, each [ global gain, scalefactors,
# subblock gains, scalefac_scale, the finest global gain, preflag ]. The
# scalefactors here are what the decoder makes of them (preflag's table
# added). Steps of 2 without preflag come first; the others only where
# those do not reach as far as the groups want.
sub _plans ($self, $want, $finest, $type) {
    my $groups = $self->_groups($type);
    my $ideal  = max(0, @$want);
    my @tries  = $type == SHORT ? ([ 0, 0 ], [ 1, 0 ]) : ([ 0, 0 ], [ 1, 0 ], [ 0, 1 ], [ 1, 1 ]);
    my @plans;

    for my $try (@tries) {
        my ($scale, $pre) = @$try;
        my $unit = $scale ? 4 : 2;

        # The global gain: the coarsest that every group can be made fine
        # enough from.
        my $gain = $ideal;
        for my $g (0 .. $#$groups) {
            my ($at, $most) = @{ $groups->[$g] }[ SF, MOST ];
            my $add   = $pre && $at >= 0 ? $PRETAB[$at] : 0;
            my $reach = $want->[$g] + ($type == SHORT ? 56 : 0) + $unit * ($most + $add);
            $gain = $reach if $gain > $reach;
        }

        my $sbg = $type == SHORT ? _subblock_gains($groups, $want, $gain, $unit) : [ 0, 0, 0 ];
        my $sf  = _scalefactors($groups, $want, $finest, $gain, $sbg, $unit, $pre, $type);

        # The global gain itself can be no finer than the groups allow.
        my $floor = 0;
        for my $g (0 .. $#$groups) {
            my ($at, $w) = @{ $groups->[$g] }[ SF, WINDOW ];
            my $q = $finest->[$g] + ($at >= 0 ? $unit * $sf->[$at] : 0) + ($w >= 0 ? 8 * $sbg->[$w] : 0);
            $floor = $q if $q > $floor;
        }
        $gain = $floor if $gain < $floor;

        push @plans, [ $gain, $sf, $sbg, $scale, $floor, $pre ];
        last if $gain >= $ideal;
    }
    return @plans;
}

# A short block's subblock gains: for each window, as much as its hardest
# group needs beyond what the scalefactors reach, at most 7.
sub _subblock_gains ($groups, $want, $gain, $unit) {
    my @sbg = (0, 0, 0);
    for my $g (0 .. $#$groups) {
        my ($most, $w) = @{ $groups->[$g] }[ MOST, WINDOW ];
        my $need = $gain - $want->[$g] - $unit * $most;
        next if $need <= 0;

        my $steps = int(($need + 7) / 8);
        $sbg[$w] = $steps if $steps > $sbg[$w];
    }
    return [ map { min($_, 7) } @sbg ];
}

# The scalefactors that bring each group from the global gain to what it
# wants, as far as they reach, and no finer than it can go.
sub _scalefactors ($groups, $want, $finest, $gain, $sbg, $unit, $pre, $type) {
    my @sf = (0) x ($type == SHORT ? 36 : 21);
    for my $g (0 .. $#$groups) {
        my ($at, $most, $w) = @{ $groups->[$g] }[ SF, MOST, WINDOW ];
        next if $at < 0;

        my $add  = $pre ? $PRETAB[$at] : 0;    # with preflag, at the least that
        my $base = $gain - ($w >= 0 ? 8 * $sbg->[$w] : 0);
        my $need = $base - $want->[$g];

        my $sf = $need > 0 ? int(($need + $unit - 1) / $unit) : 0;
        $sf = $most + $add if $sf > $most + $add;
        $sf-- while $sf > 0 && $base - $unit * $sf < $finest->[$g];
        $sf = $add if $sf < $add;
        $sf[$at] = $sf;
    }
    return \@sf;
}

# Of several plans, the one whose lines take the fewest bits, and that
# count with its lines ([ bits, ix ]) for the fit to start from. A single
# plan, or none that can be coded, leaves the first, unpriced.
sub _cheapest ($self, $plans, $a34, $type, $reuse) {
    return ($plans->[0]) if @$plans == 1;

    my ($plan, $priced) = ($plans->[0]);
    for my $p (@$plans) {
        my ($gain, $sf, $sbg, $scale, undef, $pre) = @$p;
        my $sent = _sent($sf, $pre);
        my (undef, $part2) = $self->_scalefactor_bits($sent, $type, $pre, _scfsi($sent, $reuse));
        next if !defined $part2;    # cannot be coded so (MPEG-2)

        my $ix   = $self->_quantize($a34, $type, $gain, $sf, $sbg, $scale);
        my $bits = $part2 + $self->_huffman($ix, 0, $type)->{bits};
        ($plan, $priced) = ($p, [ $bits, $ix ]) if !$priced || $bits < $priced->[0];
    }
    return ($plan, $priced);
}

# Step 3: within the budget. The finest global gain from $gain on that
# fits; or, where that takes fewer than $least bits, the coarsest from
# $finest on that takes them.
sub _fit ($self, $a34, $type, $gain, $sf, $sbg, $scale, $finest, $pre, $budget, $least, $reuse, $priced = undef) {
    my $scfsi = _scfsi(_sent($sf, $pre), $reuse);
    my ($compress, $part2) = $self->_scalefactor_bits(_sent($sf, $pre), $type, $pre, $scfsi);

    my $cost = sub ($g) {
        my $ix = $self->_quantize($a34, $type, $g, $sf, $sbg, $scale);
        return ($part2 + $self->_huffman($ix, 0, $type)->{bits}, $ix);
    };
    my ($bits, $ix) = $priced ? @$priced : $cost->($gain);

    if ($bits > $budget) {
        my ($low, $high) = ($gain, 255);
        my ($coarsest) = $cost->($high);
        if ($coarsest > $budget) {
            # Not even the coarsest gain fits with these scalefactors: none, then.
            $sf    = [ (0) x @$sf ];
            $sbg   = [ 0, 0, 0 ];
            $pre   = 0;
            $scfsi = _scfsi($sf, $reuse);
            ($compress, $part2) = $self->_scalefactor_bits($sf, $type, 0, $scfsi);
            ($low, $high) = (0, 255);
        }
        while ($high - $low > 1) {
            my $mid = int(($low + $high) / 2);
            my ($b) = $cost->($mid);
            if ($b > $budget) { $low = $mid } else { $high = $mid }
        }
        $gain = $high;
        ($bits, $ix) = $cost->($gain);
    }
    elsif ($bits < $least && $gain > $finest) {
        # bits(low) >= least > bits(high), or low is all there is.
        my ($low, $high) = ($finest, $gain);
        while ($high - $low > 1) {
            my $mid = int(($low + $high) / 2);
            my ($b) = $cost->($mid);
            if ($b >= $least) { $low = $mid } else { $high = $mid }
        }
        $gain = $low;
        ($bits, $ix) = $cost->($gain);
        ($bits, $ix) = $cost->(++$gain) while $bits > $budget;
    }

    my $code = $self->_huffman($ix, 1, $type);
    return {
        ix                => $ix,
        scalefac          => _sent($sf, $pre),
        preflag           => $pre,
        subblock_gain     => $sbg,
        global_gain       => $gain,
        scalefac_scale    => $scale,
        scalefac_compress => $compress,
        block_type        => $type,
        scfsi             => $scfsi,
        part2_length      => $part2,
        part2_3_length    => $part2 + $code->{bits},
        %$code,
    };
}

# A granule of silence.
sub _silent ($type) {
    return {
        ix                => [ (0) x 576 ],
        scalefac          => [ (0) x ($type == SHORT ? 36 : 21) ],
        preflag           => 0,
        subblock_gain     => [ 0, 0, 0 ],
        global_gain       => 0,
        scalefac_scale    => 0,
        scalefac_compress => 0,
        block_type        => $type,
        scfsi             => [ 0, 0, 0, 0 ],
        part2_length      => 0,
        part2_3_length    => 0,
        bits              => 0,
        big_values        => 0,
        count1            => 0,
        table_select      => [ 0, 0, 0 ],
        region0_count     => 0,
        region1_count     => 0,
        count1table       => 0,
    };
}

sub _groups ($self, $type) { return $self->{groups}{ $type == SHORT ? 'short' : 'long' } }

# The finest q at which no line of a group, $top the largest, exceeds LARGEST.
sub _finest ($top) {
    my $q = int(210 + 4 * log($top / LARGEST**(4 / 3)) / log(2)) + 1;
    $q = 0 if $q < 0;
    $q++ while $q < 255 && int($top**0.75 * 2**(-0.1875 * ($q - 210)) + ROUND) > LARGEST;
    return $q;
}

# A group's quantization noise at step q.
sub _noise ($xr, $a34, $lo, $hi, $q) {
    my $step  = 2**(0.25 * ($q - 210));
    my $istep = 2**(-0.1875 * ($q - 210));
    my $sum   = 0.0;
    for my $i ($lo .. $hi - 1) {
        my $ix = int($a34->[$i] * $istep + ROUND);
        $ix = LARGEST if $ix > LARGEST;
        my $d = abs($xr->[$i]) - $POW43[$ix] * $step;
        $sum += $d * $d;
    }
    return $sum;
}

# The lines quantized, as a fresh array.
sub _quantize ($self, $a34, $type, $gain, $sf, $sbg, $scale) {
    my $unit = $scale ? 4 : 2;
    my @ix   = (0) x 576;

    for my $group (@{ $self->_groups($type) }) {
        my ($lo, $hi, $at, undef, $w) = @$group;
        my $q     = $gain - ($at >= 0 ? $unit * $sf->[$at] : 0) - ($w >= 0 ? 8 * $sbg->[$w] : 0);
        my $istep = 2**(-0.1875 * ($q - 210));
        for my $i ($lo .. $hi - 1) {
            my $ix = int($a34->[$i] * $istep + ROUND);
            $ix = LARGEST if $ix > LARGEST;
            $ix[$i] = $ix;
        }
    }
    return \@ix;
}

# The scalefactors as sent: with preflag, less the decoder's table.
sub _sent ($sf, $pre) {
    return $sf if !$pre;
    return [ map { $sf->[$_] - $PRETAB[$_] } 0 .. $#$sf ];
}

# Step 4: which of the four scfsi groups of a long block's scalefactors are
# the same as the first granule's, as [ 0 or 1 ] x 4. None without a first.
sub _scfsi ($sent, $reuse) {
    return [ 0, 0, 0, 0 ] if !$reuse;

    my @same;
    for my $group (@SCFSI) {
        my ($from, $to) = @$group;
        my $differs = grep { $sent->[$_] != $reuse->[$_] } $from .. $to - 1;
        push @same, $differs ? 0 : 1;
    }
    return \@same;
}

# The scfsi group of long block scalefactor $i.
sub _scfsi_group ($i) {
    return 0 if $i < 6;
    return 1 if $i < 11;
    return 2 if $i < 16;
    return 3;
}

# The scalefactors' bits: (scalefac_compress, bits), or nothing where they
# cannot be coded so.
sub _scalefactor_bits ($self, $sf, $type, $pre, $scfsi) {
    return _part2_lsf($sf, $type, $pre) if $self->{lsf};
    return _part2($sf, $type, $scfsi);
}

# MPEG-1: the smallest scalefac_compress that holds the scalefactors. Long
# blocks: bands 0-10 with slen1 bits, 11-20 with slen2. Short: bands 0-5
# (scalefactors 0-17) with slen1, 6-11 (18-35) with slen2. Groups that
# scfsi reuses are not sent.
sub _part2 ($sf, $type, $scfsi = [ 0, 0, 0, 0 ]) {
    my ($split, $first, $second) = $type == SHORT ? (18, 18, 18) : (11, 11, 10);

    for my $g (0 .. 3) {
        next if !$scfsi->[$g];
        my ($from, $to) = @{ $SCFSI[$g] };
        if ($from < 11) { $first -= $to - $from } else { $second -= $to - $from }
    }

    my ($one, $two) = (0, 0);    # the largest of each part
    for my $i (0 .. $#$sf) {
        next if $type != SHORT && $scfsi->[ _scfsi_group($i) ];
        if ($i < $split) { $one = $sf->[$i] if $sf->[$i] > $one }
        else             { $two = $sf->[$i] if $sf->[$i] > $two }
    }

    my ($best, $bits);
    for my $c (0 .. 15) {
        next if (1 << $SLEN1[$c]) <= $one || (1 << $SLEN2[$c]) <= $two;
        my $cost = $first * $SLEN1[$c] + $second * $SLEN2[$c];
        ($best, $bits) = ($c, $cost) if !defined $bits || $cost < $bits;
    }
    return ($best, $bits);
}

# MPEG-2: scalefac_compress chooses a partition of the scalefactors and each
# part's bits (ISO 13818-3, 2.4.3.2): the cheapest that holds them. Table 2
# means preflag; so with preflag only it, and for a long block without, not
# it.
sub _part2_lsf ($sf, $type, $pre) {
    my $row    = $type == SHORT ? 1 : 0;
    my @tables = $pre ? (2) : $type == SHORT ? (0, 1, 2) : (0, 1);
    my ($best, $bits);

    TABLE:
    for my $t (@tables) {
        my $parts = $LSF_PARTS[$t][$row];
        my ($at, $cost, @slen) = (0, 0);
        for my $p (0 .. 3) {
            my $top = max(0, @$sf[ $at .. $at + $parts->[$p] - 1 ]);
            $at += $parts->[$p];

            my $len = 0;
            $len++ while (1 << $len) <= $top;
            next TABLE if $len > $LSF_SLEN_MOST[$t][$p];

            push @slen, $len;
            $cost += $parts->[$p] * $len;
        }
        my $compress = _lsf_compress($t, @slen);
        ($best, $bits) = ($compress, $cost) if !defined $bits || $cost < $bits;
    }
    return defined $bits ? ($best, $bits) : ();
}

# MPEG-2: scalefac_compress for a table and its parts' bits ...
sub _lsf_compress ($t, @slen) {
    return (($slen[0] * 5 + $slen[1]) << 4) + ($slen[2] << 2) + $slen[3] if $t == 0;
    return 400 + (($slen[0] * 5 + $slen[1]) << 2) + $slen[2]           if $t == 1;
    return 500 + $slen[0] * 3 + $slen[1];
}

# ... and back: each part's bands and bits, as the decoder reads them.
sub _lsf_slen ($compress, $type) {
    my $row = $type == SHORT ? 1 : 0;

    if ($compress < 400) {
        my $c = $compress;
        return ($LSF_PARTS[0][$row], [ int(($c >> 4) / 5), ($c >> 4) % 5, ($c >> 2) % 4, $c % 4 ]);
    }
    if ($compress < 500) {
        my $c = $compress - 400;
        return ($LSF_PARTS[1][$row], [ int(($c >> 2) / 5), ($c >> 2) % 5, $c % 4, 0 ]);
    }
    my $c = $compress - 500;
    return ($LSF_PARTS[2][$row], [ int($c / 3), $c % 3, 0, 0 ]);
}

# Step 5: the Huffman coding of the lines. Returns { bits, big_values,
# count1 (the end of the quadruples), table_select, region0_count,
# region1_count, count1table }.
#
# With $exact, a normal long block gets the best regions of all there may
# be; that is done once a granule. Otherwise the regions are known before
# the values are looked at (fixed, or a quick guess).
sub _huffman ($self, $ix, $exact, $type) {
    my @ix = @$ix;

    # The zeros at the top are not coded; below them, the quadruples of
    # ones and zeros.
    my $end = 576;
    $end-- while $end > 0 && $ix[$end - 1] == 0;
    $end++ if $end % 2;
    my $start = $end;
    while ($start >= 4 && $ix[$start - 1] <= 1 && $ix[$start - 2] <= 1 && $ix[$start - 3] <= 1 && $ix[$start - 4] <= 1) {
        $start -= 4;
    }
    my ($count1table, $bits) = _count1(\@ix, $start, $end);

    my $pairs = $start / 2;
    my %code  = (
        big_values    => $pairs,
        count1        => $end,
        count1table   => $count1table,
        region0_count => 0,
        region1_count => 0,
        table_select  => [ 0, 0, 0 ],
    );
    return { %code, bits => $bits } if $pairs == 0;

    my ($regions, $big_bits) = $exact && $type == 0
        ? $self->_best_regions(\@ix, $pairs)
        : $self->_guessed_regions(\@ix, $pairs, $type);
    @code{qw(table_select region0_count region1_count)} = @$regions;

    return { %code, bits => $bits + $big_bits };
}

# The quadruples from $start to $end: the table that codes them shorter (0:
# A, 1: B) and its bits, with the signs.
sub _count1 ($ix, $start, $end) {
    my @len_a = @{ $HUFFMAN[32][2] };
    my ($bits_a, $bits_b) = (0, 0);

    for (my $i = $start; $i < $end; $i += 4) {
        my $signs = $ix->[$i] + $ix->[$i + 1] + $ix->[$i + 2] + $ix->[$i + 3];
        $bits_a += $len_a[ $ix->[$i] * 8 + $ix->[$i + 1] * 4 + $ix->[$i + 2] * 2 + $ix->[$i + 3] ] + $signs;
        $bits_b += 4 + $signs;
    }
    return $bits_b < $bits_a ? (1, $bits_b) : (0, $bits_a);
}

# Where the regions of a block's big values end, in pairs: a normal block's
# from its region counts, a start or stop block's region 0 at the 8th long
# band's end (36 lines at MPEG-1's rates, 54 at MPEG-2's), a short block's
# after 36 lines. Short, start and stop blocks have no third region.
sub _region_ends ($self, $type, $r0, $r1) {
    my $long = $self->{long};
    return ($long->[$r0 + 1] / 2, $long->[$r0 + $r1 + 2] / 2) if $type == 0;
    return (18, 288)                                          if $type == SHORT;
    return ($long->[8] / 2, 288);
}

# The regions as a quick guess, each with the table that codes it shortest:
# ([ \@table_select, region0_count, region1_count ], bits). A normal
# block's regions end at the band edges nearest a third and two thirds of
# the big values.
sub _guessed_regions ($self, $ix, $pairs, $type) {
    my @long = @{ $self->{long} };
    my ($r0, $r1) = (0, 0);
    if ($type == 0) {
        for my $a (0 .. 15) {
            $r0 = $a if $long[$a + 1] / 2 <= $pairs / 3;
        }
        for my $b (0 .. 7) {
            $r1 = $b if $r0 + $b + 2 <= $#long && $long[$r0 + $b + 2] / 2 <= 2 * $pairs / 3;
        }
    }

    my ($one, $two) = $self->_region_ends($type, $r0, $r1);
    $one = min($one, $pairs);
    $two = $type == 0 ? min($two, $pairs) : $pairs;

    my ($t0, $b0) = _region($ix, 0, $one);
    my ($t1, $b1) = _region($ix, $one, $two);
    my ($t2, $b2) = $type == 0 ? _region($ix, $two, $pairs) : (0, 0);

    return ([ [ $t0, $t1, $t2 ], $r0, $r1 ], $b0 + $b1 + $b2);
}

# The best regions of all a normal long block may have, as for
# _guessed_regions.
#
# The code lengths of the big values are summed once per table that has
# lengths of its own (16-23 share theirs, as do 24-31), pair by pair, so
# that what a region costs in a table is a difference of two sums.
sub _best_regions ($self, $ix, $pairs) {
    # Per pair: its place in the tables, its larger value; running sums of
    # the signs and the escapes (values of 15 and more) before it.
    my @place = (0) x $pairs;
    my @big   = (0) x $pairs;
    my @signs = (0) x ($pairs + 1);
    my @esc   = (0) x ($pairs + 1);
    my ($s, $e) = (0, 0);
    for my $p (0 .. $pairs - 1) {
        my $x  = $ix->[2 * $p];
        my $y  = $ix->[2 * $p + 1];
        my $cx = $x > 15 ? 15 : $x;
        my $cy = $y > 15 ? 15 : $y;
        $place[$p] = 16 * $cx + $cy;
        $big[$p]   = $x > $y ? $x : $y;
        $s += ($x > 0 ? 1 : 0) + ($y > 0 ? 1 : 0);
        $e += ($x > 14 ? 1 : 0) + ($y > 14 ? 1 : 0);
        $signs[$p + 1] = $s;
        $esc[$p + 1]   = $e;
    }

    # Running sums of the code lengths: sums[(pairs + 1) c + p], c the
    # table's place in @CODED.
    my $stride = $pairs + 1;
    my @sums   = (0) x ($stride * @CODED);
    my ($c, $p, $sum) = (0, 0, 0);
    for my $n (0 .. @CODED * $pairs - 1) {
        $sum += $LENGTHS[ 256 * $c + $place[$p] ];
        $p++;
        $sums[ $stride * $c + $p ] = $sum;
        if ($p == $pairs) { $p = 0; $sum = 0; $c++ }
    }

    # Where regions may end, in pairs, as far as the big values go: the long
    # bands' edges; and the largest value between each edge and the next.
    my @long = @{ $self->{long} };
    my @edge = map { min($_ / 2, $pairs) } @long;
    my @top  = map { max(0, @big[ $edge[$_] .. $edge[$_ + 1] - 1 ]) } 0 .. $#edge - 1;

    # A region from edge $from to edge $to: its best table and bits.
    my $cost = sub ($from, $to) {
        my ($a, $b) = ($edge[$from], $edge[$to]);
        return (0, 0) if $b <= $a;

        my $m = max(@top[ $from .. $to - 1 ]);
        return (0, 0) if $m == 0;

        my ($best, $least);
        for my $t ($m < 16 ? @{ $SMALL[$m] } : _escape_tables($m)) {
            my $at  = $stride * $CODED_AT[$t];
            my $sum = $sums[ $at + $b ] - $sums[ $at + $a ] + $HUFFMAN[$t][1] * ($esc[$b] - $esc[$a]);
            ($best, $least) = ($t, $sum) if !defined $least || $sum < $least;
        }
        return ($best, $least + $signs[$b] - $signs[$a]);
    };

    # The edge where the big values end.
    my $last = 1;
    $last++ while $edge[$last] < $pairs;

    my $best;
    for my $r0 (0 .. 15) {
        my $one = min($r0 + 1, $last);
        my ($t0, $b0) = $cost->(0, $one);
        for my $r1 (0 .. 7) {
            last if $r0 + $r1 + 2 > $#long;

            my $two = min($r0 + $r1 + 2, $last);
            my ($t1, $b1) = $cost->($one, $two);
            my ($t2, $b2) = $cost->($two, $last);
            my $total = $b0 + $b1 + $b2;
            $best = [ $total, $r0, $r1, $t0, $t1, $t2 ] if !$best || $total < $best->[0];

            last if $two >= $last;
        }
        last if $one >= $last;
    }

    my ($total, $r0, $r1, @tables) = @$best;
    return ([ \@tables, $r0, $r1 ], $total);
}

# A region of big values, pairs $from to $to: the table that codes it
# shortest, and its bits with the signs and the escapes' linbits. One pass
# for its largest value, signs and escapes; one per table that holds the
# largest.
sub _region ($ix, $from, $to) {
    return (0, 0) if $to <= $from;

    my ($m, $signs, $esc) = (0, 0, 0);
    for my $i (2 * $from .. 2 * $to - 1) {
        my $v = $ix->[$i];
        next if !$v;
        $signs++;
        $m = $v if $v > $m;
        $esc++ if $v > 14;
    }
    return (0, 0) if $m == 0;

    my ($best, $least);
    for my $t ($m < 16 ? @{ $SMALL[$m] } : _escape_tables($m)) {
        my $base = 256 * $CODED_AT[$t];
        my $sum  = $HUFFMAN[$t][1] * $esc;
        for my $p ($from .. $to - 1) {
            my $x = $ix->[2 * $p];
            my $y = $ix->[2 * $p + 1];
            $sum += $LENGTHS[ $base + 16 * ($x > 15 ? 15 : $x) + ($y > 15 ? 15 : $y) ];
        }
        ($best, $least) = ($t, $sum) if !defined $least || $sum < $least;
    }
    return ($best, $least + $signs);
}

# The tables for a largest value above 15: of each family the smallest
# whose linbits hold it.
sub _escape_tables ($top) {
    my $need = 0;
    $need++ while (1 << $need) <= $top - 15;

    my @tables;
    for my $family (@ESCAPE) {
        my ($t) = grep { $HUFFMAN[$_][1] >= $need } @$family;
        push @tables, $t if defined $t;
    }
    return @tables;
}

# Writes the granule's main data to a bit writer: the scalefactors (but
# those scfsi reuses), then the Huffman codes. $xr gives the signs.
sub write ($self, $gi, $out, $xr) {
    $self->_write_scalefactors($gi, $out);
    $self->_write_big_values($gi, $out, $xr);
    _write_count1($gi, $out, $xr);
    return;
}

sub _write_scalefactors ($self, $gi, $out) {
    my $sf = $gi->{scalefac};

    if ($self->{lsf}) {
        my ($parts, $slen) = _lsf_slen($gi->{scalefac_compress}, $gi->{block_type});
        my $i = 0;
        for my $p (0 .. 3) {
            for (1 .. $parts->[$p]) {
                $out->put($sf->[$i], $slen->[$p]);
                $i++;
            }
        }
        return;
    }

    my $s1    = $SLEN1[ $gi->{scalefac_compress} ];
    my $s2    = $SLEN2[ $gi->{scalefac_compress} ];
    my $short = $gi->{block_type} == SHORT;
    my $split = $short ? 18 : 11;
    for my $i (0 .. $#$sf) {
        next if !$short && $gi->{scfsi}[ _scfsi_group($i) ];
        $out->put($sf->[$i], $i < $split ? $s1 : $s2);
    }
    return;
}

sub _write_big_values ($self, $gi, $out, $xr) {
    my $ix = $gi->{ix};
    my ($one, $two) = $self->_region_ends($gi->{block_type}, $gi->{region0_count}, $gi->{region1_count});

    for my $p (0 .. $gi->{big_values} - 1) {
        my $region = $p < $one ? 0 : $p < $two ? 1 : 2;
        my $table  = $gi->{table_select}[$region];
        next if $table == 0;

        my (undef, $linbits, $len, $code) = @{ $HUFFMAN[$table] };
        my $x  = $ix->[2 * $p];
        my $y  = $ix->[2 * $p + 1];
        my $cx = $x > 15 ? 15 : $x;
        my $cy = $y > 15 ? 15 : $y;

        $out->put($code->[ $cx * 16 + $cy ], $len->[ $cx * 16 + $cy ]);
        $out->put($x - 15, $linbits)              if $cx == 15 && $linbits;
        $out->put($xr->[2 * $p] < 0 ? 1 : 0, 1)     if $x;
        $out->put($y - 15, $linbits)              if $cy == 15 && $linbits;
        $out->put($xr->[2 * $p + 1] < 0 ? 1 : 0, 1) if $y;
    }
    return;
}

sub _write_count1 ($gi, $out, $xr) {
    my $ix = $gi->{ix};
    my ($len, $code) = @{ $HUFFMAN[32] }[ 2, 3 ];

    for (my $i = 2 * $gi->{big_values}; $i < $gi->{count1}; $i += 4) {
        my $v = $ix->[$i] * 8 + $ix->[$i + 1] * 4 + $ix->[$i + 2] * 2 + $ix->[$i + 3];
        if ($gi->{count1table}) { $out->put(15 - $v, 4) }
        else                    { $out->put($code->[$v], $len->[$v]) }

        for my $k ($i .. $i + 3) {
            $out->put($xr->[$k] < 0 ? 1 : 0, 1) if $ix->[$k];
        }
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MP3::Encode::Quantize - a granule's lines into Layer III's integers and codes

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $q  = Peta::MP3::Encode::Quantize->new(44100);
    my $gi = $q->granule($xr, $allowed, $budget, $least, $block_type);
    $q->write($gi, $writer, $xr);    # its main data

=head1 DESCRIPTION

The quantization and Huffman coding of one granule of one channel, in long
or short blocks: within the noise the psychoacoustic model allows, where
the bits allow it, and within the bits always.

=head1 METHODS

=head2 new

C<new($rate)>: a quantizer for a sample rate.

=head2 granule

C<granule($xr, $allowed, $budget, $least, $type, $before)>: a
granule's lines quantized and coded, within the noise each band may take, at
most C<$budget> bits and at least C<$least> where it would take fewer;
C<$before> the first granule's result for the channel, whose scalefactors
the second may reuse. Returns its side information and quantized values.

=head2 write

C<write($granule, $out, $xr)>: the granule's main data to a bit writer
(the lines give the signs): the scalefactors (but those
reused), then the Huffman codes.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
