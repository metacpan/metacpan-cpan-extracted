package REFECO::Blockchain::Contract::Solidity::ABI::Type::Tuple;

use strict;
use warnings;
no indirect;

use Carp;
use parent qw(REFECO::Blockchain::Contract::Solidity::ABI::Type);

sub configure {
    my $self = shift;
    return unless $self->data;

    my @splited_signatures = $self->split_tuple_signature->@*;

    for (my $sig_index = 0; $sig_index < @splited_signatures; $sig_index++) {
        push $self->instances->@*,
            REFECO::Blockchain::Contract::Solidity::ABI::Type::new_type(
            signature => $splited_signatures[$sig_index],
            data      => $self->data->[$sig_index]);
    }

}

sub split_tuple_signature {
    my $self             = shift;
    my $tuple_signatures = substr($self->signature, 1, length($self->signature) - 2);
    $tuple_signatures =~ s/((\((?>[^)(]*(?2)?)*\))|[^,()]*)(*SKIP),/$1\n/g;
    my @types = split('\n', $tuple_signatures);
    return \@types;
}

sub encode {
    my $self = shift;
    return $self->encoded if $self->encoded;

    my $offset = $self->get_initial_offset;

    for my $instance ($self->instances->@*) {
        $instance->encode;
        if ($instance->is_dynamic) {
            $self->push_static($self->encode_offset($offset));
            $self->push_dynamic($instance->encoded);
            $offset += scalar $instance->encoded->@*;
            next;
        }

        $self->push_static($instance->encoded);
    }

    return $self->encoded;
}

sub decode {
    my $self = shift;

    unless (scalar $self->instances->@* > 0) {
        push $self->instances->@*, REFECO::Blockchain::Contract::Solidity::ABI::Type::new_type(signature => $_)
            for $self->split_tuple_signature->@*;
    }

    return $self->read_stack_set_data;
}

sub static_size {
    my $self = shift;
    return 1 if $self->is_dynamic;
    my $size          = 1;
    my $instance_size = 0;
    for my $signature ($self->split_tuple_signature->@*) {
        my $instance = REFECO::Blockchain::Contract::Solidity::ABI::Type::new_type(signature => $signature);
        $instance_size += $instance->static_size // 0;
    }

    return $size * $instance_size;
}

1;

