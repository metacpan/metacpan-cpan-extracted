package REFECO::Blockchain::Contract::Solidity::ABI::Type::String;

use v5.26;
use strict;
use warnings;
no indirect;

use parent qw(REFECO::Blockchain::Contract::Solidity::ABI::Type);

sub encode {
    my $self = shift;
    return $self->encoded if $self->encoded;

    my $hex = unpack("H*", $self->data);

    # for dynamic length basic types the length must be included
    $self->push_dynamic($self->encode_length(length(pack("H*", $hex))));
    $self->push_dynamic($self->pad_right($hex));

    return $self->encoded;
}

sub decode {
    my $self = shift;
    my @data = $self->data->@*;

    my $size          = hex shift @data;
    my $string_data   = join('', @data);
    my $packed_string = pack("H*", $string_data);
    return substr($packed_string, 0, $size);
}

1;

