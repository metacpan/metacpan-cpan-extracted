package Net::Nostr::RelayStore;

use strictures 2;

use Carp qw(croak);

sub new {
    my $class = shift;
    my %args = @_;

    my %known = map { $_ => 1 } qw(max_events);
    my @unknown = grep { !$known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    if (defined $args{max_events}) {
        croak "max_events must be a positive integer"
            unless $args{max_events} =~ /^\d+$/ && $args{max_events} > 0;
    }

    my $self = bless {
        max_events          => $args{max_events},
        _by_id              => {},
        _by_pubkey_kind     => {},
        _by_pubkey_kind_dtag => {},
        _by_kind            => {},
        _by_pubkey          => {},
        _by_tag             => {},
        _ordered            => [],
    }, $class;

    return $self;
}

sub max_events { $_[0]->{max_events} }

sub event_count { scalar @{$_[0]->{_ordered}} }

sub store {
    my ($self, $event) = @_;

    my $id = $event->id;
    return 0 if exists $self->{_by_id}{$id};

    # primary index
    $self->{_by_id}{$id} = $event;

    # kind index
    $self->{_by_kind}{$event->kind}{$id} = $event;

    # pubkey index
    $self->{_by_pubkey}{$event->pubkey}{$id} = $event;

    # replaceable index: only update if this event is newer (or no current entry)
    if ($event->is_replaceable) {
        my $key = $event->pubkey . ':' . $event->kind;
        my $current = $self->{_by_pubkey_kind}{$key};
        if (!$current || _is_newer($event, $current)) {
            $self->{_by_pubkey_kind}{$key} = $event;
        }
    }

    # addressable index: only update if this event is newer (or no current entry)
    if ($event->is_addressable) {
        my $key = $event->pubkey . ':' . $event->kind . ':' . $event->d_tag;
        my $current = $self->{_by_pubkey_kind_dtag}{$key};
        if (!$current || _is_newer($event, $current)) {
            $self->{_by_pubkey_kind_dtag}{$key} = $event;
        }
    }

    # tag index
    for my $tag (@{$event->_tags}) {
        next unless defined $tag->[0] && defined $tag->[1];
        my $key = $tag->[0] . ':' . $tag->[1];
        $self->{_by_tag}{$key}{$id} = $event;
    }

    # ordered list: insert in sorted position (created_at DESC, id ASC)
    $self->_insert_ordered($event);

    # eviction
    if (defined $self->{max_events} && $self->event_count > $self->{max_events}) {
        my $oldest = $self->{_ordered}[-1];
        $self->delete_by_id($oldest->id);
    }

    return 1;
}

sub get_by_id {
    my ($self, $id) = @_;
    return $self->{_by_id}{$id};
}

sub find_replaceable {
    my ($self, $pubkey, $kind) = @_;
    my $key = "$pubkey:$kind";
    return $self->{_by_pubkey_kind}{$key};
}

sub find_addressable {
    my ($self, $pubkey, $kind, $d_tag) = @_;
    my $key = "$pubkey:$kind:$d_tag";
    return $self->{_by_pubkey_kind_dtag}{$key};
}

sub delete_by_id {
    my ($self, $id) = @_;

    my $event = delete $self->{_by_id}{$id};
    return undef unless $event;

    # kind index
    delete $self->{_by_kind}{$event->kind}{$id};

    # pubkey index
    delete $self->{_by_pubkey}{$event->pubkey}{$id};

    # replaceable index: promote next best candidate if we removed the current entry
    if ($event->is_replaceable) {
        my $key = $event->pubkey . ':' . $event->kind;
        if ($self->{_by_pubkey_kind}{$key}
            && $self->{_by_pubkey_kind}{$key}->id eq $id) {
            delete $self->{_by_pubkey_kind}{$key};
            my $best = $self->_find_best_replaceable($event->pubkey, $event->kind);
            $self->{_by_pubkey_kind}{$key} = $best if $best;
        }
    }

    # addressable index: promote next best candidate if we removed the current entry
    if ($event->is_addressable) {
        my $key = $event->pubkey . ':' . $event->kind . ':' . $event->d_tag;
        if ($self->{_by_pubkey_kind_dtag}{$key}
            && $self->{_by_pubkey_kind_dtag}{$key}->id eq $id) {
            delete $self->{_by_pubkey_kind_dtag}{$key};
            my $best = $self->_find_best_addressable($event->pubkey, $event->kind, $event->d_tag);
            $self->{_by_pubkey_kind_dtag}{$key} = $best if $best;
        }
    }

    # tag index
    for my $tag (@{$event->_tags}) {
        next unless defined $tag->[0] && defined $tag->[1];
        my $key = $tag->[0] . ':' . $tag->[1];
        delete $self->{_by_tag}{$key}{$id};
    }

    # ordered list: binary search for exact position, then single splice
    my $ordered = $self->{_ordered};
    my $cat = $event->created_at;
    my $eid = $event->id;
    my ($lo, $hi) = (0, scalar @$ordered);
    while ($lo < $hi) {
        my $mid = int(($lo + $hi) / 2);
        my $cmp = $cat <=> $ordered->[$mid]->created_at;
        if ($cmp == 0) {
            $cmp = $ordered->[$mid]->id cmp $eid;
        }
        if ($cmp > 0) {
            $hi = $mid;
        } else {
            $lo = $mid + 1;
        }
    }
    # $lo is the insertion point; scan nearby for exact match
    # (binary search lands at or near the element)
    if ($lo > 0 && $ordered->[$lo - 1]->id eq $eid) {
        splice @$ordered, $lo - 1, 1;
    } elsif ($lo < @$ordered && $ordered->[$lo]->id eq $eid) {
        splice @$ordered, $lo, 1;
    } else {
        # fallback linear scan (shouldn't happen with consistent data)
        for my $i (0 .. $#$ordered) {
            if ($ordered->[$i]->id eq $eid) {
                splice @$ordered, $i, 1;
                last;
            }
        }
    }

    return $event;
}

sub delete_matching {
    my ($self, $pubkey, $ids, $addresses, $before_ts) = @_;
    my $count = 0;

    # delete by event id
    for my $id (@$ids) {
        my $event = $self->{_by_id}{$id};
        next unless $event;
        next unless $event->pubkey eq $pubkey;
        next if $event->kind == 5;
        $self->delete_by_id($id);
        $count++;
    }

    # delete by address (kind:pubkey:d_tag or kind:pubkey: for replaceable)
    for my $addr (@$addresses) {
        my ($kind, $addr_pubkey, $d_tag) = split /:/, $addr, 3;
        next unless defined $d_tag;

        my $event;
        if (length $d_tag) {
            # Addressable event (kind 30000-39999)
            my $key = "$addr_pubkey:$kind:$d_tag";
            $event = $self->{_by_pubkey_kind_dtag}{$key};
        } else {
            # Replaceable event (kind 0, 3, 10000-19999) — empty d_tag
            my $key = "$addr_pubkey:$kind";
            $event = $self->{_by_pubkey_kind}{$key};
        }
        next unless $event;
        next unless $event->pubkey eq $pubkey;
        next if $event->kind == 5;
        next if $event->created_at > $before_ts;
        $self->delete_by_id($event->id);
        $count++;
    }

    return $count;
}

sub query {
    my ($self, $filters) = @_;

    my %seen;
    my @results;

    for my $filter (@$filters) {
        my $candidates = $self->_candidates_for($filter);
        my $limit = $filter->limit;
        my $count = 0;

        for my $event (@$candidates) {
            last if defined $limit && $count >= $limit;
            next if $event->is_expired;
            next if $seen{$event->id};
            next unless $filter->matches($event);
            $seen{$event->id} = 1;
            push @results, $event;
            $count++;
        }
    }

    # final sort: created_at DESC, id ASC
    @results = sort {
        $b->created_at <=> $a->created_at
        || $a->id cmp $b->id
    } @results;

    return \@results;
}

sub count {
    my ($self, $filters) = @_;

    my %seen;
    my $total = 0;

    for my $filter (@$filters) {
        my $candidates = $self->_candidates_for($filter);
        for my $event (@$candidates) {
            next if $event->is_expired;
            next if $seen{$event->id};
            next unless $filter->matches($event);
            $seen{$event->id} = 1;
            $total++;
        }
    }

    return $total;
}

sub all_events {
    my ($self) = @_;
    return [@{$self->{_ordered}}];
}

sub clear {
    my ($self) = @_;
    $self->{_by_id}              = {};
    $self->{_by_pubkey_kind}     = {};
    $self->{_by_pubkey_kind_dtag} = {};
    $self->{_by_kind}            = {};
    $self->{_by_pubkey}          = {};
    $self->{_by_tag}             = {};
    $self->{_ordered}            = [];
}

# --- private helpers ---

sub _insert_ordered {
    my ($self, $event) = @_;
    my $ordered = $self->{_ordered};

    # binary search for insertion point
    # sorted: created_at DESC, id ASC
    my ($lo, $hi) = (0, scalar @$ordered);
    while ($lo < $hi) {
        my $mid = int(($lo + $hi) / 2);
        # does $event come before $ordered->[$mid]?
        my $cmp = $event->created_at <=> $ordered->[$mid]->created_at;
        if ($cmp == 0) {
            $cmp = $ordered->[$mid]->id cmp $event->id;
        }
        # cmp > 0: event is newer (or same time, lower id) -- goes before mid
        if ($cmp > 0) {
            $hi = $mid;
        } else {
            $lo = $mid + 1;
        }
    }
    splice @$ordered, $lo, 0, $event;
}

sub _candidates_for {
    my ($self, $filter) = @_;

    # 1. ids -- tightest
    if ($filter->ids) {
        my @events;
        for my $id (@{$filter->ids}) {
            my $e = $self->{_by_id}{$id};
            push @events, $e if $e;
        }
        return $self->_sort_events(\@events);
    }

    # 2. authors + kinds -- intersect
    if ($filter->authors && $filter->kinds) {
        my %by_author;
        for my $pk (@{$filter->authors}) {
            my $idx = $self->{_by_pubkey}{$pk} // {};
            $by_author{$_} = 1 for keys %$idx;
        }
        my @events;
        for my $k (@{$filter->kinds}) {
            my $idx = $self->{_by_kind}{$k} // {};
            for my $id (keys %$idx) {
                push @events, $idx->{$id} if $by_author{$id};
            }
        }
        return $self->_sort_events(\@events);
    }

    # 3. authors only
    if ($filter->authors) {
        my @events;
        for my $pk (@{$filter->authors}) {
            my $idx = $self->{_by_pubkey}{$pk} // {};
            push @events, values %$idx;
        }
        return $self->_sort_events(\@events);
    }

    # 4. kinds only
    if ($filter->kinds) {
        my @events;
        for my $k (@{$filter->kinds}) {
            my $idx = $self->{_by_kind}{$k} // {};
            push @events, values %$idx;
        }
        return $self->_sort_events(\@events);
    }

    # 5. tag filters
    if ($filter->_tag_filters) {
        my @letters = keys %{$filter->_tag_filters};
        if (@letters) {
            my $letter = $letters[0];
            my $values = $filter->_tag_filters->{$letter};
            my @events;
            my %seen;
            for my $val (@$values) {
                my $key = "$letter:$val";
                my $idx = $self->{_by_tag}{$key} // {};
                for my $id (keys %$idx) {
                    next if $seen{$id}++;
                    push @events, $idx->{$id};
                }
            }
            return $self->_sort_events(\@events);
        }
    }

    # 6. fallback -- use pre-sorted ordered list
    return $self->{_ordered};
}

sub _find_best_replaceable {
    my ($self, $pubkey, $kind) = @_;
    my $pk_idx = $self->{_by_pubkey}{$pubkey} // {};
    my $best;
    for my $event (values %$pk_idx) {
        next unless $event->kind == $kind && $event->is_replaceable;
        $best = $event if !$best || _is_newer($event, $best);
    }
    return $best;
}

sub _find_best_addressable {
    my ($self, $pubkey, $kind, $d_tag) = @_;
    my $pk_idx = $self->{_by_pubkey}{$pubkey} // {};
    my $best;
    for my $event (values %$pk_idx) {
        next unless $event->kind == $kind && $event->is_addressable;
        next unless $event->d_tag eq $d_tag;
        $best = $event if !$best || _is_newer($event, $best);
    }
    return $best;
}

sub _is_newer {
    my ($new, $existing) = @_;
    return 1 if $new->created_at > $existing->created_at;
    return 1 if $new->created_at == $existing->created_at
             && $new->id lt $existing->id;
    return 0;
}

sub _sort_events {
    my ($self, $events) = @_;
    return [sort {
        $b->created_at <=> $a->created_at
        || $a->id cmp $b->id
    } @$events];
}

1;

__END__

=head1 NAME

Net::Nostr::RelayStore - Indexed in-memory event storage for Nostr relays

=head1 SYNOPSIS

    use Net::Nostr::RelayStore;

    my $store = Net::Nostr::RelayStore->new(max_events => 10000);

    $store->store($event);                          # returns 1 (new) or 0 (duplicate)
    my $event = $store->get_by_id($id);             # or undef
    my $old   = $store->find_replaceable($pk, $k);  # or undef
    my $addr  = $store->find_addressable($pk, $k, $d);  # or undef
    $store->delete_by_id($id);                      # returns removed event or undef
    $store->delete_matching($pk, \@ids, \@addrs, $ts);  # NIP-09

    my $results = $store->query(\@filters);          # sorted, deduped, limit-aware
    my $count   = $store->count(\@filters);          # deduped count

    my $all = $store->all_events;                    # snapshot copy, sorted
    my $n   = $store->event_count;
    $store->clear;

=head1 DESCRIPTION

Provides indexed in-memory event storage for L<Net::Nostr::Relay>. Events
are indexed by id, pubkey, kind, pubkey+kind (replaceable), pubkey+kind+d_tag
(addressable), and tag values. Queries use the narrowest applicable index
as the candidate set, then post-filter with L<Net::Nostr::Filter/matches>.

This is the default storage backend. Third-party backends (SQLite, LMDB, etc.)
can implement the same method interface and be passed to L<Net::Nostr::Relay>
via the C<store> constructor option.

=head1 CONSTRUCTOR

=head2 new

    my $store = Net::Nostr::RelayStore->new;
    my $store = Net::Nostr::RelayStore->new(max_events => 5000);

Strict constructor. Creates a new empty store. All arguments are optional.
Croaks on unknown arguments or invalid C<max_events> values.

=over

=item max_events

Maximum number of events to retain. When exceeded, the oldest event (by
C<created_at>) is evicted. Must be a positive integer. Defaults to unlimited.

=back

=head1 METHODS

=head2 store

    my $ok = $store->store($event);

Stores an event. Returns 1 on success, 0 if the event is a duplicate (same
id already stored). Updates all indexes. If C<max_events> is set and the
store exceeds capacity after insertion, the oldest event is evicted.

For replaceable events (kind 0, 3, 10000-19999), the C<find_replaceable>
index always points to the newest event by C<created_at>, with lowest C<id>
as tiebreak. Storing an older replaceable event adds it to the store but
does not overwrite the index entry. The same applies to addressable events
(kind 30000-39999) via C<find_addressable>.

    $store->store($event);  # 1
    $store->store($event);  # 0 (duplicate)

=head2 get_by_id

    my $event = $store->get_by_id($event_id);

Returns the event with the given id, or C<undef> if not found.

=head2 find_replaceable

    my $event = $store->find_replaceable($pubkey, $kind);

Returns the newest stored replaceable event for the given pubkey and kind,
or C<undef> if none exists. When the store holds multiple versions (e.g.
an older event not yet cleaned up by the relay), this always returns the
one with the highest C<created_at> (lowest C<id> as tiebreak).
Replaceable kinds are 0, 3, and 10000-19999.

=head2 find_addressable

    my $event = $store->find_addressable($pubkey, $kind, $d_tag);

Returns the newest stored addressable event for the given pubkey, kind,
and d tag, or C<undef> if none exists. When the store holds multiple
versions, this always returns the one with the highest C<created_at>
(lowest C<id> as tiebreak). Addressable kinds are 30000-39999.

=head2 delete_by_id

    my $removed = $store->delete_by_id($event_id);

Removes the event with the given id from all indexes. Returns the removed
event, or C<undef> if not found. If the removed event was the current entry
in the replaceable or addressable index, the next best candidate (by
C<created_at> DESC, C<id> ASC) is promoted. If no candidates remain, the
index entry is cleared.

=head2 delete_matching

    my $count = $store->delete_matching($pubkey, \@ids, \@addresses, $before_ts);

NIP-09 bulk deletion. Deletes events owned by C<$pubkey> by event id or by
coordinate. Addresses may be addressable (C<"kind:pubkey:d_tag">) or
replaceable (C<"kind:pubkey:"> with empty d_tag). Both id-based and
address-based deletions skip events belonging to a different pubkey.
Address-based deletion additionally only removes events with
C<created_at E<lt>= $before_ts>. Kind 5 (deletion) events are never deleted.
Returns the number of events deleted.

    $store->delete_matching($pk, [$event_id], [], 9999);
    $store->delete_matching($pk, [], ["30023:$pk:slug"], $deletion_ts);
    $store->delete_matching($pk, [], ["10000:$pk:"], $deletion_ts);  # replaceable

=head2 query

    my $events = $store->query(\@filters);

Returns an arrayref of events matching any of the given filters (OR across
filters, AND within each filter). Results are sorted by C<created_at> DESC
then C<id> ASC. Expired events (NIP-40) are excluded. Events matching
multiple filters are deduplicated. Each filter's C<limit> is respected
independently. A C<limit> of 0 returns no events for that filter.

    my $results = $store->query([
        Net::Nostr::Filter->new(kinds => [1], limit => 10),
        Net::Nostr::Filter->new(authors => [$pk]),
    ]);

=head2 count

    my $n = $store->count(\@filters);

Like L</query> but returns only the count. Deduplicates across filters
and skips expired events.

=head2 all_events

    my $events = $store->all_events;

Returns a snapshot (array copy) of all stored events, sorted by
C<created_at> DESC then C<id> ASC. Mutating the returned arrayref does
not affect the store. Unlike L</query>, this includes expired events.

=head2 event_count

    my $n = $store->event_count;

Returns the number of events currently stored.

=head2 max_events

    my $max = $store->max_events;  # positive integer or undef

Returns the configured maximum event capacity, or C<undef> if unlimited.

=head2 clear

    $store->clear;

Removes all events and resets all indexes.

=head1 PLUGGABLE BACKENDS

Third-party storage backends should implement the same public method interface:
C<store>, C<get_by_id>, C<find_replaceable>, C<find_addressable>,
C<delete_by_id>, C<delete_matching>, C<query>, C<count>, C<all_events>,
C<event_count>, and C<clear>. No base class or role is required -- the
interface is duck-typed.

=head1 SEE ALSO

L<Net::Nostr::Relay>, L<Net::Nostr::Filter>, L<Net::Nostr::Event>,
L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>

=cut
