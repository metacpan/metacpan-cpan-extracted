# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM chunks


package SIRTX::VM::Chunk::Type::Padding;

use v5.16;
use strict;
use warnings;

use Carp;

use parent 'SIRTX::VM::Chunk::Type';

our $VERSION = v0.03;


sub data_size {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    if (defined $n) {
        my $str = chr(0) x $n;
        open(my $fh, '<:raw', \$str);
        $self->SIRTX::VM::Chunk::attach_data($fh);
    }

    return $self->_data_length;
}

# ---- Private helpers ----

sub _create_data {
    my ($self) = @_;
    $self->data_size(0);
}

sub _parse {
    # no-op
}

sub _render {
    # no-op
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Chunk::Type::Padding - module for interacting with SIRTX VM chunks

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use SIRTX::VM::Chunk::Type::Padding;

    my SIRTX::VM::Chunk $chunk = SIRTX::VM::Chunk::Type::Padding->new;

    $chunk->data_size($size);

(since v0.02)

This represends a padding chunk.

This inherits from L<SIRTX::VM::Chunk>.

=head2 data_size

    my $size = $chunk->data_size;
    # or:
    $chunk->data_size($size);

Sets the (data size) of the padding chunk.

B<Note:>
The actual size of the chunk will be larger than this value due to it's header and framing considerations.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
