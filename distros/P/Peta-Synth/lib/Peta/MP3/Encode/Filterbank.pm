package Peta::MP3::Encode::Filterbank;
# ABSTRACT: samples into Layer III's frequency lines

# Turns a channel's samples into the lines Layer III quantizes, a granule
# (576 samples) at a time:
#
#   subbands   the polyphase filterbank of ISO 11172-3: a 512-tap window and
#              a matrixing into 32 subbands, 18 samples each
#   mdct       per subband, over the previous granule's 18 samples and these
#              18, in the window of the block type:
#                0  normal   36 samples, 18 lines
#                1  start    long, then half of a short window
#                2  short    three MDCTs of 12 samples, 6 lines each
#                3  stop     the reverse of start
#              then, in long blocks, the butterflies that reduce the
#              aliasing between neighbouring subbands
#
# Long blocks come out in frequency order, line 18 sb + k. Short blocks
# come out in the order the bitstream has them: band by band, in each band
# window 0, 1, 2, each window's lines in frequency order.
#
# The functions after new() define the filterbank's arithmetic; the PDL
# filterbank builds its matrices from them too.
#
# Written for pperl's JIT. Each stage is one long loop that keeps its own
# counters (the JIT leaves short nested loops to the interpreter), reads
# lexical copies of the tables, and has no list assignments, bit operations
# or calls inside.

use v5.36;
use Peta::MP3::Encode::Tables;

our $VERSION = '0.2610180';

use constant PI    => 3.141592653589793;
use constant SHORT => 2;    # the block type of short blocks

my @C    = @Peta::MP3::Encode::Tables::WINDOW;
my @M    = map { matrixing(int($_ / 64), $_ % 64) } 0 .. 2047;    # M[64 sb + k]
my @SIGN = map { sign(int($_ / 32), $_ % 32) } 0 .. 575;          # SIGN[32 t + sb]

# Each long window's MDCT, LONG{type}[36 m + k]; the short one's, SHORT[12 m + k].
my %LONG  = map { my $type = $_; ($type => [ map { long_mdct($type, int($_ / 36), $_ % 36) } 0 .. 647 ]) } 0, 1, 3;
my @SHORT = map { short_mdct(int($_ / 12), $_ % 12) } 0 .. 71;

my ($CS, $CA) = butterflies();

sub new ($class, $rate) {
    return bless {
        history  => [ (0.0) x 480 ],    # the samples the window still reaches back to
        previous => [ (0.0) x 576 ],    # the last granule's subband samples
        order    => short_order($rate),
    }, $class;
}

# The matrixing of 64 windowed sums into subband $sb, at sum $k.
sub matrixing ($sb, $k) { return cos((2 * $sb + 1) * ($k - 16) * PI / 64) }

# The filterbank inverts every other subband in every other step: the sign
# that undoes it, for step $t of subband $sb.
sub sign ($t, $sb) { return ($sb % 2 && $t % 2) ? -1.0 : 1.0 }

# A long block's window, at input $k of 36. The start and stop windows join
# a long half and a short one.
sub long_window ($type, $k) {
    my $long = sin(PI / 36 * ($k + 0.5));

    return $long if $type == 0;

    if ($type == 1) {
        return $long                         if $k < 18;
        return 1.0                           if $k < 24;
        return sin(PI / 12 * ($k + 0.5 - 18)) if $k < 30;
        return 0.0;
    }

    return 0.0                               if $k < 6;
    return sin(PI / 12 * ($k + 0.5 - 6))     if $k < 12;
    return 1.0                               if $k < 18;
    return $long;
}

# The long MDCT through a block type's window: input $k's share of line $m.
sub long_mdct ($type, $m, $k) {
    return long_window($type, $k) * cos(PI / 72 * (2 * $k + 1 + 18) * (2 * $m + 1)) / 9;
}

# The short MDCT through its window: input $k's share of line $m (of 6).
sub short_mdct ($m, $k) {
    return sin(PI / 12 * ($k + 0.5)) * cos(PI / 24 * (2 * $k + 1 + 6) * (2 * $m + 1)) / 3;
}

# The aliasing butterflies' coefficients (Table B.9): (\@cs, \@ca).
sub butterflies () {
    my @c = (-0.6, -0.535, -0.33, -0.185, -0.095, -0.041, -0.0142, -0.0037);
    return ([ map { 1 / sqrt(1 + $_ * $_) } @c ], [ map { $_ / sqrt(1 + $_ * $_) } @c ]);
}

# Where each line of a short block, in the bitstream's order, is found among
# the MDCT's lines: line 6 sb + m of window w is MDCT line 18 sb + 3 m + w.
sub short_order ($rate) {
    my $bands = $Peta::MP3::Encode::Tables::BANDS{$rate} // die "no scalefactor bands for $rate Hz\n";
    my @short = @{ $bands->{short} };
    my @order;

    for my $b (0 .. $#short - 1) {
        for my $w (0 .. 2) {
            for my $f ($short[$b] .. $short[$b + 1] - 1) {
                push @order, 18 * int($f / 6) + 3 * ($f % 6) + $w;
            }
        }
    }
    return \@order;
}

# The lines of the next granule of 576 samples, in a block type's window.
sub granule ($self, $samples, $type) {
    my $sub = $self->subbands($samples);
    my $xr  = $self->mdct($self->{previous}, $sub, $type);
    $self->{previous} = $sub;
    return $xr;
}

# A granule of 576 samples into 18 samples of each of the 32 subbands:
# sub[32 t + sb].
sub subbands ($self, $new) {
    my @buf  = (@{ $self->{history} }, @$new);    # 1056 samples, oldest first
    my @C    = @C;
    my @M    = @M;
    my @SIGN = @SIGN;

    # The windowed sums, 64 for each of the 18 steps: y[64 t + i].
    my @y = (0.0) x 1152;
    my ($t, $i, $j, $sum) = (0, 0, 0, 0.0);
    for my $n (0 .. 9215) {
        $sum += $C[ $i + 64 * $j ] * $buf[ 511 + 32 * $t - $i - 64 * $j ];
        $j++;
        if ($j == 8) {
            $y[ 64 * $t + $i ] = $sum;
            $j   = 0;
            $sum = 0.0;
            $i++;
            if ($i == 64) { $i = 0; $t++ }
        }
    }

    # The matrixing.
    my @sub = (0.0) x 576;
    my ($sb, $k) = (0, 0);
    $t = 0;
    for my $n (0 .. 36863) {
        $sum += $M[ 64 * $sb + $k ] * $y[ 64 * $t + $k ];
        $k++;
        if ($k == 64) {
            $sub[ 32 * $t + $sb ] = $sum * $SIGN[ 32 * $t + $sb ];
            $k   = 0;
            $sum = 0.0;
            $sb++;
            if ($sb == 32) { $sb = 0; $t++ }
        }
    }

    $self->{history} = [ @buf[ 576 .. 1055 ] ];
    return \@sub;
}

# The lines of a granule, from its subband samples and the previous
# granule's, in a block type's window.
sub mdct ($self, $previous, $current, $type) {
    # The 36 inputs of every subband side by side: in[36 sb + k].
    my @in = (0.0) x 1152;
    my ($sb, $k) = (0, 0);
    for my $n (0 .. 575) {
        $in[ 36 * $sb + $k ]      = $previous->[ 32 * $k + $sb ];
        $in[ 36 * $sb + $k + 18 ] = $current->[ 32 * $k + $sb ];
        $k++;
        if ($k == 18) { $k = 0; $sb++ }
    }

    return $self->_short(\@in) if $type == SHORT;
    return _long(\@in, $LONG{$type});
}

# A long block: the MDCT of every subband, then the butterflies.
sub _long ($inref, $wref) {
    my @in = @$inref;
    my @W  = @$wref;
    my @xr = (0.0) x 576;
    my ($sb, $m, $k, $sum) = (0, 0, 0, 0.0);
    for my $n (0 .. 20735) {
        $sum += $W[ 36 * $m + $k ] * $in[ 36 * $sb + $k ];
        $k++;
        if ($k == 36) {
            $xr[ 18 * $sb + $m ] = $sum;
            $k   = 0;
            $sum = 0.0;
            $m++;
            if ($m == 18) { $m = 0; $sb++ }
        }
    }

    # The butterflies between each subband and the next, 8 pairs of lines
    # about each boundary.
    my @CS = @$CS;
    my @CA = @$CA;
    my $i = 0;
    $sb = 1;
    for my $n (0 .. 247) {
        my $up   = 18 * $sb - 1 - $i;
        my $down = 18 * $sb + $i;
        my $bu   = $xr[$up];
        my $bd   = $xr[$down];
        $xr[$up]   = $bu * $CS[$i] + $bd * $CA[$i];
        $xr[$down] = $bd * $CS[$i] - $bu * $CA[$i];
        $i++;
        if ($i == 8) { $i = 0; $sb++ }
    }
    return \@xr;
}

# A short block: three MDCTs per subband, over inputs 6 .. 17, 12 .. 23 and
# 18 .. 29; then the lines in the bitstream's order.
sub _short ($self, $inref) {
    my @in   = @$inref;
    my @S    = @SHORT;
    my @mdct = (0.0) x 576;
    my ($sb, $w, $m, $k, $sum) = (0, 0, 0, 0, 0.0);
    for my $n (0 .. 6911) {
        $sum += $S[ 12 * $m + $k ] * $in[ 36 * $sb + 6 + 6 * $w + $k ];
        $k++;
        if ($k == 12) {
            $mdct[ 18 * $sb + 3 * $m + $w ] = $sum;
            $k   = 0;
            $sum = 0.0;
            $m++;
            if ($m == 6) {
                $m = 0;
                $w++;
                if ($w == 3) { $w = 0; $sb++ }
            }
        }
    }
    return [ @mdct[ @{ $self->{order} } ] ];
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MP3::Encode::Filterbank - samples into Layer III's frequency lines

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $bank = Peta::MP3::Encode::Filterbank->new(44100);    # one per channel
    my $xr   = $bank->granule(\@samples, $block_type);      # 576 samples, -1 .. 1

=head1 DESCRIPTION

The polyphase filterbank, the MDCT in its four windows and the aliasing
butterflies of ISO 11172-3, in plain Perl. Each bank keeps what the next
granule needs, so a channel needs its own. Short blocks come out in the
bitstream's order (band, window, line).

L<Peta::MP3::Encode::Filterbank::PDL> computes the same with PDL, from the
functions C<matrixing>, C<sign>, C<long_window>, C<long_mdct>,
C<short_mdct>, C<butterflies> and C<short_order> here.

=head1 METHODS

=head2 new

C<new($rate)>: a bank for a sample rate, with nothing before the first
granule.

=head2 granule

C<granule(\@samples, $type)>: the lines of the next granule of 576
samples, in a block type's window.

=head2 subbands, mdct

Its steps: a granule of 576 samples into 18 samples of each of the 32
subbands (C<sub[32 t + sb]>); the lines of a granule from its subband
samples and the previous granule's, in a block type's window.

=head1 FUNCTIONS

=head2 matrixing, sign

C<matrixing($sb, $k)>: the matrixing of 64 windowed sums into subband
C<$sb>, at sum C<$k>; C<sign($sb, $t)>: the sign that undoes the
filterbank's inverting every other subband in every other step.

=head2 long_window, long_mdct, short_mdct

A long block's window at input C<$k> of 36 (the start and stop windows
join a long half and a short one); the long MDCT through a block type's
window, input C<$k>'s share of line C<$m>; the short MDCT's, of line
C<$m> of 6.

=head2 butterflies, short_order

The aliasing butterflies' coefficients (Table B.9), C<(\@cs, \@ca)>;
where each line of a short block in the bitstream's order is among the
MDCT's (line 6 sb + m of window w is MDCT line 18 sb + 3 m + w).

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
