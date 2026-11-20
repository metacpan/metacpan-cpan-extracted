package Protocol::IR::Proto::RC6;
use strict;
use warnings;

our $VERSION = '1.5';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    return Protocol::IR::Code->new(
        protocol   => 'RC6',
        bits       => 20,
        address    => ($val >> 8) & 0xff,
        subaddress => -1,
        command    => $val & 0xff,
        data       => $val,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr = $args{address} // $args{device} // 0;
    $addr = hex($addr) if $addr =~ /^0x/i;
    my $cmd = $args{command} // $args{function} // 0;
    $cmd = hex($cmd) if $cmd =~ /^0x/i;
    $addr &= 0xff;
    $cmd &= 0xff;
    my $data = ($addr << 8) | $cmd;
    return Protocol::IR::Code->new(
        protocol   => 'RC6',
        bits       => 20,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => $data,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs;

    # Expand pairs into tick units.
    my @expanded;
    for my $p (@$pairs) {
        my ($m, $s) = @$p;
        my $mn = int(($m + 222) / 444);
        for (1 .. $mn) { push @expanded, 444; }
        my $sn = int(($s + 222) / 444);
        for (1 .. $sn) { push @expanded, -444; }
    }
    # strip trailing spaces
    while (@expanded && $expanded[-1] < 0) { pop @expanded; }

    return undef unless @expanded >= 8 + 2 + 2 * 20;
    for my $i (0 .. 5) { return undef unless $expanded[$i] > 0; }
    return undef unless $expanded[6] < 0 && $expanded[7] < 0;

    my $idx = 8;
    return undef unless $idx + 1 < @expanded && $expanded[$idx] > 0 && $expanded[$idx + 1] < 0;
    $idx += 2;

    my $data = 0;
    for my $bitIndex (0 .. 19) {
        my $w = ($bitIndex == 3) ? 2 : 1;
        return undef if $idx + 2 * $w > @expanded;
        my $levelA = $expanded[$idx] > 0 ? 1 : -1;
        for my $k (0 .. $w - 1) {
            return undef unless ($expanded[$idx + $k] > 0 ? 1 : -1) == $levelA;
        }
        $idx += $w;
        my $levelB = $expanded[$idx] > 0 ? 1 : -1;
        for my $k (0 .. $w - 1) {
            return undef unless ($expanded[$idx + $k] > 0 ? 1 : -1) == $levelB;
        }
        $idx += $w;

        if ($levelA == 1 && $levelB == -1) { $data = ($data << 1) | 1; }
        elsif ($levelA == -1 && $levelB == 1) { $data = $data << 1; }
        else { return undef; }
    }

    return Protocol::IR::Code->new(
        protocol   => 'RC6',
        bits       => 20,
        address    => ($data >> 8) & 0xff,
        subaddress => -1,
        command    => $data & 0xff,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $data = $code->{data} & 0xfffff;
    my $carrier_hz = 36000;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @pronto_pairs;
    # header
    push @pronto_pairs, [ $us_to_pulses->(6 * 444), $us_to_pulses->(2 * 444) ];
    # start bit
    push @pronto_pairs, [ $us_to_pulses->(444), $us_to_pulses->(444) ];
    for my $i (0 .. 19) {
        my $w = ($i == 3) ? 2 : 1;
        my $bit = ($data >> (19 - $i)) & 1;
        if ($bit == 1) {
            push @pronto_pairs, [ $w * $us_to_pulses->(444), $w * $us_to_pulses->(444) ];
        } else {
            push @pronto_pairs, [ 0, $w * $us_to_pulses->(444) ];
            push @pronto_pairs, [ $w * $us_to_pulses->(444), 0 ];
        }
    }

    my $seq1 = scalar(@pronto_pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pronto_pairs);
    return "$header $payload";
}

1;

=head1 NAME

Protocol::IR::Proto::RC6 - IR protocol handler

=head1 VERSION

version 1.5

=cut
