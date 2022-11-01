package REFECO::Blockchain::Contract::Solidity::ABI::Type;

use strict;
use warnings;
no indirect;

use Carp;
use Module::Load;
use constant NOT_IMPLEMENTED => 'Method not implemented';

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;
    $self->{signature} = $params{signature};
    $self->{data}      = $params{data};

    $self->configure();

    return $self;
}

sub configure { }

sub encode {
    croak NOT_IMPLEMENTED;
}

sub decode {
    croak NOT_IMPLEMENTED;
}

sub static {
    return shift->{static} //= [];
}

sub push_static {
    my ($self, $data) = @_;
    push($self->static->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

sub dynamic {
    return shift->{dynamic} //= [];
}

sub push_dynamic {
    my ($self, $data) = @_;
    push($self->dynamic->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

sub signature {
    return shift->{signature};
}

sub data {
    return shift->{data};
}

=head2 fixed_length

No documentation for perl function 'Get' found

=over4

=back

Return the int length or undef

=cut

sub fixed_length {
    my $self = shift;
    if ($self->signature =~ /[a-z](\d+)/) {
        return $1;
    }
    return undef;
}

=head2 pad_right

Pad data with right zeros, if the length is bigger than 32 bytes will break
the data in chunks of 32 bytes and pad the last chunk

=over4

=item * C<$data> value to be padded

=back

Array ref

=cut

sub pad_right {
    my ($self, $data) = @_;

    my @chunks;
    push(@chunks, $_ . '0' x (64 - length $_)) for unpack("(A64)*", $data);

    return \@chunks;
}

=head2 pad_right

Pad data with left zeros, if the length is bigger than 32 bytes will break
the data in chunks of 32 bytes and pad the first chunk

=over4

=item * C<$data> value to be padded

=back

Array ref

=cut

sub pad_left {
    my ($self, $data) = @_;

    my @chunks;
    push(@chunks, sprintf("%064s", $_)) for unpack("(A64)*", $data);

    return \@chunks;

}

=head2 encode_length

Encodes integer length to hex and pad it with left zeros

=over4

=item * C<$length> value to be encoded

=back

Encoded hex string

=cut

sub encode_length {
    my ($self, $length) = @_;
    return sprintf("%064s", sprintf("%x", $length));
}

=head2 encode_length

Encodes integer offset to hex and pad it with left zeros

This expects to receive the non stack offset number e.g. 1,2 instead of 32,64
the value will be multiplied by 32, if you need the same without the multiplication
use encode_length instead

=over4

=item * C<$offset> value to be encoded

=back

Encoded hex string

=cut

sub encode_offset {
    my ($self, $offset) = @_;
    return sprintf("%064s", sprintf("%x", $offset * 32));
}

=head2 encoded

Join the static and dynamic values

=over 4

=back

Array ref or undef

=cut

sub encoded {
    my $self = shift;
    my @data = ($self->static->@*, $self->dynamic->@*);
    return scalar @data ? \@data : undef;
}

=head2 encoded

Check if the current type and his instances are dynamic or static

=over 4

=back

1 or 0

=cut

sub is_dynamic {
    return shift->signature =~ /(bytes|string)(?!\d+)|(\[\])/ ? 1 : 0;
}

=head2 new_type

Check if the current type and his instances are dynamic or static

=over 4

=item * C<%params> type signature as key and data as value

=back

1 or 0

=cut

sub new_type {
    my (%params) = @_;

    my $signature = $params{signature};

    my $module;
    if ($signature =~ /\[(\d+)?\]$/gm) {
        $module = "Array";
    } elsif ($signature =~ /^\(.*\)/) {
        $module = "Tuple";
    } elsif ($signature =~ /^address$/) {
        $module = "Address";
    } elsif ($signature =~ /^(u)?(int|bool)(\d+)?$/) {
        $module = "Int";
    } elsif ($signature =~ /^(?:bytes)(\d+)?$/) {
        $module = "Bytes";
    } elsif ($signature =~ /^string$/) {
        $module = "String";
    } else {
        croak "Module not found for the given parameter signature $signature";
    }

    # this is just to avoid `use module` for every new type included
    my $_package = __PACKAGE__;
    my $package  = sprintf("%s::%s", $_package, $module);
    load $package;
    return $package->new(
        signature => $signature,
        data      => $params{data});
}

sub instances {
    return shift->{instances} //= [];
}

=head2 get_initial_offset

Based in the static items and the offsets in the header gets the first position
in the stack for the dynamic values

=over 4

=back

Integer offset

=cut

sub get_initial_offset {
    my $self   = shift;
    my $offset = 0;
    for my $param ($self->instances->@*) {
        my $encoded = $param->encode;
        if ($param->is_dynamic) {
            $offset += 1;
        } else {
            $offset += scalar $param->encoded->@*;
        }
    }

    return $offset;
}

sub static_size {
    return 1;
}

=head2 read_stack_set_data

Based in the given signatures and data separate the string data into chunks
of instances and decode them

=over 4

=back

Array ref containing the decoded data values

=cut

sub read_stack_set_data {
    my $self = shift;

    my @data = $self->data->@*;
    my @offsets;
    my $current_offset = 0;

    # Since at this point we don't information about the chunks of data it is_dynamic
    # needed to get all the offsets in the static header, so the dynamic values can
    # be retrieved based in between the current and the next offsets
    for my $instance ($self->instances->@*) {
        if ($instance->is_dynamic) {
            push @offsets, hex($data[$current_offset]) / 32;
        }

        my $size = 1;
        $size = $instance->static_size unless $instance->is_dynamic;
        $current_offset += $size;
    }

    $current_offset = 0;
    my %response;
    # Dynamic data must to be set first since the full_size method
    # will need to use the data offset related to the size of the item
    for (my $i = 0; $i < $self->instances->@*; $i++) {
        my $instance = $self->instances->[$i];
        next unless $instance->is_dynamic;
        my $offset_start = shift @offsets;
        my $offset_end   = $offsets[0] // scalar @data - 1;
        my @range        = @data[$offset_start .. $offset_end];
        $instance->{data} = \@range;
        $current_offset += scalar @range;
        $response{$i} = $instance->decode();
    }

    $current_offset = 0;

    for (my $i = 0; $i < $self->instances->@*; $i++) {
        my $instance = $self->instances->[$i];

        if ($instance->is_dynamic) {
            $current_offset++;
            next;
        }

        my $size = 1;
        $size = $instance->static_size unless $instance->is_dynamic;
        my @range = @data[$current_offset .. $current_offset + $size - 1];
        $instance->{data} = \@range;
        $current_offset += $size;

        $response{$i} = $instance->decode();
    }

    my @array_response;
    # the given order of type signatures needs to be strict followed
    push(@array_response, $response{$_}) for 0 .. scalar $self->instances->@* - 1;
    return \@array_response;
}

1;

