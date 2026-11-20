package Protocol::IR::Proto::Dish;
use strict;
use warnings;

our $VERSION = '1.5';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    return Protocol::IR::Code->new(
        protocol   => 'Dish_Network',
        bits       => 16,
        address    => 0,
        subaddress => -1,
        command    => $val & 0xffff,
        data       => $val & 0xffff,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    my $cmd = $args{command} // $args{function} // $args{device} // 0;
    $cmd = hex($cmd) if $cmd =~ /^0x/i;
    $cmd &= 0xffff;
    return Protocol::IR::Code->new(
        protocol   => 'Dish_Network',
        bits       => 16,
        address    => 0,
        subaddress => -1,
        command    => $cmd,
        data       => $cmd,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs >= 17;
    my ($hdr_mark, $hdr_space) = @{$pairs->[0]};
    return undef unless $hdr_mark >= 300 && $hdr_mark <= 500 && $hdr_space >= 5500 && $hdr_space <= 6700;
    my $data = 0;
    for my $i (0 .. 15) {
        my ($mark, $space) = @{$pairs->[$i + 1]};
        return undef unless $mark >= 300 && $mark <= 500;
        my $bit;
        my $mid = (1700 + 2800) / 2;
        if ($space > $mid) { $bit = 0; }
        elsif ($space < $mid && $space >= 850) { $bit = 1; }
        else { return undef; }
        $data = ($data << 1) | $bit;
    }
    return Protocol::IR::Code->new(
        protocol   => 'Dish_Network',
        bits       => 16,
        address    => 0,
        subaddress => -1,
        command    => $data,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $data = $code->{data} & 0xffff;
    my $carrier_hz = 57600;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @bits;
    for my $i (reverse 0 .. 15) { push @bits, ($data >> $i) & 1; }

    my @pairs = ( [ $us_to_pulses->(400), $us_to_pulses->(6100) ] );
    for my $bit (@bits) {
        push @pairs, [ $us_to_pulses->(400), $us_to_pulses->($bit ? 1700 : 2800) ];
    }

    my $seq1 = scalar(@pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pairs);
    return "$header $payload";
}

1;

=head1 NAME

Protocol::IR::Proto::Dish - IR protocol handler

=head1 VERSION

version 1.5

=cut
