package Protocol::IR::Proto::Aiwa;
use strict;
use warnings;

our $VERSION = '1.5';

use Protocol::IR::Code;
use Math::BigInt;

my $PRE_DATA = 0x1D8113F;
my $PRE_BITS = 26;
my $DATA_BITS = 15;
my $POST_BITS = 1;
my $TOTAL_BITS = $PRE_BITS + $DATA_BITS + $POST_BITS;

sub new { bless {}, shift }

sub _reverse_bits {
    my ($v, $bits) = @_;
    my $out = 0;
    for my $i (0 .. $bits - 1) { $out |= (($v >> $i) & 1) << ($bits - 1 - $i); }
    return $out;
}

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? Math::BigInt->from_hex($raw) : Math::BigInt->new($raw);
    return Protocol::IR::Code->new(
        protocol   => 'Aiwa',
        bits       => $DATA_BITS,
        address    => ($val >> 8) & 0x7f,
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
    $addr &= 0x7f;
    $cmd &= 0xff;
    my $data = (Math::BigInt->new($addr) << 8) | Math::BigInt->new($cmd);
    return Protocol::IR::Code->new(
        protocol   => 'Aiwa',
        bits       => $DATA_BITS,
        address    => $addr,
        subaddress => -1,
        command    => $cmd,
        data       => $data,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs >= $TOTAL_BITS + 1;
    my ($hdr_mark, $hdr_space) = @{$pairs->[0]};
    return undef unless $hdr_mark >= 7500 && $hdr_mark <= 10500 && $hdr_space >= 3500 && $hdr_space <= 5500;

    my $data = Math::BigInt->bzero();
    for my $i (0 .. $TOTAL_BITS - 1) {
        my $space = $pairs->[$i + 1][1];
        my $bit = $space > 1100 ? 1 : 0;
        $data = ($data << 1) | $bit;
    }
    my $prefix = ($data >> ($DATA_BITS + $POST_BITS)) & ((1 << $PRE_BITS) - 1);
    my $postfix = $data & 1;
    return undef unless $prefix == $PRE_DATA && $postfix == 1;
    my $var = ($data >> $POST_BITS) & Math::BigInt->new((1 << $DATA_BITS) - 1);
    return Protocol::IR::Code->new(
        protocol   => 'Aiwa',
        bits       => $DATA_BITS,
        address    => ($var >> 8) & 0x7f,
        subaddress => -1,
        command    => $var & 0xff,
        data       => $var,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $var = $code->{data} & Math::BigInt->new('0x7fff');
    my $full = (Math::BigInt->new($PRE_DATA) << ($DATA_BITS + $POST_BITS)) | ($var << $POST_BITS) | 1;
    my $carrier_hz = 38000;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @bits;
    for my $i (reverse 0 .. $TOTAL_BITS - 1) { push @bits, ($full >> $i) & 1; }

    my @pairs = ( [ $us_to_pulses->(9024), $us_to_pulses->(4512) ] );
    for my $bit (@bits) {
        push @pairs, [ $us_to_pulses->(562.5), $us_to_pulses->($bit ? 1687.5 : 562.5) ];
    }
    push @pairs, [ $us_to_pulses->(564), $us_to_pulses->(43992) ];

    my $seq1 = scalar(@pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pairs);
    return "$header $payload";
}

1;

=head1 NAME

Protocol::IR::Proto::Aiwa - IR protocol handler

=head1 VERSION

version 1.5

=cut
