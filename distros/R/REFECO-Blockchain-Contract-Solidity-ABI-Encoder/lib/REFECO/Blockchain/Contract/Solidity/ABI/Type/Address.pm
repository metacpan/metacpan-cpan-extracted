package REFECO::Blockchain::Contract::Solidity::ABI::Type::Address;

use strict;
use warnings;
no indirect;

use Carp;
use parent qw(REFECO::Blockchain::Contract::Solidity::ABI::Type);

sub encode {
    my $self = shift;
    return $self->encoded if $self->encoded;
    $self->push_static($self->pad_left(substr($self->data, 2)));

    return $self->encoded;
}

sub decode {
    my $self = shift;
    return '0x' . substr $self->data->[0], -40;
}

1;

