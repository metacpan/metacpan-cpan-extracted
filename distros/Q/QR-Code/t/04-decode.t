use strict;
use warnings;
use Test::More;
use QR::Code;

# A complete pure-Perl decoder: format, unmask, zigzag walk,
# de-interleave, Reed-Solomon syndrome check, payload extraction. Every
# table here is retyped from the specification rather than shared with
# the C, so an error in either implementation breaks the round-trip.
#
# History note: a decoder like this one originally AGREED with a broken
# encoder, because both were written from the same misreading of the
# format bit order. The convention is now pinned independently in
# t/03-format.t against the published 0x5412 anchor; this file's job is
# everything downstream of it.

my %RS = (      # [ec_per_block, g1_blocks, g1_data, g2_blocks, g2_data]
    '1,L'=>[7,1,19,0,0],   '1,M'=>[10,1,16,0,0],  '1,Q'=>[13,1,13,0,0],  '1,H'=>[17,1,9,0,0],
    '2,L'=>[10,1,34,0,0],  '2,M'=>[16,1,28,0,0],  '2,Q'=>[22,1,22,0,0],  '2,H'=>[28,1,16,0,0],
    '3,L'=>[15,1,55,0,0],  '3,M'=>[26,1,44,0,0],  '3,Q'=>[18,2,17,0,0],  '3,H'=>[22,2,13,0,0],
    '4,L'=>[20,1,80,0,0],  '4,M'=>[18,2,32,0,0],  '4,Q'=>[26,2,24,0,0],  '4,H'=>[16,4,9,0,0],
    '5,L'=>[26,1,108,0,0], '5,M'=>[24,2,43,0,0],  '5,Q'=>[18,2,15,2,16], '5,H'=>[22,2,11,2,12],
    '7,L'=>[20,2,78,0,0],  '7,M'=>[18,4,31,0,0],  '7,Q'=>[18,2,14,4,15], '7,H'=>[26,4,13,1,14],
    '10,L'=>[18,2,68,2,69],'10,M'=>[26,4,43,1,44],'10,Q'=>[24,6,19,2,20],'10,H'=>[28,6,15,2,16],
    '14,L'=>[30,3,115,1,116],'14,M'=>[24,4,40,5,41],'14,Q'=>[20,11,16,5,17],'14,H'=>[24,11,12,5,13],
    '15,L'=>[22,5,87,1,88],'15,M'=>[24,5,41,5,42],'15,Q'=>[30,5,24,7,25],'15,H'=>[24,11,12,7,13],
);
my %ALIGN = (
    1=>[], 2=>[6,18], 3=>[6,22], 4=>[6,26], 5=>[6,30], 7=>[6,22,38],
    10=>[6,28,50], 14=>[6,26,46,66], 15=>[6,26,48,70],
);
my %ECCBITS = (L => 1, M => 0, Q => 3, H => 2);   # format-field encoding
my %ECCNUM  = (L => 0, M => 1, Q => 2, H => 3);   # the encoder's own order

my (@E, @L);
{ my $x = 1;
  for my $i (0 .. 254) { $E[$i] = $x; $L[$x] = $i; $x <<= 1; $x ^= 0x11D if $x & 0x100 } }
sub gmul { my ($a, $b) = @_; ($a && $b) ? $E[($L[$a] + $L[$b]) % 255] : 0 }

sub decode {
    my ($m, $v, $ecc) = @_;
    my $size = @$m;

    # function map
    my @fx = map { [ (0) x $size ] } 1 .. $size;
    my $mark = sub {
        my ($r, $c) = @_;
        $fx[$r][$c] = 1 if $r >= 0 && $c >= 0 && $r < $size && $c < $size;
    };
    for my $o ([0,0], [0,$size-7], [$size-7,0]) {
        for my $r (-1..7) { for my $c (-1..7) { $mark->($o->[0]+$r, $o->[1]+$c) } }
    }
    for my $i (0..$size-1) { $mark->(6,$i); $mark->($i,6) }
    my @a = @{ $ALIGN{$v} };
    for my $r (@a) { for my $c (@a) {
        next if ($r==6 && $c==6) || ($r==6 && $c==$a[-1]) || ($r==$a[-1] && $c==6);
        for my $dr (-2..2) { for my $dc (-2..2) { $mark->($r+$dr, $c+$dc) } }
    } }
    for my $i (0..8) { next if $i == 6; $mark->(8,$i); $mark->($i,8) }
    $mark->(8,6); $mark->(6,8);   # timing modules inside the format band
    for my $i (0..7) { $mark->(8,$size-1-$i); $mark->($size-1-$i,8) }
    $mark->($size-8, 8);
    if ($v >= 7) {
        for my $i (0..17) {
            $mark->(int($i/3), $size-11 + $i%3);
            $mark->($size-11 + $i%3, int($i/3));
        }
    }

    # format: first copy, MSB first
    my @c1 = ([8,0],[8,1],[8,2],[8,3],[8,4],[8,5],[8,7],[8,8],
              [7,8],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8]);
    my $f = 0;
    $f = ($f << 1) | $m->[$_->[0]][$_->[1]] for @c1;
    my $data = ($f ^ 0x5412) >> 10;
    my ($eccbits, $mask) = ($data >> 3, $data & 7);
    return (undef, "ecc bits $eccbits != $ECCBITS{$ecc}")
        if $eccbits != $ECCBITS{$ecc};

    # unmask
    my @cond = (
        sub { ($_[0] + $_[1]) % 2 == 0 },
        sub { $_[0] % 2 == 0 },
        sub { $_[1] % 3 == 0 },
        sub { ($_[0] + $_[1]) % 3 == 0 },
        sub { (int($_[0]/2) + int($_[1]/3)) % 2 == 0 },
        sub { (($_[0]*$_[1]) % 2) + (($_[0]*$_[1]) % 3) == 0 },
        sub { ((($_[0]*$_[1]) % 2) + (($_[0]*$_[1]) % 3)) % 2 == 0 },
        sub { ((($_[0]+$_[1]) % 2) + (($_[0]*$_[1]) % 3)) % 2 == 0 },
    );
    my @u = map { [ @$_ ] } @$m;
    for my $r (0..$size-1) { for my $c (0..$size-1) {
        $u[$r][$c] ^= 1 if !$fx[$r][$c] && $cond[$mask]->($r, $c);
    } }

    # zigzag
    my @bits;
    my $up = 1;
    for (my $col = $size - 1; $col > 0; $col -= 2) {
        $col = 5 if $col == 6;
        for my $i (0 .. $size - 1) {
            my $r = $up ? $size - 1 - $i : $i;
            for my $d (0, 1) {
                push @bits, $u[$r][$col - $d] unless $fx[$r][$col - $d];
            }
        }
        $up = !$up;
    }
    my @cw;
    while (@bits >= 8) {
        my $b = 0;
        $b = ($b << 1) | shift @bits for 1 .. 8;
        push @cw, $b;
    }

    # de-interleave and check syndromes
    my ($ec, $g1, $d1, $g2, $d2) = @{ $RS{"$v,$ecc"} };
    my $blocks = $g1 + $g2;
    my @dlen = ((($d1) x $g1), (($d2) x $g2));
    my $maxd = $d2 > $d1 ? $d2 : $d1;
    my (@blk, @ecb);
    my $n = 0;
    for my $j (0 .. $maxd - 1) { for my $i (0 .. $blocks - 1) {
        next if $j >= $dlen[$i];
        push @{ $blk[$i] }, $cw[$n++];
    } }
    for my $j (0 .. $ec - 1) { for my $i (0 .. $blocks - 1) {
        push @{ $ecb[$i] }, $cw[$n++];
    } }
    for my $i (0 .. $blocks - 1) {
        my @full = (@{ $blk[$i] }, @{ $ecb[$i] });
        for my $s (0 .. $ec - 1) {
            my $acc = 0;
            $acc = gmul($acc, $E[$s]) ^ $_ for @full;
            return (undef, "block $i syndrome $s nonzero") if $acc;
        }
    }

    # payload
    my $bitstr = join '', map { sprintf '%08b', $_ } map { @$_ } @blk;
    my $mode = oct '0b' . substr($bitstr, 0, 4);
    return (undef, "mode $mode not byte mode") if $mode != 4;
    my $cl  = $v < 10 ? 8 : 16;
    my $len = oct '0b' . substr($bitstr, 4, $cl);
    my $txt = '';
    $txt .= chr oct '0b' . substr($bitstr, 4 + $cl + $_ * 8, 8)
        for 0 .. $len - 1;
    return ($txt, undef);
}

for my $v (sort { $a <=> $b } map { (split /,/)[0] } grep { /,L$/ } keys %RS) {
    for my $ecc (qw(L M Q H)) {
        my $cap = QR::Code::_capacity($ECCNUM{$ecc}, $v);
        # exact capacity, and a short payload that exercises padding
        for my $len ($cap, 3) {
            my $payload = join '',
                map { chr(0x20 + ($_ * 7 + $len) % 95) } 0 .. $len - 1;
            my $m = QR::Code->matrix($payload, ecc => $ecc, version => $v);
            my ($got, $why) = decode($m, $v, $ecc);
            is $got, $payload,
                "v$v/$ecc round-trips $len bytes" . ($why ? " ($why)" : '');
        }
    }
}

done_testing;
