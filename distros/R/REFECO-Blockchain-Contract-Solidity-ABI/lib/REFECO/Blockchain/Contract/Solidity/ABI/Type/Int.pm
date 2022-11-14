package REFECO::Blockchain::Contract::Solidity::ABI::Type::Int;

use v5.26;
use strict;
use warnings;
no indirect;

use Carp;
use Math::BigInt;
use parent qw(REFECO::Blockchain::Contract::Solidity::ABI::Type);

use constant DEFAULT_INT_SIZE => 256;

sub encode {
    my $self = shift;
    return $self->encoded if $self->encoded;

    my $bdata = Math::BigInt->new($self->data);

    croak "Invalid numeric data @{[$self->data]}" if $bdata->is_nan;

    croak "Invalid data length, signature: @{[$self->fixed_length]}, data length: @{[$bdata->length]}"
        if $self->fixed_length && $bdata->length > $self->fixed_length;

    croak "Invalid negative numeric data @{[$self->data]}"
        if $bdata->is_neg && $self->signature =~ /^uint|bool/;

    croak "Invalid bool data it must be 1 or 0 but given @{[$self->data]}"
        if !$bdata->is_zero && !$bdata->is_one && $self->signature =~ /^bool/;

    $self->push_static($self->pad_left($bdata->to_hex));

    return $self->encoded;
}

sub decode {
    my $self = shift;
    return Math::BigInt->from_hex($self->data->[0]);
}

sub fixed_length {
    my $self = shift;
    if ($self->signature =~ /[a-z](\d+)/) {
        return $1;
    }
    return DEFAULT_INT_SIZE;
}

1;

