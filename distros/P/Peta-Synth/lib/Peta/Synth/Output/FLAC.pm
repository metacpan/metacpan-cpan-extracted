package Peta::Synth::Output::FLAC;
# ABSTRACT: a FLAC encoder in Perl

# A FLAC encoder in Perl. The samples go in blocks of 4096; each channel is
# predicted by the better of the best fixed polynomial predictor (orders 0
# to 4) and a linear predictor (LPC) of up to order 12; stereo is coded as
# left/right, left/side, right/side or mid/side, whichever is smallest; the
# residuals are Rice coded in partitions, each with its own parameter.
# STREAMINFO carries the MD5 of the samples, so `flac -t` verifies a file.
#
# The linear predictor: the block windowed, its autocorrelation,
# Levinson-Durbin for the coefficients of every order, and the order whose
# expected bits are fewest (as libFLAC estimates them); its coefficients
# quantized with the rounding error carried on. Depending on the
# compression level the block is tried through one window or more (the
# whole block, its halves, the block without one of its thirds: six at
# level 8, as flac -8 has them), and the one that codes shortest wins.

use v5.36;
use Digest::MD5;
use List::Util qw(max);
use Peta::Synth::Output;

our $VERSION = '0.2610180';

use constant BLOCK   => 4096;
use constant MAX_LPC => 12;      # the highest order of a linear predictor

# The sample rates a frame header can name; others are in STREAMINFO only.
my %RATE_CODE = (
    8000  => 4,
    16000 => 5,
    22050 => 6,
    24000 => 7,
    32000 => 8,
    44100 => 9,
    48000 => 10,
    88200 => 1,
    96000 => 11,
    176400 => 2,
    192000 => 3,
);

# The CRCs of each byte value: CRC-8 (polynomial 0x07) of the frame
# headers, CRC-16 (0x8005) of the frames.
my (@CRC8, @CRC16);
for my $byte (0 .. 255) {
    my $c = $byte;
    for (1 .. 8) { $c = ($c & 0x80 ? ($c << 1) ^ 0x07 : $c << 1) & 0xff }
    $CRC8[$byte] = $c;

    $c = $byte << 8;
    for (1 .. 8) { $c = ($c & 0x8000 ? ($c << 1) ^ 0x8005 : $c << 1) & 0xffff }
    $CRC16[$byte] = $c;
}

sub crc8 ($bytes) {
    my $c = 0;
    $c = $CRC8[ $c ^ $_ ] for unpack 'C*', $bytes;
    return $c;
}

sub crc16 ($bytes) {
    my $c = 0;
    $c = (($c << 8) & 0xffff) ^ $CRC16[ ($c >> 8) ^ $_ ] for unpack 'C*', $bytes;
    return $c;
}

sub new ($class, $file, %opt) {
    my $bits  = $opt{bits} // 16;
    my $level = $opt{quality} // 5;
    $bits = 24 if $bits == 32;

    die "FLAC is written with 16 or 24 bits, not $bits\n" if $bits != 16 && $bits != 24;
    die "FLAC's level is 0 to 8, not $level\n" if $level !~ /\A[0-8]\z/;

    open my $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    my $self = bless {
        file      => $file,
        fh        => $fh,
        rate      => $opt{rate} // 48000,
        bits      => $bits,
        windows   => _windows_of($level),
        left      => [],    # samples not yet in a frame
        right     => [],
        dither    => 1,     # Peta::Synth::Output::to_integers' state
        md5       => Digest::MD5->new,
        frames    => 0,
        samples   => 0,
        min_frame => 0xffffff,
        max_frame => 0,
    }, $class;

    print {$fh} 'fLaC', $self->_streaminfo;
    return $self;
}

# How many windows a compression level tries the linear predictor through,
# as flac: 0-2 fixed predictors only; 3-5 one window; 6-7 three; 8 six.
sub _windows_of ($level) {
    return 6 if $level >= 8;
    return 3 if $level >= 6;
    return 1 if $level >= 3;
    return 0;
}

# The STREAMINFO block: written first with what is not yet known as zeros,
# and again over it when the file is closed.
sub _streaminfo ($self) {
    my $total = $self->{samples};
    my $info  = join '',
        pack('n n', BLOCK, BLOCK),                                      # the least and most block size
        substr(pack('N', $self->{frames} ? $self->{min_frame} : 0), 1),  # and frame size, 24 bits each
        substr(pack('N', $self->{max_frame}), 1),
        pack('N N',                                                     # 20 bits rate, 3 channels - 1,
            ($self->{rate} << 12) | (1 << 9) | (($self->{bits} - 1) << 4) | (int($total / 2**32) & 0xf),
            $total % 2**32),                                             # 5 bits - 1, 36 the samples
        $self->{done} // "\0" x 16;                                       # the MD5

    return pack('C', 0x80) . substr(pack('N', length $info), 1) . $info;    # the last metadata block
}

# Takes samples (-1 .. 1) of both channels; writes every whole block.
sub write ($self, $left, $right) {
    my $ints = Peta::Synth::Output::to_integers($left, $right, $self->{bits}, \$self->{dither});
    my $n    = @$left;
    push @{ $self->{left} },  @$ints[ map { 2 * $_ } 0 .. $n - 1 ];
    push @{ $self->{right} }, @$ints[ map { 2 * $_ + 1 } 0 .. $n - 1 ];

    while (@{ $self->{left} } >= BLOCK) {
        $self->_frame([ splice @{ $self->{left} }, 0, BLOCK ], [ splice @{ $self->{right} }, 0, BLOCK ]);
    }
    return $self;
}

# Writes the last, shorter block and the final STREAMINFO. Returns the file's name.
sub close ($self) {
    $self->_frame($self->{left}, $self->{right}) if @{ $self->{left} };

    $self->{done} = $self->{md5}->digest;
    my $fh = $self->{fh};
    seek $fh, 4, 0 or die "cannot seek in '$self->{file}': $!\n";
    print {$fh} $self->_streaminfo;
    close $fh or die "cannot write '$self->{file}': $!\n";
    return $self->{file};
}

# A frame number as FLAC writes it: in UTF-8's scheme, up to 36 bits.
sub _utf8_number ($n) {
    return chr $n if $n < 0x80;
    my @cont;
    my $lead_bits = 6;
    while ($n >= (1 << $lead_bits)) {
        unshift @cont, 0x80 | ($n & 0x3f);
        $n >>= 6;
        $lead_bits--;
    }
    my $count = @cont + 1;
    my $lead = ((0xff << (8 - $count)) & 0xff) | $n;
    return pack 'C*', $lead, @cont;
}

# The windows the linear predictors are computed through, for a block of
# $n samples, as flac -8 has them: the whole block (Tukey 0.5); each half
# on its own (partial Tukey); the block with each of its thirds left out
# (punched-out Tukey). Made once per block size.
my %WINDOWS;

sub _windows ($n) {
    return $WINDOWS{$n} if $WINDOWS{$n};

    my @all = (_tukey($n, 0, $n, 0.5), _tukey($n, 0, int($n / 2), 0.5), _tukey($n, int($n / 2), $n, 0.5));
    for my $third (0 .. 2) {
        my $w    = _tukey($n, 0, $n, 0.5);
        my $from = int($n * $third / 3);
        my $to   = int($n * ($third + 1) / 3);
        my $cut  = _tukey($n, $from, $to, 0.2);
        $w->[$_] *= 1 - $cut->[$_] for $from .. $to - 1;
        push @all, $w;
    }
    return $WINDOWS{$n} = \@all;
}

# A window of $n samples: 1 from $from to $to, tapered by a cosine over
# $share of that span at both ends, 0 elsewhere.
sub _tukey ($n, $from, $to, $share) {
    my @w     = (0.0) x $n;
    my $len   = $to - $from;
    my $taper = int($len * $share / 2) || 1;

    for my $i ($from .. $to - 1) {
        my $at = $i - $from;
        $w[$i] = $at < $taper         ? 0.5 - 0.5 * cos(3.141592653589793 * $at / $taper)
               : $at >= $len - $taper ? 0.5 - 0.5 * cos(3.141592653589793 * ($len - 1 - $at) / $taper)
               :                        1.0;
    }
    return \@w;
}

# The linear predictors of a channel, orders 1 to MAX_LPC: [ coefficients,
# expected error ] each, from the windowed block's autocorrelation by
# Levinson-Durbin. Empty for a silent or too short block.
sub _lpc ($x, $window) {
    my $n = scalar @$x;
    return () if $n <= 2 * MAX_LPC;
    my @w = (0.0) x $n;
    $w[$_] = $x->[$_] * $window->[$_] for 0 .. $n - 1;
    my @r = (0.0) x (MAX_LPC + 1);
    for my $k (0 .. MAX_LPC) {
        my $sum = 0.0;
        for my $i ($k .. $n - 1) { $sum += $w[$i] * $w[ $i - $k ] }
        $r[$k] = $sum;
    }
    return () if $r[0] <= 0;
    my @a;
    my $err = $r[0];
    my @out;
    for my $m (1 .. MAX_LPC) {
        my $acc = $r[$m];
        $acc -= $a[ $_ - 1 ] * $r[ $m - $_ ] for 1 .. $m - 1;
        my $k = $acc / $err;
        my @next = @a;
        $next[ $m - 1 ] = $k;
        $next[ $_ - 1 ] = $a[ $_ - 1 ] - $k * $a[ $m - $_ - 1 ] for 1 .. $m - 1;
        @a = @next;
        $err *= 1 - $k * $k;
        last if $err <= 0;
        push @out, [ [@a], $err ];
    }
    return @out;
}

# The coefficients quantized: (\@q, shift), the q of $precision bits with
# sign, the rounding error of each carried into the next.
sub _quantize_lpc ($a, $precision) {
    my $top = max(map { abs } @$a);
    return if $top == 0;

    my $log2 = int(log($top) / log(2)) + 1;    # as frexp's exponent
    my $shift = $precision - 1 - $log2;
    $shift = 15 if $shift > 15;
    return if $shift < 0;
    my $most  = (1 << ($precision - 1)) - 1;
    my $least = -(1 << ($precision - 1));
    my ($error, @q) = (0.0);
    for my $c (@$a) {
        $error += $c * (1 << $shift);
        my $q = $error < 0 ? -int(-$error + 0.5) : int($error + 0.5);
        $q = $most if $q > $most;
        $q = $least if $q < $least;
        $error -= $q;
        push @q, $q;
    }
    return (\@q, $shift);
}

# The residual of a linear predictor, from sample $order on: integers, the
# prediction shifted right arithmetically (as FLAC's decoders do). One flat
# loop over sample and coefficient.
sub _lpc_residual ($xref, $qref, $shift) {
    use integer;
    my @x = @$xref;
    my @q = @$qref;
    my $order = scalar @q;
    my $n = scalar @x;
    my @r = (0) x ($n - $order);
    my ($i, $j, $sum) = ($order, 0, 0);
    for my $step (0 .. ($n - $order) * $order - 1) {
        $sum += $q[$j] * $x[ $i - 1 - $j ];
        $j++;
        if ($j == $order) {
            $r[ $i - $order ] = $x[$i] - ($sum >> $shift);
            $j = 0;
            $sum = 0;
            $i++;
        }
    }
    return \@r;
}

# The order of a channel's linear predictor whose expected bits are fewest,
# its coefficients and expected cost (libFLAC's estimate: half the log of
# the error per sample, per sample); or nothing.
sub _best_lpc ($x, $bps, $precision, $window = _windows(scalar @$x)->[0]) {
    my $n = scalar @$x;
    my ($best, $cost);
    for my $one (_lpc($x, $window)) {
        my ($a, $err) = @$one;
        my $order = @$a;
        my $per = $err > 0 ? 0.5 * log(0.5 / $n * $err) / log(2) : 0;
        $per = 0 if $per < 0;
        my $bits = $per * ($n - $order) + $order * ($bps + $precision);
        ($best, $cost) = ($a, $bits) if !defined $cost || $bits < $cost;
    }
    return $best ? ($best, $cost) : ();
}

# The residual of fixed predictor $order (0 to 4), from sample $order on:
# the samples' differences of that order.
sub _residual ($x, $order) {
    my $n = scalar @$x;
    return [@$x] if $order == 0;

    my @r = (0) x ($n - $order);
    if ($order == 1) {
        for my $i (1 .. $n - 1) {
            $r[$i - 1] = $x->[$i] - $x->[$i - 1];
        }
    }
    elsif ($order == 2) {
        for my $i (2 .. $n - 1) {
            $r[$i - 2] = $x->[$i] - 2 * $x->[$i - 1] + $x->[$i - 2];
        }
    }
    elsif ($order == 3) {
        for my $i (3 .. $n - 1) {
            $r[$i - 3] = $x->[$i] - 3 * $x->[$i - 1] + 3 * $x->[$i - 2] - $x->[$i - 3];
        }
    }
    else {
        for my $i (4 .. $n - 1) {
            $r[$i - 4] = $x->[$i] - 4 * $x->[$i - 1] + 6 * $x->[$i - 2] - 4 * $x->[$i - 3] + $x->[$i - 4];
        }
    }
    return \@r;
}

# The best fixed order for a channel, by the smallest sum of its residual's
# magnitudes: the order and that sum. All five orders are measured in one
# pass, each order's error the difference of the previous one's (as
# libFLAC does); only the chosen order's residual is built later.
sub _best ($x) {
    my $n = scalar @$x;
    return (0, 0) if $n < 5;
    my ($s0, $s1, $s2, $s3, $s4) = (0, 0, 0, 0, 0);
    my $p1 = $x->[3] - $x->[2];
    my $p2 = $p1 - ($x->[2] - $x->[1]);
    my $p3 = $p2 - ($x->[2] - $x->[1] - ($x->[1] - $x->[0]));
    for my $i (4 .. $n - 1) {
        my $e0 = $x->[$i];
        my $e1 = $e0 - $x->[ $i - 1 ];
        my $e2 = $e1 - $p1;
        my $e3 = $e2 - $p2;
        my $e4 = $e3 - $p3;
        $s0 += abs($e0);
        $s1 += abs($e1);
        $s2 += abs($e2);
        $s3 += abs($e3);
        $s4 += abs($e4);
        $p1 = $e1;
        $p2 = $e2;
        $p3 = $e3;
    }
    my ($order, $sum) = (0, $s0);
    ($order, $sum) = (1, $s1) if $s1 < $sum;
    ($order, $sum) = (2, $s2) if $s2 < $sum;
    ($order, $sum) = (3, $s3) if $s3 < $sum;
    ($order, $sum) = (4, $s4) if $s4 < $sum;
    return ($order, $sum);
}

# Roughly the bits of a residual of $count values summing to $sum in magnitude.
sub _estimate ($sum, $count) {
    return $count unless $count && $sum > $count;
    return $count * (1 + log($sum / $count) / log(2) + 0.5);
}

# How to Rice code a residual: the partition order and each partition's
# parameter, and about how many bits that takes: [ order, \@params,
# \@folded, bits ]. The sums of the finest partitions are taken once and
# merged for the coarser ones; a partition's parameter is the one its mean
# suggests (an exact search for the cheapest gains a tenth of a per cent).
# Parameters above 14 need the five-bit form (RICE2).
sub _rice_plan ($r, $block, $order) {
    my @u = map { $_ >= 0 ? 2 * $_ : -2 * $_ - 1 } @$r;
    my $finest = 0;
    $finest++ while $finest < 8 && !($block % (2 << $finest)) && $block / (2 << $finest) > $order;
    my $parts = 1 << $finest;
    my $len   = $block / $parts;
    my (@sum, @count);
    my $at = 0;
    for my $p (0 .. $parts - 1) {
        my $count = $p == 0 ? $len - $order : $len;
        my $s = 0;
        $s += $u[$_] for $at .. $at + $count - 1;
        push @sum, $s;
        push @count, $count;
        $at += $count;
    }
    my ($best_bits, $best);
    for (my $porder = $finest; $porder >= 0; $porder--) {
        my ($bits, @params) = (0);
        for my $p (0 .. $#sum) {
            my ($s, $count) = ($sum[$p], $count[$p]);
            my $k = $count && $s > $count ? int(log($s / $count) / log(2)) : 0;
            $k = 30 if $k > 30;
            push @params, $k;
            $bits += $count * ($k + 1) + ($k ? $s / (1 << $k) : $s) + 5;
        }
        ($best_bits, $best) = ($bits, [ $porder, \@params, \@u, $bits ]) if !defined $best_bits || $bits < $best_bits;
        last if $porder == 0;
        # The next coarser order: neighbouring partitions merged.
        @sum   = map { $sum[ 2 * $_ ] + $sum[ 2 * $_ + 1 ] } 0 .. @sum / 2 - 1;
        @count = map { $count[ 2 * $_ ] + $count[ 2 * $_ + 1 ] } 0 .. @count / 2 - 1;
    }
    return $best;
}

# The bits of a frame: a writer that gathers them in an integer and moves
# them out 32 at a time, as whole words. [acc, count, \@words]
sub _bits () { return [ 0, 0, [] ] }

sub _put ($w, $value, $count) {
    my ($acc, $have, $words) = @$w;
    while ($count > 24) {    # wide values in two pieces, so the integer never overflows
        _put($w, $value >> 16, $count - 16);
        ($acc, $have) = @$w;
        $value &= 0xffff;
        $count = 16;
    }
    $acc = ($acc << $count) | ($value & ((1 << $count) - 1));
    $have += $count;
    if ($have >= 32) {
        $have -= 32;
        push @$words, $acc >> $have;
        $acc &= (1 << $have) - 1;
    }
    @$w[ 0, 1 ] = ($acc, $have);
    return;
}

# The bytes, padded with zero bits to a whole byte.
sub _bytes ($w) {
    my ($acc, $have, $words) = @$w;
    my $out = pack 'N*', @$words;
    $acc <<= (8 - $have % 8) % 8;
    $have += (8 - $have % 8) % 8;
    $out .= substr(pack('N', $acc), 4 - $have / 8) if $have;
    return $out;
}

# A subframe: $coding { order, residual, plan, and for LPC q, shift, precision }.
sub _subframe ($w, $coding, $x, $bps) {
    my $order = $coding->{order};
    my ($porder, $params, $u) = @{ $coding->{plan} };
    my $wide = grep { $_ > 14 } @$params;
    if ($coding->{q}) {
        _put($w, (32 | ($order - 1)) << 1, 8);    # zero bit, LPC and its order, no wasted bits
        _put($w, $x->[$_] & 0xffffffff, $bps) for 0 .. $order - 1;
        _put($w, $coding->{precision} - 1, 4);
        _put($w, $coding->{shift}, 5);
        _put($w, $_ & ((1 << $coding->{precision}) - 1), $coding->{precision}) for @{ $coding->{q} };
    }
    else {
        _put($w, (8 | $order) << 1, 8);          # zero bit, FIXED and its order, no wasted bits
        _put($w, $x->[$_] & 0xffffffff, $bps) for 0 .. $order - 1;
    }
    _put($w, ($wide ? 1 : 0) << 4 | $porder, 6);
    my $param_bits = $wide ? 5 : 4;
    my $at  = 0;
    my $len = @$x / (1 << $porder);
    my ($acc, $have, $words) = @$w;
    for my $p (0 .. $#$params) {
        my $k = $params->[$p];
        my $count = $p == 0 ? $len - $order : $len;
        @$w[ 0, 1 ] = ($acc, $have);
        _put($w, $k, $param_bits);
        ($acc, $have) = @$w;
        my $mask = (1 << $k) - 1;
        # Each value: its quotient in unary (that many zeros, then a one), then
        # its k low bits. The writer of _put, inlined.
        for my $i ($at .. $at + $count - 1) {
            my $v = $u->[$i];
            my $q = $v >> $k;
            while ($q >= 24) {
                $acc <<= 24;
                $have += 24;
                $q -= 24;
                if ($have >= 32) {
                    $have -= 32;
                    push @$words, $acc >> $have;
                    $acc &= (1 << $have) - 1;
                }
            }
            my $n = $q + 1 + $k;
            if ($n > 32) {
                $acc = ($acc << ($q + 1)) | 1;
                $have += $q + 1;
                if ($have >= 32) {
                    $have -= 32;
                    push @$words, $acc >> $have;
                    $acc &= (1 << $have) - 1;
                }
                $n   = $k;
                $acc = ($acc << $n) | ($v & $mask);
            }
            else {
                $acc = ($acc << $n) | (1 << $k) | ($v & $mask);
            }
            $have += $n;
            if ($have >= 32) {
                $have -= 32;
                push @$words, $acc >> $have;
                $acc &= (1 << $have) - 1;
            }
        }
        $at += $count;
    }
    @$w[ 0, 1 ] = ($acc, $have);
    return;
}

# How a chosen channel is coded: the fixed predictor's residual, and where
# the estimate preferred a linear predictor, its residual too; whichever
# Rice codes in fewer bits.
sub _coding ($c, $precision, $windows) {
    my $n = scalar @{ $c->{x} };
    my $fixed = { order => $c->{order} };
    $fixed->{plan} = _rice_plan(_residual($c->{x}, $c->{order}), $n, $c->{order});
    $fixed->{bits} = $fixed->{plan}[3] + $c->{order} * $c->{bps};
    return $fixed if !$c->{lpc};
    # The linear predictor through each window, the one that codes shortest.
    my $best = $fixed;
    for my $window (@{ _windows($n) }[ 0 .. $windows - 1 ]) {
        my ($a) = _best_lpc($c->{x}, $c->{bps}, $precision, $window);
        my ($q, $shift) = $a ? _quantize_lpc($a, $precision) : ();
        next if !$q;
        my $order = @$q;
        my $lpc = { order => $order, q => $q, shift => $shift, precision => $precision };
        $lpc->{plan} = _rice_plan(_lpc_residual($c->{x}, $q, $shift), $n, $order);
        $lpc->{bits} = $lpc->{plan}[3] + $order * ($c->{bps} + $precision) + 9;
        $best = $lpc if $lpc->{bits} < $best->{bits};
    }
    return $best;
}

# Codes and writes a frame of the samples, as integers.
sub _frame ($self, $left, $right) {
    my $n    = scalar @$left;
    my $bits = $self->{bits};
    $self->_add_md5($left, $right);

    # The four channels the stereo codings choose from. Mid is the sum
    # shifted right arithmetically (FLAC rounds towards minus infinity):
    # Perl's >> is unsigned unless under integer.
    my %x = (left => $left, right => $right);
    $x{side} = [ map { $left->[$_] - $right->[$_] } 0 .. $n - 1 ];
    $x{mid}  = do { use integer; [ map { ($left->[$_] + $right->[$_]) >> 1 } 0 .. $n - 1 ] };

    my $precision = $bits == 16 ? 12 : 14;
    my %coded     = map { $_ => $self->_estimated($x{$_}, $bits + ($_ eq 'side' ? 1 : 0), $precision) } keys %x;

    # At level 8 all four are coded and their sizes compared, as libFLAC
    # does; below, the estimates decide (half a per cent larger, 40 per cent
    # faster).
    my %coding;
    if ($self->{windows} >= 6) {
        for my $name (keys %coded) {
            $coding{$name} = _coding($coded{$name}, $precision, $self->{windows});
            $coded{$name}{cost} = $coding{$name}{bits};
        }
    }

    # The stereo coding whose two channels are smallest.
    my @choice = sort { $a->[0] <=> $b->[0] } (
        [ $coded{left}{cost} + $coded{right}{cost}, 1,  qw(left right) ],
        [ $coded{left}{cost} + $coded{side}{cost},  8,  qw(left side) ],
        [ $coded{side}{cost} + $coded{right}{cost}, 9,  qw(side right) ],
        [ $coded{mid}{cost}  + $coded{side}{cost},  10, qw(mid side) ],
    );
    my (undef, $assignment, @channels) = @{ $choice[0] };

    my $w = _bits();
    for my $name (@channels) {
        my $c = $coded{$name};
        _subframe($w, $coding{$name} // _coding($c, $precision, $self->{windows}), $c->{x}, $c->{bps});
    }
    my $frame = $self->_frame_header($n, $assignment) . _bytes($w);
    $frame .= pack('n', crc16($frame));

    print { $self->{fh} } $frame;
    my $size = length $frame;
    $self->{min_frame} = $size if $size < $self->{min_frame};
    $self->{max_frame} = $size if $size > $self->{max_frame};
    $self->{frames}++;
    $self->{samples} += $n;
    return;
}

# Adds a block's samples to the MD5: little-endian, interleaved.
sub _add_md5 ($self, $left, $right) {
    my $inter = Peta::Synth::Output::interleave($left, $right);
    my $bytes = $self->{bits} == 16 ? pack('s<*', @$inter) : join '', map { substr pack('l<', $_), 0, 3 } @$inter;
    $self->{md5}->add($bytes);
    return;
}

# A channel's best fixed predictor and, where the estimate prefers it, its
# best linear one: { x, bps, order, cost, lpc }.
sub _estimated ($self, $x, $bps, $precision) {
    my ($order, $sum) = _best($x);
    my $coded = {
        x     => $x,
        bps   => $bps,
        order => $order,
        cost  => _estimate($sum, @$x - $order) + $order * $bps,
    };
    my ($a, $cost) = $self->{windows} ? _best_lpc($x, $bps, $precision) : ();
    @$coded{qw(lpc cost)} = ($a, $cost) if $a && $cost < $coded->{cost};

    return $coded;
}

# A frame's header: its block size, rate, stereo coding, sample size and
# number, and its CRC-8.
sub _frame_header ($self, $n, $assignment) {
    my $size_code = $n == BLOCK ? 12 : 7;    # 7: the size follows, 16 bits
    my $rate_code = $RATE_CODE{ $self->{rate} } // 0;
    my $bits_code = $self->{bits} == 16 ? 4 : 6;

    my $header = join '',
        pack('n', 0xfff8),                         # sync, fixed block size
        pack('C', ($size_code << 4) | $rate_code),
        pack('C', ($assignment << 4) | ($bits_code << 1)),
        _utf8_number($self->{frames});
    $header .= pack('n', $n - 1) if $size_code == 7;

    return $header . pack('C', crc8($header));
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Output::FLAC - a FLAC encoder in Perl

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $out = Peta::Synth::Output::FLAC->new('song.flac', rate => 48000, bits => 24);
    $out->write(\@left, \@right);       # floats in -1 .. 1, as often as needed
    $out->close;

=head1 DESCRIPTION

Writes FLAC files with no program or library outside Perl: blocks of 4096
samples, the better of fixed predictors (orders 0 to 4) and linear
predictors (up to order 12), the best of four stereo codings, partitioned
Rice coding, and the MD5 of the samples in STREAMINFO. Usually
opened through L<Peta::Synth::Output>.

=head1 METHODS

=head2 new

C<< new($file, rate => ..., bits => 16 or 24, quality => 5) >>. C<quality>
is the compression level, 0 to 8, as flac's: 0-2 fixed predictors only,
3-5 also a linear predictor through one window, 6-7 through three, 8
through six, with the stereo coding chosen by coding all four channels
(as C<flac -8>; about four and a half times the time of 5, files 1-3%
smaller). Level 5 makes files as large as C<flac -5>, level 8 within half a
per cent of C<flac -8>.

=head2 write

C<write(\@left, \@right)>: takes samples (-1 .. 1) of both channels;
writes each block of 4096 as it is complete.

=head2 close

Writes the last, shorter block and the final STREAMINFO (its sizes,
samples and MD5); returns the file name.

=head1 FUNCTIONS

=head2 crc8, crc16

The checksums of FLAC frame headers and frames.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
