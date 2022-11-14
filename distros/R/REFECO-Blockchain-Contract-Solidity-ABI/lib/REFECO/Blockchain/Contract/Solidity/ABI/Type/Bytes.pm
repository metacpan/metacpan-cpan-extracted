package REFECO::Blockchain::Contract::Solidity::ABI::Type::Bytes;

use v5.26;
use strict;
use warnings;
no indirect;

use Carp;
use parent qw(REFECO::Blockchain::Contract::Solidity::ABI::Type);

sub encode {
    my $self = shift;
    return $self->encoded if $self->encoded;
    # remove 0x and validates the hexadecimal value
    croak 'Invalid hexadecimal value ' . $self->data // 'undef'
        unless $self->data =~ /^(?:0x|0X)?([a-fA-F0-9]+)$/;
    my $hex = $1;

    my $data_length = length(pack("H*", $hex));
    unless ($self->fixed_length) {
        # for dynamic length basic types the length must be included
        $self->push_dynamic($self->encode_length($data_length));
        $self->push_dynamic($self->pad_right($hex));
    } else {
        croak "Invalid data length, signature: @{[$self->fixed_length]}, data length: $data_length"
            if $self->fixed_length && $data_length != $self->fixed_length;
        $self->push_static($self->pad_right($hex));
    }

    return $self->encoded;
}

sub decode {
    my $self = shift;
    my @data = $self->data->@*;

    my $hex_data;
    my $size = $self->fixed_length;
    unless ($self->fixed_length) {
        $size = hex shift @data;

        $hex_data = join('', @data);
    } else {
        $hex_data = $data[0];
    }

    my $bytes = substr(pack("H*", $hex_data), 0, $size);
    return sprintf "0x%s", unpack("H*", $bytes);
}

1;

