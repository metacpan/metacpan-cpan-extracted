package Protocol::IR::Proto::Denon;
use strict;
use warnings;

our $VERSION = '1.3';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub _pack {
    my ($class, $addr, $cmd) = @_;
    return (($addr & 0x1f) << 10) | (($cmd & 0xff) << 2);
}

sub _protocol_name { 'DENON' }

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 15,
        address    => ($val >> 10) & 0x1f,
        subaddress => -1,
        command    => ($val >> 2) & 0xff,
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
    $cmd &= 0xff;
    my $data = $class->_pack($addr, $cmd);
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 15,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => $data,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs >= 15;
    my $data = 0;
    for my $i (0 .. 14) {
        my ($mark, $space) = @{$pairs->[$i]};
        return undef unless $mark >= 130 && $mark <= 390;
        my $bit;
        my $mid = (1820 + 780) / 2;
        if ($space > $mid) { $bit = 1; }
        elsif ($space < $mid && $space > 390) { $bit = 0; }
        else { return undef; }
        $data = ($data << 1) | $bit;
    }
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => 15,
        address    => ($data >> 10) & 0x1f,
        subaddress => -1,
        command    => ($data >> 2) & 0xff,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $data = $code->{data};
    my $carrier_hz = 38000;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @bits;
    for my $i (reverse 0 .. 14) { push @bits, ($data >> $i) & 1; }

    my @pairs;
    for my $bit (@bits) {
        push @pairs, [ $us_to_pulses->(260), $us_to_pulses->($bit ? 1820 : 780) ];
    }
    # inverted frame
    my $addr = ($data >> 10) & 0x1f;
    my $rest = $data & 0x3ff;
    my $inverted = ($addr << 10) | (~$rest & 0x3ff);
    my @invbits;
    for my $i (reverse 0 .. 14) { push @invbits, ($inverted >> $i) & 1; }
    for my $bit (@invbits) {
        push @pairs, [ $us_to_pulses->(260), $us_to_pulses->($bit ? 1820 : 780) ];
    }

    my $seq1 = scalar(@pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pairs);
    return "$header $payload";
}

1;

package Protocol::IR::Proto::DenonK;
use base 'Protocol::IR::Proto::Denon';
sub _protocol_name { 'DENON-K' }

package Protocol::IR::Proto::Denon1;
use base 'Protocol::IR::Proto::Denon';
sub _protocol_name { 'DENON{1}' }

1;

=head1 NAME

Protocol::IR::Proto::Denon - IR protocol handler

=head1 VERSION

version 1.3

=cut
