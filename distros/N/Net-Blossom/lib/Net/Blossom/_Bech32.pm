package Net::Blossom::_Bech32;

use strictures 2;

my $CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
my %VALUE = map { substr($CHARSET, $_, 1) => $_ } 0 .. length($CHARSET) - 1;
my @GENERATOR = (0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3);

sub decode {
    my ($value, $checksum) = @_;
    my ($hrp, $data) = _parts($value);
    return unless defined $hrp;

    my @values = (_hrp_expand($hrp), map { $VALUE{$_} } split //, $data);
    return unless _polymod(\@values) == $checksum;

    my @payload = map { $VALUE{$_} } split //, substr($data, 0, -6);
    return ($hrp, \@payload);
}

sub convert_5_to_8 {
    my ($values) = @_;
    my ($accumulator, $bits) = (0, 0);
    my $bytes = '';

    for my $value (@$values) {
        return unless defined $value && $value >= 0 && $value < 32;
        $accumulator = (($accumulator << 5) | $value) & 0xfff;
        $bits += 5;

        while ($bits >= 8) {
            $bits -= 8;
            $bytes .= chr(($accumulator >> $bits) & 0xff);
        }
    }

    return if $bits >= 5;
    return if $bits && (($accumulator << (8 - $bits)) & 0xff);
    return $bytes;
}

sub _parts {
    my ($value) = @_;
    return unless defined $value && !ref($value) && length $value;
    return if $value =~ /[^\x21-\x7e]/;
    return if lc($value) ne $value && uc($value) ne $value;

    my $normalized = lc $value;
    my $separator = rindex($normalized, '1');
    return if $separator < 1;

    my $data = substr($normalized, $separator + 1);
    return if length($data) < 6;
    return unless $data =~ /\A[$CHARSET]+\z/;

    return (substr($normalized, 0, $separator), $data);
}

sub _hrp_expand {
    my ($hrp) = @_;
    my @chars = split //, $hrp;
    return ((map { ord($_) >> 5 } @chars), 0, (map { ord($_) & 31 } @chars));
}

sub _polymod {
    my ($values) = @_;
    my $checksum = 1;

    for my $value (@$values) {
        my $top = $checksum >> 25;
        $checksum = (($checksum & 0x1ffffff) << 5) ^ $value;
        for my $i (0 .. 4) {
            $checksum ^= $GENERATOR[$i] if (($top >> $i) & 1);
        }
    }

    return $checksum;
}

1;
