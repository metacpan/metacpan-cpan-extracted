package Protocol::IR::Proto::Mitsubishi;
use strict;
use warnings;

our $VERSION = '1.3';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    return Protocol::IR::Code->new(
        protocol   => 'Mitsubishi',
        bits       => 16,
        address    => ($val >> 8) & 0xff,
        subaddress => -1,
        command    => $val & 0xff,
        data       => $val & 0xffff,
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
        protocol   => 'Mitsubishi',
        bits       => 16,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => $data,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs >= 16;
    my $data = 0;
    for my $i (0 .. 15) {
        my ($mark, $space) = @{$pairs->[$i]};
        return undef unless $mark >= 250 && $mark <= 350;
        my $bit;
        if (abs($space - 2100) < 200) { $bit = 1; }
        elsif (abs($space - 900) < 200) { $bit = 0; }
        else { return undef; }
        $data = ($data << 1) | $bit;
    }
    return Protocol::IR::Code->new(
        protocol   => 'Mitsubishi',
        bits       => 16,
        address    => ($data >> 8) & 0xff,
        subaddress => -1,
        command    => $data & 0xff,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $data = $code->{data} & 0xffff;
    my $carrier_hz = 33000;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @bits;
    for my $i (reverse 0 .. 15) { push @bits, ($data >> $i) & 1; }

    my @pairs;
    for my $bit (@bits) {
        push @pairs, [ $us_to_pulses->(300), $us_to_pulses->($bit ? 2100 : 900) ];
    }

    my $seq1 = scalar(@pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pairs);
    return "$header $payload";
}

1;

=head1 NAME

Protocol::IR::Proto::Mitsubishi - IR protocol handler

=head1 VERSION

version 1.3

=cut
