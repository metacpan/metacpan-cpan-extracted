package Protocol::IR::Proto::RC5;
use strict;
use warnings;

our $VERSION = '1.3';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub _half { 889 }

sub _manchester_bits {
    my ($class, $toggle, $address, $command) = @_;
    my $start2 = ($command & 0x40) ? 0 : 1;
    my $cmd6 = $command & 0x3f;
    my @bits = (1, $start2, $toggle & 1);
    for my $i (reverse 0 .. 4) { push @bits, ($address >> $i) & 1; }
    for my $i (reverse 0 .. 5) { push @bits, ($cmd6 >> $i) & 1; }
    return @bits;
}

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    my $toggle = ($val >> 11) & 1;
    my $address = ($val >> 6) & 0x1f;
    my $command = $val & 0x3f;
    return Protocol::IR::Code->new(
        protocol   => 'RC5',
        bits       => 12,
        address    => $address,
        subaddress => -1,
        command    => $command,
        data       => $val,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr = $args{address} // $args{device} // 0;
    $addr = hex($addr) if $addr =~ /^0x/i;
    my $cmd = $args{command} // $args{function} // 0;
    $cmd = hex($cmd) if $cmd =~ /^0x/i;
    $addr &= 0x1f;
    $cmd &= 0x7f;
    my $toggle = 0;
    my $data = ($toggle << 11) | ($addr << 6) | ($cmd & 0x3f);
    return Protocol::IR::Code->new(
        protocol   => 'RC5',
        bits       => 12,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => $data,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs;

    # Convert pairs to signed halves.
    my @signed;
    for my $p (@$pairs) {
        my ($m, $s) = @$p;
        if ($m > 0) { push @signed, $m; }
        if ($s > 0) { push @signed, -$s; }
    }
    # Expand merged magnitudes into 889 units.
    my @expanded;
    for my $t (@signed) {
        my $n = int((abs($t) + 444) / 889);
        my $sign = $t >= 0 ? 1 : -1;
        for (1 .. $n) { push @expanded, $sign * 889; }
    }
    # strip leading/trailing spaces
    while (@expanded && $expanded[0] < 0) { shift @expanded; }
    while (@expanded && $expanded[-1] < 0) { pop @expanded; }
    return undef unless @expanded;
    return undef unless $expanded[0] > 0;

    my @bits = (1);
    my $i = 1;
    while ($i + 1 < @expanded) {
        my ($a, $b) = @expanded[$i, $i + 1];
        if ($a < 0 && $b > 0) { push @bits, 1; }
        elsif ($a > 0 && $b < 0) { push @bits, 0; }
        else { return undef; }
        $i += 2;
    }
    if ($i < @expanded) {
        if ($expanded[$i] > 0) { push @bits, 0; }
        else { return undef; }
    }
    return undef unless @bits == 14;

    my $s2 = $bits[1];
    my $toggle = $bits[2];
    my $address = 0;
    for my $k (0 .. 4) { $address = ($address << 1) | $bits[3 + $k]; }
    my $command = 0;
    for my $k (0 .. 5) { $command = ($command << 1) | $bits[8 + $k]; }
    if ($s2 == 0) { $command |= 0x40; }
    my $data = ($toggle << 11) | ($address << 6) | ($command & 0x3f);
    return Protocol::IR::Code->new(
        protocol   => 'RC5',
        bits       => 12,
        address    => $address,
        subaddress => -1,
        command    => $command,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $toggle = ($code->{data} >> 11) & 1;
    my $address = $code->{address} & 0x1f;
    my $command = $code->{command} & 0x7f;
    my @bits = $class->_manchester_bits($toggle, $address, $command);

    my $carrier_hz = 36000;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @pronto_pairs;
    for my $bit (@bits) {
        if ($bit == 0) {
            push @pronto_pairs, [ $us_to_pulses->(889), $us_to_pulses->(889) ];
        } else {
            push @pronto_pairs, [ 0, $us_to_pulses->(889) ];
            push @pronto_pairs, [ $us_to_pulses->(889), 0 ];
        }
    }
    my $seq1 = scalar(@pronto_pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pronto_pairs);
    return "$header $payload";
}

1;

=head1 NAME

Protocol::IR::Proto::RC5 - IR protocol handler

=head1 VERSION

version 1.3

=cut
