# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for interacting with SIRTX VM chunks


package SIRTX::VM::Chunk;

use v5.16;
use strict;
use warnings;

use Carp;
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);

use Data::Identifier;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Known);

our $VERSION = v0.01;

use constant {
    WK_SID => Data::Identifier->new(uuid => 'f87a38cb-fd13-4e15-866c-e49901adbec5'), # small-identifier
    WK_SNI => Data::Identifier->new(uuid => '039e0bb7-5dd3-40ee-a98c-596ff6cce405'), # sirtx-numerical-identifier
    WK_HDI => Data::Identifier->new(uuid => 'f8eb04ef-3b8a-402c-ad7c-1e6814cb1998'), # host-defined-identifier
    WK_UDI => Data::Identifier->new(uuid => '05af99f9-4578-4b79-aabe-946d8e6f5888'), # user-defined-identifier

    FLAG_STANDALONE         => (1<<7),
    FLAG_CHUNK_IDENTIFIER   => (1<<1),
    FLAG_PADDING            => (1<<0),
};

my %_flags = map {$_ => 1} qw(standalone);

# Fields:
# - Opcode
# - Extra
# * Flags
# * Type
# * Chunk identifier
# - Data
# * Padding


sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {
        standalone => undef,
        type => undef,
        chunk_identifier => undef,
        data => undef,
    }, $pkg;

    if (defined(my $v = delete $opts{type})) {
        $self->type($v);
    }

    if (defined(my $v = delete $opts{flags})) {
        foreach my $flag (keys %{$v}) {
            $self->set_flag($flag => $v->{$flag});
        }
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub write {
    my ($self, $out, @opts) = @_;
    my $chunk_identifier = $self->chunk_identifier;
    my $data_length = $self->_data_length;
    my $body_length = 4 + (defined $chunk_identifier ? 2 : 0) + $data_length + ($data_length & 1);
    my $body_length_extra = $body_length / 2;
    my $flags = 0;
    my $extra;
    my $type;

    croak 'Stray options passed' if scalar @opts;

    croak 'Output handle in bad state: not 16 bit aligned' if $out->tell & 1;

    if ($body_length_extra <= 0xFFFF) {
        $extra = pack('n', $body_length_extra);
    } elsif ($body_length_extra <= 0xFFFF_FFFF) {
        $extra = pack('N', $body_length_extra);
    } else {
        ...;
    }

    {
        my $type_id = $self->type;

        $type = eval {$type_id->as(WK_SNI)};
        if (defined $type) {
            $flags |= (0<<15)|(0<<14);
            last;
        }

        $type = eval {$type_id->as(WK_SID)};
        if (defined $type) {
            $flags |= (0<<15)|(1<<14);
            last;
        }

        $type = eval {$type_id->as(WK_HDI)};
        if (defined $type) {
            $flags |= (1<<15)|(0<<14);
            last;
        }

        $type = eval {$type_id->as(WK_UDI)};
        if (defined $type) {
            $flags |= (1<<15)|(1<<14);
            last;
        }

        croak 'Unsupported type';
    }

    $flags |= FLAG_STANDALONE       if $self->{standalone};
    $flags |= FLAG_CHUNK_IDENTIFIER if defined $chunk_identifier;
    $flags |= FLAG_PADDING          if $data_length & 1;

    $out->print(pack('na*nn', 0x0638 + length($extra)/2, $extra, $flags, $type));

    if (defined $chunk_identifier) {
        $out->print(pack('n', $chunk_identifier));
    }

    {
        my $todo = $data_length;
        my $in = $self->{data}{fh};
        my $restore = $in->tell;

        $in->seek($self->{data}{offset}, SEEK_SET) or croak 'Cannot seek to correct input position';

        while ($todo) {
            my $step = $todo > 4096 ? 4096 : $todo;
            my $got = read($in, my $data, $step);

            if (!defined($got) || $got < 1) {
                last;
            }

            $out->print($data);

            $todo -= $got;
        }

        $in->seek($restore, SEEK_SET) or croak 'Cannot seek back on input';

        croak 'Incompelete data read on input' if $todo;
    }

    $out->print(chr(0)) if $data_length & 1;
}


sub read {
    my ($self, $in, @opts) = @_;
    my $opcode;
    my $data;
    my $extra2;
    my ($flags, $type);
    my $chunk_identifier;
    my $data_length;
    my $data_offset;

    croak 'Stray options passed' if scalar @opts;

    $in->read($data, 2) == 2 or croak 'Cannot read opcode';
    $opcode = unpack('n', $data);

    croak sprintf('Bad opcode: 0x%04x', $opcode) unless ($opcode & 0xFFF8) == 0x0638;

    if (($opcode & 0x7) == 1) {
        $in->read($data, 2) == 2 or croak 'Cannot read extra';
        $extra2 = unpack('n', $data) * 2;
    } elsif (($opcode & 0x7) == 2) {
        $in->read($data, 4) == 2 or croak 'Cannot read extra';
        $extra2 = unpack('N', $data) * 2;
    } else {
        ...
    }

    $in->read($data, 4) == 4 or croak 'Cannot read header';
    ($flags, $type) = unpack('nn', $data);

    if ($flags & FLAG_CHUNK_IDENTIFIER) {
        $in->read($data, 2) == 2 or croak 'Cannot read chunk identifier';
        $chunk_identifier = unpack('n', $data);
    }

    $data_length = $extra2 - 4 - ($flags & FLAG_CHUNK_IDENTIFIER ? 2 : 0) - ($flags & FLAG_PADDING ? 1 : 0);

    $data_offset = $in->tell or croak 'Cannot tell on input handle';

    $in->seek($data_length, SEEK_CUR);

    if ($flags & FLAG_PADDING) {
        $in->read($data, 1) == 1 or croak 'Cannot read padding';
        croak 'Invalid padding' unless ord($data) == 0;
    }

    {
        my $flags_type = $flags & ((1<<15)|(1<<14));

        if ($flags_type == ((0<<15)|(0<<14))) {
            $self->type(Data::Identifier->new(sni => $type));
        } elsif ($flags_type == ((0<<15)|(1<<14))) {
            $self->type(Data::Identifier->new(sid => $type));
        } elsif ($flags_type == ((1<<15)|(0<<14))) {
            $self->type(Data::Identifier->new(WK_HDI => $type));
        } elsif ($flags_type == ((1<<15)|(1<<14))) {
            $self->type(Data::Identifier->new(WK_UDI => $type));
        }
    }

    $self->set_flag(standalone => $flags & FLAG_STANDALONE);
    $self->chunk_identifier($chunk_identifier);
    $self->attach_data($in, $data_offset, $data_length);
}


sub type {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    if (defined $n) {
        $self->{type} = Data::Identifier->new(from => $n);
    }

    return $self->{type};
}


sub chunk_identifier {
    my ($self, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    if (defined $n) {
        $n =~ s/^~([0-9]+)$/$1/;
        $n = int($n);

        croak 'Bad chunk identifier' unless $n >= 0;

        croak 'Chunk is read only' if $self->{read_only};

        $n = undef unless $n > 0;
        $self->{chunk_identifier} = $n;
    }

    return $self->{chunk_identifier};
}


sub padding {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->_data_length & 1;
}


sub flag {
    my ($self, $flag, $n, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    croak 'Not a known flag: '.$flag unless $_flags{$flag};

    if (defined $n) {
        $self->{$flag} = !!$n;
    }

    return $self->{$flag};
}


sub set_flag {
    my ($self, $flag, $n, @opts) = @_;

    $n //= 0;

    return $self->flag($flag, $n, @opts);
}


sub attach_data {
    my ($self, $fh, $offset, $length, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    croak 'No valid data handle given' unless ref $fh;

    $offset //= $fh->tell // croak 'Cannot tell position on data handle';

    unless (defined $length) {
        my $pos = $fh->tell;

        $fh->seek(0, SEEK_END) or croak 'Cannot seek in data handle';

        $length = $fh->tell - $offset;

        $fh->seek($pos, SEEK_SET) or croak 'Cannot seek in data handle';
    }

    $self->{data} = {
        fh      => $fh,
        offset  => $offset,
        length  => $length,
    };
}


sub read_data {
    my ($self, $length, $offset) = @_;
    my $data = $self->{data};
    my $res;

    $length = int($length // 0);
    $offset = int($offset // 0);

    croak 'Bad length' if $length < 0;
    croak 'Bad offset' if $offset < 0;
    croak 'No data attached' unless defined $data;

    return undef if $offset >= $data->{length};

    $length = $data->{length} - $offset if ($length + $offset) > $data->{length};

    {
        my $pos = $data->{fh}->tell;

        $data->{fh}->seek($data->{offset} + $offset, SEEK_SET) or croak 'Cannot seek forward';

        $data->{fh}->read($res, $length);

        $data->{fh}->seek($pos, SEEK_SET) or croak 'Cannot seek back';
    }

    return $res;
}

# ---- Private helpers ----

sub _data_length {
    my ($self) = @_;

    croak 'No data attached' unless defined $self->{data};

    return $self->{data}{length};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SIRTX::VM::Chunk - module for interacting with SIRTX VM chunks

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use SIRTX::VM::Chunk;

This package inherits from L<Data::Identifier::Interface::Userdata> and L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 new

    my SIRTX::VM::Chunk $chunk = SIRTX::VM::Chunk->new;

(since v0.01)

Creates a new chunk object.

The following options are supported:

=over

=item C<type>

The type of the chunk as per L</type>.

=item C<flags>

A hashref with flags that are to be set as per L</set_flag>.

=back

=head2 write

    $chunk->write($fh);

(since v0.01)

Writes the chunk to the given file handle.
No options are supported.

=head2 read

    $chunk->read($fh);

(since v0.01)

Reads the chunk from the given file handle.
Resets all internal state of the chunk.
No options are supported.

B<Note:>
The handle to read from needs to support L<perlfunc/tell> and L</perlfunc/seek>.

B<Note:>
A reference to the handle is stored in the object as per L</attach_data>.
See details on what operations are allowed on the handle after this call.

=head2 type

    my Data::Identifier $type = $chunk->type;
    # or:
    $chunk->type($type);

(since v0.01)

Gets or sets the type of the chunk.

If the type is set and C<$type> is not a L<Data::Identifier> it is converted
as per L<Data::Identifier/new> using C<from>.

B<Note:>
In order to be useable a type must have a valid I<sid> (C<small-identifier>),
I<sni> (C<sirtx-numerical-identifier>) assigned, or being mapped to a host defined identifier,
or a private identifier.

=head2 chunk_identifier

    my $chunk_identifier = $chunk->chunk_identifier;
    # or:
    $chunk->chunk_identifier($chunk_identifier);

(experimental since v0.01)

Gets or sets the chunk identifier.

B<Note:>
The type and range of this value is not yet fully defined and may be changed in later versions of this module.

=head2 padding

    my $padding = $chunk->padding;

(experimental since v0.01)

Returns the padding status of the chunk.

Padding is automatically added by this module as needed.

B<Note:>
The return type and range is not yet defined.
However it is defined that the returned value will be true-ish if any non-zero amount of padding is used and
false-ish if no padding is used.

B<Note:>
This method is hardly useful for most code. It is provided only for debugging.

B<Note:>
The returned value might or might not reflect the value as read by L</read>.
It might be a calculated value.

    my $bool = $chunk->flag($flag);
    # or:
    $chunk->flag($flag => $value); # value is not undef!

(since v0.01)

Gets or sets the boolean state of a flag.

Currently the only supported flag is C<standalone>.

This method can be used to set the state of the flag.
However L</set_flag> is often the more secure method to do this
as it is not tri-state.

=head2 set_flag

    $chunk->set_flag($flag => $value); # any boolean, including undef

(since v0.01)

Sets the value of a flag.
See L</flag> for details on flags.

=head2 attach_data

    $chunk->attach_data($fh [, $offset [, $length]]);

(since v0.01)

Attaches an open handle as data for a chunk.

The passed handle (C<$fh>) will be stored as a reference inside the chunk object.

The passed handle must support L<perlfunc/tell>, L<perlfunc/seek>, and L<perlfunc/read>.

Optionally a offset and a length can be given to only use a subrange of the data as body for the chunk.
This is analogous to L<perlfunc/substr>.
If no offset is given the current offset (not the start/offset 0) is used as offset.
This is specifically designed to allow stream like reading.
If no length is given the length from the offset to the end of the file is used.
If C<$fh> refers to a freshly opened file this results in all of the file being used as body by default.

B<Note:>
The an internal reference to the handle is used to avoid loading the content in memory or into a temporary file.
This specifically allowes for chunks with large bodies.

B<Note:>
While an internal reference is held by the chunk the handle may go out of scope by the caller.
However it is not valid to call L<perlfunc/close> on the handle.

B<Note:>
The handle must be in a 8 bit binary mode before passed to this function.
See also L<perlfunc/binmode> regarding binary mode.

B<Note:>
If the data the handle refers to is altered in the used range (see offset and length) after this method is called
the behaviour is undefined.

=head2 read_data

    my $data = $chunk->read_data($length [, $offset]);

(experimental since v0.01)

Reads data from the body of the chunk.

This method reads at most C<$length> bytes at the offset of C<$offset> (defaults to C<0>).
The result will be returned.

If a read starting beyond the end of the data is requested C<undef> is returned.
If less than C<$length> bytes are available a the available bytes are returned.

If any invalid values are passed this method will C<die>.

B<Note:>
This method does not store the current read position.
Hence any read that is not to read from the very beginning must provide a C<$offset>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
