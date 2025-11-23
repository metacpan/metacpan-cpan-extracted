# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM chunks


package SIRTX::VM::Chunk::Type::OctetStream;

use v5.16;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);

use parent 'SIRTX::VM::Chunk::Type';

our $VERSION = v0.02;

sub attach_data {
    my ($self, @opts) = @_;
    return $self->SIRTX::VM::Chunk::attach_data(@opts);
}


sub ingest_object {
    my ($self, $obj, @opts) = @_;
    my $blob;

    croak 'Stray options passed' if scalar @opts;

    croak 'Object is not blessed' unless blessed $obj;

    if ($obj->isa('String::Super')) {
        $blob = $obj->result;
    }

    croak 'Not a supported object or no data found' unless defined $blob;

    {
        open(my $fh, '<:raw', \$blob);
        $self->attach_data($fh);
    }
}

# ---- Private helpers ----

sub _create_data {
    my ($self) = @_;
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

SIRTX::VM::Chunk::Type::OctetStream - module for interacting with SIRTX VM chunks

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use SIRTX::VM::Chunk::Type::OctetStream;

    my SIRTX::VM::Chunk $chunk = SIRTX::VM::Chunk::Type::OctetStream->new;

(since v0.02)

This represends an octet stream chunk.
Such a chunk is used to store unstructured data.

This inherits from L<SIRTX::VM::Chunk>.

=head2 ingest_object

    $chunk->ingest_object($obj);

(experimental since v0.02)

Ingests an object as the data source for this chunk.
This is similar to L<SIRTX::VM::Chunk/attach_data>
but works with Perl objects.

Currently only L<String::Super> is supported.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
