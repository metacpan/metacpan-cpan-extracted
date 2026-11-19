package Protocol::IR::Proto::Pioneer;
use strict;
use warnings;

our $VERSION = '1.3';

use Protocol::IR::Code;
use Protocol::IR::Proto::NEC;

sub new { bless {}, shift }

sub _nec_encode {
    my ($addr, $cmd) = @_;
    # NEC address byte, subaddress default ~addr, command, ~command
    my $sub = (~$addr) & 0xff;
    return (($addr & 0xff) << 24) | ($sub << 16) | (($cmd & 0xff) << 8) | ((~$cmd) & 0xff);
}

sub decode_raw {
    my ($class, $raw) = @_;
    my $val = $raw =~ /^0x/i ? hex($raw) : $raw + 0;
    # val is 64-bit bundle
    my $first = ($val >> 32) & 0xffffffff;
    my $second = $val & 0xffffffff;
    my $address = ($first >> 8) & 0xff;
    my $command = ($second >> 8) & 0xff;
    return Protocol::IR::Code->new(
        protocol   => 'Pioneer',
        bits       => 64,
        address    => $address,
        subaddress => -1,
        command    => $command,
        data       => $val,
    );
}

sub decode_params {
    my ($class, %args) = @_;
    my $address = $args{address} // $args{device} // 0;
    $address = hex($address) if $address =~ /^0x/i;
    my $command = $args{command} // $args{function} // 0;
    $command = hex($command) if $command =~ /^0x/i;
    $address &= 0xff;
    $command &= 0xff;
    my $first = _nec_encode(0, $address);
    my $second = _nec_encode(0, $command);
    my $data = ($first << 32) | $second;
    return Protocol::IR::Code->new(
        protocol   => 'Pioneer',
        bits       => 64,
        address    => $address,
        subaddress => -1,
        command    => $command,
        data       => $data,
    );
}

sub decode_timing {
    my ($class, $pairs) = @_;
    return undef unless ref $pairs eq 'ARRAY' && @$pairs >= 68;
    my $first = Protocol::IR::Proto::NEC->decode_timing([ @{$pairs}[0 .. 33] ]);
    return undef unless defined $first;
    my $second = Protocol::IR::Proto::NEC->decode_timing([ @{$pairs}[34 .. 67] ]);
    return undef unless defined $second;
    my $address = ($first->{data} >> 8) & 0xff;
    my $command = ($second->{data} >> 8) & 0xff;
    my $data = ($first->{data} << 32) | $second->{data};
    return Protocol::IR::Code->new(
        protocol   => 'Pioneer',
        bits       => 64,
        address    => $address,
        subaddress => -1,
        command    => $command,
        data       => $data,
    );
}

sub to_pronto {
    my ($class, $code) = @_;
    my $data = $code->{data};
    my $first = ($data >> 32) & 0xffffffff;
    my $second = $data & 0xffffffff;
    my $first_code = Protocol::IR::Proto::NEC->decode_raw($first);
    my $second_code = Protocol::IR::Proto::NEC->decode_raw($second);
    my $p1 = Protocol::IR::Proto::NEC->to_pronto($first_code);
    my $p2 = Protocol::IR::Proto::NEC->to_pronto($second_code);

    my @t1 = split(/\s+/, $p1);
    my @t2 = split(/\s+/, $p2);
    my $freq_word = $t1[1];
    my $pairs1 = hex($t1[2]);
    my $pairs2 = hex($t2[2]);
    my $total = $pairs1 + $pairs2;
    my $header = sprintf('0000 %s %04X 0000', $freq_word, $total);
    my $payload1 = join(' ', @t1[4 .. $#t1]);
    my $payload2 = join(' ', @t2[4 .. $#t2]);
    return "$header $payload1 $payload2";
}

1;

=head1 NAME

Protocol::IR::Proto::Pioneer - IR protocol handler

=head1 VERSION

version 1.3

=cut
