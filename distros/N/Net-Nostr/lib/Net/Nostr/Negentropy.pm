package Net::Nostr::Negentropy;

use strictures 2;

use Carp qw(croak);
use Digest::SHA qw(sha256);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $IDLIST_THRESHOLD = 48;

use constant INFINITY_TS => ~0;

sub new {
    my ($class, %args) = @_;
    my @unknown = grep { $_ ne 'frame_size_limit' } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return bless {
        _items        => [],
        _sealed       => 0,
        _is_initiator => 0,
        frame_size_limit => $args{frame_size_limit} // 0,
    }, $class;
}

sub add_item {
    my ($self, $timestamp, $id_hex) = @_;
    croak "cannot add items after sealed" if $self->{_sealed};
    croak "timestamp must be a non-negative integer"
        unless defined $timestamp && $timestamp >= 0 && $timestamp == int($timestamp);
    croak "timestamp must not be the reserved infinity value"
        if $timestamp == INFINITY_TS;
    croak "id must be 64-char lowercase hex" unless defined $id_hex && $id_hex =~ $HEX64;
    push @{$self->{_items}}, [$timestamp, pack('H*', $id_hex)];
}

sub seal {
    my ($self) = @_;
    $self->{_items} = [
        sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @{$self->{_items}}
    ];
    $self->{_sealed} = 1;
}

sub initiate {
    my ($self) = @_;
    croak "must seal before initiate" unless $self->{_sealed};
    $self->{_is_initiator} = 1;

    my @items = @{$self->{_items}};

    my @ranges;

    if (@items <= $IDLIST_THRESHOLD) {
        push @ranges, {
            upper   => [INFINITY_TS, ''],
            mode    => 2,
            payload => [map { $_->[1] } @items],
        };
    } else {
        my $n_ranges = int(sqrt(@items));
        $n_ranges = 2 if $n_ranges < 2;
        my $per_range = int(@items / $n_ranges);

        for my $i (0 .. $n_ranges - 1) {
            my $start = $i * $per_range;
            my $end = ($i == $n_ranges - 1) ? $#items : ($start + $per_range - 1);
            my @range_items = @items[$start .. $end];

            my $upper;
            if ($i == $n_ranges - 1) {
                $upper = [INFINITY_TS, ''];
            } else {
                $upper = _compute_bound($items[$end], $items[$end + 1]);
            }

            push @ranges, {
                upper   => $upper,
                mode    => 1,
                payload => _fingerprint(@range_items),
            };
        }
    }

    return unpack('H*', _encode_message(\@ranges));
}

sub reconcile {
    my ($self, $hex_msg) = @_;
    croak "must seal before reconcile" unless $self->{_sealed};

    my $msg_bytes = pack('H*', $hex_msg);
    my $ranges = _decode_message($msg_bytes);

    my @items = @{$self->{_items}};
    my @response_ranges;
    my @have_ids;
    my @need_ids;

    my $lower = [0, ''];
    my $have_non_skip = 0;

    for my $range (@$ranges) {
        my $upper = $range->{upper};
        my @local = _items_in_range(\@items, $lower, $upper);

        if ($range->{mode} == 0) {
            push @response_ranges, { upper => $upper, mode => 0, payload => undef };
        }
        elsif ($range->{mode} == 1) {
            my $local_fp = _fingerprint(@local);
            if ($local_fp eq $range->{payload}) {
                push @response_ranges, { upper => $upper, mode => 0, payload => undef };
            }
            elsif (@local <= $IDLIST_THRESHOLD) {
                push @response_ranges, {
                    upper   => $upper,
                    mode    => 2,
                    payload => [map { $_->[1] } @local],
                };
                $have_non_skip = 1;
            }
            else {
                push @response_ranges, _split_items_into_ranges(\@local, $upper);
                $have_non_skip = 1;
            }
        }
        elsif ($range->{mode} == 2) {
            my %their_ids = map { $_ => 1 } @{$range->{payload}};
            my %our_ids   = map { $_->[1] => 1 } @local;

            for my $id (@{$range->{payload}}) {
                push @need_ids, unpack('H*', $id) unless $our_ids{$id};
            }
            for my $item (@local) {
                push @have_ids, unpack('H*', $item->[1]) unless $their_ids{$item->[1]};
            }

            if ($self->{_is_initiator}) {
                push @response_ranges, { upper => $upper, mode => 0, payload => undef };
            } else {
                push @response_ranges, {
                    upper   => $upper,
                    mode    => 2,
                    payload => [map { $_->[1] } @local],
                };
                $have_non_skip = 1;
            }
        }

        $lower = $upper;
    }

    my $response_hex;
    if ($have_non_skip) {
        $response_hex = unpack('H*', _encode_message(\@response_ranges));
    } else {
        $response_hex = undef;
    }

    return ($response_hex, \@have_ids, \@need_ids);
}

# --- Binary protocol internals ---

sub _encode_varint {
    my ($n) = @_;
    my @bytes;
    do {
        unshift @bytes, $n & 0x7f;
        $n >>= 7;
    } while ($n > 0);
    $bytes[$_] |= 0x80 for 0 .. $#bytes - 1;
    return pack('C*', @bytes);
}

sub _decode_varint {
    my ($buf, $pos) = @_;
    my $n = 0;
    while (1) {
        croak "varint: unexpected end of buffer" if $pos >= length($buf);
        my $byte = ord(substr($buf, $pos++, 1));
        $n = ($n << 7) | ($byte & 0x7f);
        last unless $byte & 0x80;
    }
    return ($n, $pos);
}

sub _encode_message {
    my ($ranges) = @_;
    my $msg = chr(0x61);
    my $prev_ts = 0;
    for my $range (@$ranges) {
        my ($ts, $prefix) = @{$range->{upper}};

        # Encode bound
        my $encoded_ts;
        if ($ts == INFINITY_TS) {
            $encoded_ts = 0;
        } else {
            $encoded_ts = 1 + ($ts - $prev_ts);
        }
        $msg .= _encode_varint($encoded_ts);
        $msg .= _encode_varint(length($prefix));
        $msg .= $prefix;

        # Encode mode + payload
        $msg .= _encode_varint($range->{mode});
        if ($range->{mode} == 1) {
            $msg .= $range->{payload};
        } elsif ($range->{mode} == 2) {
            my @ids = @{$range->{payload}};
            $msg .= _encode_varint(scalar @ids);
            $msg .= $_ for @ids;
        }

        $prev_ts = $ts unless $ts == INFINITY_TS;
    }
    return $msg;
}

sub _decode_message {
    my ($buf) = @_;
    croak "empty message" unless length $buf;
    my $version = ord(substr($buf, 0, 1));
    croak "unsupported negentropy protocol version: $version"
        unless $version == 0x61;

    my @ranges;
    my $pos = 1;
    my $prev_ts = 0;

    while ($pos < length $buf) {
        # Decode bound
        my ($encoded_ts, $pos2) = _decode_varint($buf, $pos);
        my $ts;
        if ($encoded_ts == 0) {
            $ts = INFINITY_TS;
        } else {
            $ts = $prev_ts + $encoded_ts - 1;
        }
        my ($prefix_len, $pos3) = _decode_varint($buf, $pos2);
        my $prefix = substr($buf, $pos3, $prefix_len);
        $pos = $pos3 + $prefix_len;

        # Decode mode
        my ($mode, $pos4) = _decode_varint($buf, $pos);
        $pos = $pos4;

        my $payload;
        if ($mode == 0) {
            $payload = undef;
        } elsif ($mode == 1) {
            $payload = substr($buf, $pos, 16);
            $pos += 16;
        } elsif ($mode == 2) {
            my ($count, $pos5) = _decode_varint($buf, $pos);
            $pos = $pos5;
            my @ids;
            for (1 .. $count) {
                push @ids, substr($buf, $pos, 32);
                $pos += 32;
            }
            $payload = \@ids;
        } else {
            croak "unknown range mode: $mode";
        }

        push @ranges, {
            upper   => [$ts, $prefix],
            mode    => $mode,
            payload => $payload,
        };

        $prev_ts = $ts unless $ts == INFINITY_TS;
    }

    return \@ranges;
}

sub _fingerprint {
    my (@items) = @_;
    my @sum = (0) x 32;
    for my $item (@items) {
        my @id = unpack('C*', $item->[1]);
        my $carry = 0;
        for my $i (0 .. 31) {
            my $s = $sum[$i] + $id[$i] + $carry;
            $sum[$i] = $s & 0xFF;
            $carry = $s >> 8;
        }
    }
    my $sum_bytes = pack('C*', @sum);
    my $data = $sum_bytes . _encode_varint(scalar @items);
    return substr(sha256($data), 0, 16);
}

sub _compute_bound {
    my ($item_a, $item_b) = @_;
    if ($item_a->[0] != $item_b->[0]) {
        return [$item_b->[0], ''];
    }
    my $len = 0;
    while ($len < 32 && substr($item_a->[1], $len, 1) eq substr($item_b->[1], $len, 1)) {
        $len++;
    }
    return [$item_b->[0], substr($item_b->[1], 0, $len + 1)];
}

sub _items_in_range {
    my ($items, $lower, $upper) = @_;
    my @result;
    for my $item (@$items) {
        next unless _item_ge_bound($item, $lower);
        last if !_item_lt_bound($item, $upper);
        push @result, $item;
    }
    return @result;
}

sub _item_ge_bound {
    my ($item, $bound) = @_;
    my ($bts, $bprefix) = @$bound;
    return 1 if $item->[0] > $bts;
    return 0 if $item->[0] < $bts;
    my $padded = $bprefix . ("\x00" x (32 - length($bprefix)));
    return $item->[1] ge $padded;
}

sub _item_lt_bound {
    my ($item, $bound) = @_;
    my ($bts, $bprefix) = @$bound;
    return 1 if $bts == INFINITY_TS;
    return 1 if $item->[0] < $bts;
    return 0 if $item->[0] > $bts;
    my $padded = $bprefix . ("\x00" x (32 - length($bprefix)));
    return $item->[1] lt $padded;
}

sub _split_items_into_ranges {
    my ($items, $final_upper) = @_;
    my $n = int(sqrt(scalar @$items));
    $n = 2 if $n < 2;
    my $per = int(@$items / $n);

    my @ranges;
    for my $i (0 .. $n - 1) {
        my $start = $i * $per;
        my $end = ($i == $n - 1) ? $#{$items} : ($start + $per - 1);
        my @sub = @{$items}[$start .. $end];

        my $upper;
        if ($i == $n - 1) {
            $upper = $final_upper;
        } else {
            $upper = _compute_bound($items->[$end], $items->[$end + 1]);
        }

        push @ranges, {
            upper   => $upper,
            mode    => 1,
            payload => _fingerprint(@sub),
        };
    }
    return @ranges;
}

1;

__END__


=head1 NAME

Net::Nostr::Negentropy - NIP-77 negentropy set reconciliation

=head1 SYNOPSIS

    use Net::Nostr::Negentropy;

    # Client side
    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, '01' x 32);
    $client->add_item(2000, '02' x 32);
    $client->seal;

    my $q = $client->initiate;
    # Send $q in NEG-OPEN message

    # Server side
    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(1000, '01' x 32);
    $server->add_item(3000, '03' x 32);
    $server->seal;

    my ($response, $s_have, $s_need) = $server->reconcile($q);
    # Send $response in NEG-MSG

    # Client processes response
    my ($next, $c_have, $c_need) = $client->reconcile($response);
    # $c_have = ['02' x 32]   -- client has, server doesn't
    # $c_need = ['03' x 32]   -- server has, client doesn't
    # If $next is defined, send as NEG-MSG and continue

=head1 DESCRIPTION

Implements the Negentropy set reconciliation protocol as specified in
NIP-77. This protocol efficiently determines the symmetric difference
between two sets of events by exchanging fingerprints and progressively
narrowing mismatched ranges.

The protocol uses a binary message format with varint encoding,
range-based fingerprints (SHA-256 of modular ID sums), and ID lists.
Messages are hex-encoded for transmission over the Nostr WebSocket
protocol.

Typical flow:

=over 4

=item 1. Both sides create a Negentropy instance, add their local
events via L</add_item>, and call L</seal>.

=item 2. The client (initiator) calls L</initiate> to produce the
initial message.

=item 3. The server calls L</reconcile> with the client's message
and returns a response.

=item 4. The client calls L</reconcile> with the server's response.
If the return message is C<undef>, the protocol is complete.
Otherwise, send the message and repeat from step 3.

=back

After reconciliation, the client knows which IDs it has that the
server lacks (C<have>) and which IDs the server has that it lacks
(C<need>). It can then use C<EVENT> to upload and C<REQ> to download.

=head1 CONSTRUCTOR

=head2 new

    my $ne = Net::Nostr::Negentropy->new;
    my $ne = Net::Nostr::Negentropy->new(frame_size_limit => 4096);

Creates a new Negentropy instance. Croaks on unknown arguments.

Options:

=over 4

=item C<frame_size_limit> -- maximum byte size for encoded protocol
messages. Defaults to C<0> (unlimited).

=back

=head1 METHODS

=head2 add_item

    $ne->add_item($timestamp, $id_hex);

Adds an event to the local set. C<$timestamp> must be a non-negative
integer (the event's C<created_at>). The maximum uint64 value
(C<2**64 - 1>) is reserved as the protocol's infinity timestamp and
is rejected. C<$id_hex> must be a 64-character lowercase hex string
(the event ID). Croaks if called after L</seal>.

=head2 seal

    $ne->seal;

Sorts the items and finalizes the set. Must be called before
L</initiate> or L</reconcile>. After sealing, L</add_item> is no
longer allowed.

=head2 initiate

    my $hex_msg = $ne->initiate;

Creates the initial reconciliation message. Returns a hex-encoded
binary message string. This marks the instance as the initiator
(client side). Croaks if not sealed.

=head2 reconcile

    my ($hex_response, $have_ids, $need_ids) = $ne->reconcile($hex_msg);

Processes a reconciliation message from the other side. Returns:

=over 4

=item C<$hex_response> -- the response message (hex string), or
C<undef> if the protocol is complete

=item C<$have_ids> -- arrayref of hex ID strings that we have and
they don't

=item C<$need_ids> -- arrayref of hex ID strings that they have and
we don't

=back

Croaks if not sealed.

=head1 SEE ALSO

L<NIP-77|https://github.com/nostr-protocol/nips/blob/master/77.md>,
L<Net::Nostr>, L<Net::Nostr::Message>

=cut
