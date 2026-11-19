package Protocol::IR::Proto::GICable;
use strict;
use warnings;

our $VERSION = '1.3';

use Protocol::IR::Code;

sub new { bless {}, shift }

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    return Protocol::IR::Code->new(
        protocol   => 'G.I.Cable',
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
        protocol   => 'G.I.Cable',
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
    my ($hm, $hs) = @{$pairs->[0]};
    return undef unless $hm >= 8000 && $hm <= 10000 && $hs >= 3800 && $hs <= 5000;
    my $data = 0;
    for my $i (0 .. 15) {
        my ($mark, $space) = @{$pairs->[$i + 1]};
        return undef unless $mark >= 400 && $mark <= 700;
        my $bit;
        my $mid = (4400 + 2200) / 2;
        if ($space > $mid) { $bit = 1; }
        elsif ($space < $mid && $space >= 1100) { $bit = 0; }
        else { return undef; }
        $data = ($data << 1) | $bit;
    }
    return Protocol::IR::Code->new(
        protocol   => 'G.I.Cable',
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
    my $carrier_hz = 38000;
    my $freq_word = int(1000000.0 / ($carrier_hz * 0.241246) + 0.5);
    my $period_us = $freq_word * 0.241246;
    my $us_to_pulses = sub { int($_[0] / $period_us + 0.5) };

    my @bits;
    for my $i (reverse 0 .. 15) { push @bits, ($data >> $i) & 1; }

    my @pairs = ( [ $us_to_pulses->(9000), $us_to_pulses->(4400) ] );
    for my $bit (@bits) {
        push @pairs, [ $us_to_pulses->(550), $us_to_pulses->($bit ? 4400 : 2200) ];
    }

    my $seq1 = scalar(@pairs);
    my $header = sprintf('0000 %04X %04X 0000', $freq_word, $seq1);
    my $payload = join(' ', map { sprintf('%04X %04X', $_->[0], $_->[1]) } @pairs);
    return "$header $payload";
}

1;

=head1 NAME

Protocol::IR::Proto::GICable - IR protocol handler

=head1 VERSION

version 1.3

=cut
