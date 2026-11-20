package Protocol::IR::Proto::Sony;
our $VERSION = '1.5';

package Protocol::IR::Proto::Sony12;
use strict;
use warnings;

our $VERSION = '1.5';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub bits { 12 }
sub address_bits { 5 }
sub extended_bits { 0 }

sub _reverse_bits {
    my ($value, $bits) = @_;
    my $out = 0;
    for my $i (0 .. $bits - 1) {
        $out |= (($value >> $i) & 1) << ($bits - 1 - $i);
    }
    return $out;
}

sub _logical_value {
    my ($class, $addr, $ext, $cmd) = @_;
    my $v = $addr & ((1 << $class->address_bits) - 1);
    if ($class->extended_bits) {
        $v |= ($ext & ((1 << $class->extended_bits) - 1)) << $class->address_bits;
    }
    $v = ($v << 7) | ($cmd & 0x7f);
    return $v;
}

sub decode_raw {
    my ($class, $raw) = @_;
    my $transmitted = $raw + 0;
    $transmitted = hex($transmitted) if $transmitted =~ /^0x/i;
    my $logical = _reverse_bits($transmitted, $class->bits);
    my $cmd = $logical & 0x7f;
    my $addr = ($logical >> 7) & ((1 << $class->address_bits) - 1);
    my $ext = 0;
    if ($class->extended_bits) {
        $ext = ($logical >> (7 + $class->address_bits)) & ((1 << $class->extended_bits) - 1);
    }
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => $class->bits,
        address    => $addr,
        subaddress => $class->extended_bits ? $ext : -1,
        command    => $cmd,
        data       => $logical,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    my $addr = $args{address} // $args{device} // 0;
    $addr = hex($addr) if $addr =~ /^0x/i;
    my $ext = $args{subaddress} // $args{subdevice} // 0;
    $ext = hex($ext) if $ext =~ /^0x/i;
    my $cmd = $args{command} // $args{function} // 0;
    $cmd = hex($cmd) if $cmd =~ /^0x/i;

    my $logical = $class->_logical_value($addr, $ext, $cmd);
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => $class->bits,
        address    => $addr,
        subaddress => $class->extended_bits ? $ext : -1,
        command    => $cmd,
        data       => $logical,
    );
}

sub _protocol_name { 'SONY12' }

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs >= $class->bits + 1;
    # Reject frames that carry more bits than this variant (e.g. a 15-bit
    # frame must not be accepted by the 12-bit decoder).
    if (@$pairs > $class->bits + 1) {
        return undef unless ($pairs->[$class->bits + 1][0] // 0) == 0;
    }

    my ($hdr_mark, $hdr_space) = @{$pairs->[0]};
    return undef unless $hdr_mark >= 2000 && $hdr_mark <= 2800 && $hdr_space >= 400 && $hdr_space <= 800;

    my $data = 0;
    for my $k (0 .. $class->bits - 1) {
        my $mark = $pairs->[$k + 1][0];
        my $bit;
        if ($mark >= 1000 && $mark <= 1400) { $bit = 1; }
        elsif ($mark >= 400 && $mark <= 800) { $bit = 0; }
        else { return undef; }
        $data = ($data << 1) | $bit;
    }

    my $logical = _reverse_bits($data, $class->bits);
    my $cmd = $logical & 0x7f;
    my $addr = ($logical >> 7) & ((1 << $class->address_bits) - 1);
    my $ext = 0;
    if ($class->extended_bits) {
        $ext = ($logical >> (7 + $class->address_bits)) & ((1 << $class->extended_bits) - 1);
    }
    return Protocol::IR::Code->new(
        protocol   => $class->_protocol_name,
        bits       => $class->bits,
        address    => $addr,
        subaddress => $class->extended_bits ? $ext : -1,
        command    => $cmd,
        data       => $logical,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $carrier_hz = 40000;
    # freq word
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my $addr = $code->{address} & ((1 << $class->address_bits) - 1);
    my $ext = $class->extended_bits ? ($code->{subaddress} & ((1 << $class->extended_bits) - 1)) : 0;
    my $cmd = $code->{command} & 0x7f;
    my $logical = $class->_logical_value($addr, $ext, $cmd);
    my $transmitted = _reverse_bits($logical, $class->bits);

    my @bits;
    for my $i (reverse 0 .. $class->bits - 1) {
        push @bits, ($transmitted >> $i) & 1;
    }

    my @pairs;
    push @pairs, [ $us_to_pulses->(2400), $us_to_pulses->(600) ];
    for my $bit (@bits) {
        push @pairs, [ $us_to_pulses->($bit ? 1200 : 600), $us_to_pulses->(600) ];
    }

    my $seq1 = scalar(@pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pairs);
    return "$header $payload";
}

# --- SONY15 ----------------------------------------------------------------
package Protocol::IR::Proto::Sony15;
use base 'Protocol::IR::Proto::Sony12';
sub bits { 15 }
sub address_bits { 8 }
sub _protocol_name { 'SONY15' }

# --- SONY20 ----------------------------------------------------------------
package Protocol::IR::Proto::Sony20;
use base 'Protocol::IR::Proto::Sony12';
sub bits { 20 }
sub address_bits { 5 }
sub extended_bits { 8 }
sub _protocol_name { 'SONY20' }

1;

=head1 NAME

Protocol::IR::Proto::Sony - IR protocol handler

=head1 VERSION

version 1.5

=cut
