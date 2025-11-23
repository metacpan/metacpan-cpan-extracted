# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM chunks


package SIRTX::VM::Chunk::Type::ColourPalette;

use v5.16;
use strict;
use warnings;

use Carp;

use Data::URIID::Colour;

use parent 'SIRTX::VM::Chunk::Type';

our $VERSION = v0.02;


sub offset {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    if (defined $n) {
        $n = int($n);

        if ($n < 1 || $n > 0xFFFF) {
            croak 'Invalid offset';
        }

        $self->{type_data}{offset} = $n;
    }

    return $self->{type_data}{offset};
}


sub get_colour {
    my ($self, $idx, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $idx = int($idx) - $self->{type_data}{offset};

    croak 'Invalid index, did you try a relative offset as index' if $idx < 0;

    return $self->{type_data}{colours}[$idx] // croak 'No such entry';
}


sub set_colour {
    my ($self, $idx, $colour, @opts) = @_;
    my $type_data = $self->{type_data};

    croak 'Stray options passed' if scalar @opts;

    $idx = int($idx) - $type_data->{offset};

    croak 'Invalid index, did you try a relative offset as index' if $idx < 0;

    unless (eval {$colour->isa('Data::URIID::Colour')}) {
        $colour = Data::URIID::Colour->new(rgb => $colour);
    }

    if ($idx > 0) {
        croak 'Setting colour would create hole' unless defined $type_data->{colours}[$idx - 1];
    }

    $type_data->{colours}[$idx] = $colour;

    return $self;
}


sub add_colour {
    my ($self, $colour, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    unless (eval {$colour->isa('Data::URIID::Colour')}) {
        $colour = Data::URIID::Colour->new(rgb => $colour);
    }

    push(@{$self->{type_data}{colours}}, $colour);
}

# ---- Private helpers ----

sub _create_data {
    my ($self) = @_;
    my $str = "\0\0";
    open(my $fh, '<:raw', \$str);
    $self->SIRTX::VM::Chunk::attach_data($fh);
}

sub _parse {
    my ($self) = @_;
    my $length = $self->_data_length;
    my @colours;
    my $type_data = $self->{type_data} = {colours => \@colours};
    my $offset = 2;
    my $data;

    if ($length < 2 || (($length - 2) % 3) != 0) {
        croak 'Invalid data, bad length';
    }

    $type_data->{offset} = unpack('n', $self->read_data(2));

    while ($offset < $length) {
        my ($r, $g, $b) = unpack('CCC', $self->read_data(3, $offset));

        push(@colours, Data::URIID::Colour->new(rgb => sprintf('#%02x%02x%02x', $r, $g, $b)));

        $offset += 3;
    }
}

sub _render {
    my ($self) = @_;
    my $type_data = $self->{type_data};
    my $str = join('', map {substr($_->rgb, 1)} @{$type_data->{colours}});

    use Data::Dumper;
    warn Dumper($type_data, $str);
    $str = pack('nH*', $type_data->{offset}, $str);

    open(my $fh, '<:raw', \$str);
    $self->SIRTX::VM::Chunk::attach_data($fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Chunk::Type::ColourPalette - module for interacting with SIRTX VM chunks

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use SIRTX::VM::Chunk::Type::ColourPalette;

    my SIRTX::VM::Chunk $chunk = SIRTX::VM::Chunk::Type::ColourPalette->new;

    $chunk->offset($first_id);
    $chunk->add_colour(@colours);

(since v0.02)

This type represents a colour palette.
Such a palette consists of a number of colour values being mapped to C<user-defined-identifier>s.

This inherits from L<SIRTX::VM::Chunk>.

=head2 offset

    my $offset = $chunk->offset;
    # or:
    $chunk->offset($offset);

(experimental since v0.02)

This gets or sets the offset of the colour plaette into the C<user-defined-identifier> space.

The types and ranges used by this method are subject to change.

B<Note:>
As per specification of the identifier space a value of zero (null-identifier) is invalid.
Values past C<2^16-1> (or: C<0xFFFF>) are also invalid.

=head2 get_colour

    my $colour = $chunks->get_colour($idx);

(experimental since v0.02)

Gets a colour by it's C<user-defined-identifier>.

The types and ranges used by this method are subject to change.

=head2 set_colour

    $chunks->set_colour($idx => $colour);

(experimental since v0.02)

Sets a colour by it's C<user-defined-identifier>.

The types and ranges used by this method are subject to change.

B<Note:>
This method may refuse setting colours if the result would creat an invalid state that could not be written.
This is specifically true for creating holes.
Hence it is recommended to add colours using L</add_colour> or add them in-order.

=head2 add_colour

    $chunks->add_colour($colour);

(experimental since v0.02)

Adds a colour to the palette.

The types and ranges used by this method are subject to change.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
