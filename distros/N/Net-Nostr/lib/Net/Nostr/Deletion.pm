package Net::Nostr::Deletion;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

use Class::Tiny qw(reason _events _addresses _kinds);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    $self->_events($self->_events // []);
    $self->_addresses($self->_addresses // []);
    $self->_kinds($self->_kinds // {});
    $self->reason($self->reason // '');
    return $self;
}

sub add_event {
    my ($self, $event_id, %opts) = @_;
    croak "event_id must be 64-char lowercase hex" unless $event_id =~ $HEX64;
    my $kind = $opts{kind} // croak "add_event requires 'kind'";
    push @{$self->_events}, $event_id;
    $self->_kinds->{$kind} = 1;
    return $self;
}

sub add_address {
    my ($self, $address, %opts) = @_;
    my $kind = $opts{kind} // croak "add_address requires 'kind'";
    push @{$self->_addresses}, $address;
    $self->_kinds->{$kind} = 1;
    return $self;
}

sub event_ids { [@{$_[0]->_events}] }

sub addresses { [@{$_[0]->_addresses}] }

sub to_event {
    my ($self, %args) = @_;
    my @tags;
    for my $id (@{$self->_events}) {
        push @tags, ['e', $id];
    }
    for my $addr (@{$self->_addresses}) {
        push @tags, ['a', $addr];
    }
    for my $kind (sort { $a <=> $b } keys %{$self->_kinds}) {
        push @tags, ['k', "$kind"];
    }
    return Net::Nostr::Event->new(
        %args,
        kind    => 5,
        content => $self->reason,
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    croak "event must be kind 5" unless $event->kind == 5;

    my $self = $class->new(reason => $event->content);
    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2 && defined $tag->[1];
        if ($tag->[0] eq 'e') {
            push @{$self->_events}, $tag->[1];
        } elsif ($tag->[0] eq 'a') {
            push @{$self->_addresses}, $tag->[1];
        } elsif ($tag->[0] eq 'k') {
            $self->_kinds->{$tag->[1]} = 1;
        }
    }
    return $self;
}

sub applies_to {
    my ($self, $target_event, $deletion_pubkey) = @_;
    return 0 unless $target_event->pubkey eq $deletion_pubkey;

    # Check e tags
    for my $id (@{$self->_events}) {
        return 1 if $target_event->id eq $id;
    }

    # Check a tags for addressable events (kind:pubkey:d_tag)
    if ($target_event->is_addressable) {
        my $target_addr = $target_event->kind . ':' . $target_event->pubkey . ':' . $target_event->d_tag;
        for my $addr (@{$self->_addresses}) {
            return 1 if $addr eq $target_addr;
        }
    }

    # Check a tags for replaceable events (kind:pubkey:)
    if ($target_event->is_replaceable) {
        my $target_addr = $target_event->kind . ':' . $target_event->pubkey . ':';
        for my $addr (@{$self->_addresses}) {
            return 1 if $addr eq $target_addr;
        }
    }

    return 0;
}

1;

__END__

=head1 NAME

Net::Nostr::Deletion - NIP-09 event deletion requests

=head1 SYNOPSIS

    use Net::Nostr::Deletion;

    # Create a deletion request
    my $del = Net::Nostr::Deletion->new(reason => 'posted by accident');
    $del->add_event($event_id, kind => 1);
    $del->add_event($other_id, kind => 1);
    $del->add_address("30023:$pubkey:my-article", kind => 30023);
    $del->add_address("10000:$pubkey:", kind => 10000);  # replaceable

    my $event = $del->to_event(pubkey => $my_pubkey);
    $key->sign_event($event);
    $client->publish($event);

    # Parse a received deletion request
    my $del = Net::Nostr::Deletion->from_event($event);
    say $del->reason;
    say join ', ', @{$del->event_ids};

    # Check if a deletion applies to a specific event
    if ($del->applies_to($target_event, $deletion_event->pubkey)) {
        # hide or delete the target event
    }

=head1 DESCRIPTION

Implements NIP-09 event deletion requests. A deletion request is a kind 5
event containing C<e> and/or C<a> tags referencing events to be deleted,
and C<k> tags indicating the kinds of those events.

Deletion requests are just requests - relays and clients SHOULD honor them
but there is no guarantee that events will be deleted from all relays.

=head1 CONSTRUCTOR

=head2 new

    my $del = Net::Nostr::Deletion->new;
    my $del = Net::Nostr::Deletion->new(reason => 'posted by accident');

Creates an empty deletion request. C<reason> is optional and becomes the
event's C<content> field. Croaks on unknown arguments.

=head2 from_event

    my $del = Net::Nostr::Deletion->from_event($event);

Parses a kind 5 event into a Deletion object. Tags with fewer than
two elements are silently skipped. Croaks if the event is not kind 5.

    my $del = Net::Nostr::Deletion->from_event($event);
    for my $id (@{$del->event_ids}) {
        say "delete: $id";
    }

=head1 METHODS

=head2 add_event

    $del->add_event($event_id, kind => 1);

Adds an event ID to the deletion request. C<kind> is required and will
be included as a C<k> tag. Returns C<$self> for chaining.

    $del->add_event($id1, kind => 1)
        ->add_event($id2, kind => 1);

=head2 add_address

    $del->add_address("30023:$pubkey:my-article", kind => 30023);
    $del->add_address("10000:$pubkey:", kind => 10000);  # replaceable

Adds an event coordinate (C<a> tag) to the deletion request. The coordinate
may be addressable (C<kind:pubkey:d_tag>) or replaceable (C<kind:pubkey:>
with empty d_tag). C<kind> is required. Returns C<$self> for chaining.

=head2 event_ids

    my $ids = $del->event_ids;  # arrayref

Returns the list of event IDs referenced by C<e> tags.

=head2 addresses

    my $addrs = $del->addresses;  # arrayref

Returns the list of event coordinates referenced by C<a> tags (both
addressable and replaceable).

=head2 reason

    my $reason = $del->reason;

Returns the deletion reason (the event's C<content>), or empty string.

=head2 to_event

    my $event = $del->to_event(pubkey => $pubkey_hex);
    my $event = $del->to_event(pubkey => $pubkey_hex, created_at => time());

Creates a kind 5 L<Net::Nostr::Event> from the deletion request. Extra
arguments are passed through to the Event constructor.

    my $event = $del->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);

=head2 applies_to

    my $bool = $del->applies_to($target_event, $deletion_pubkey);

Returns true if this deletion request applies to the given event.
Checks that:

=over 4

=item * The target event's pubkey matches the deletion request's pubkey

=item * The target event's ID is referenced by an C<e> tag, or its
addressable coordinate (C<kind:pubkey:d_tag>) or replaceable coordinate
(C<kind:pubkey:>) is referenced by an C<a> tag

=back

    if ($del->applies_to($event, $del_event->pubkey)) {
        # event should be hidden/deleted
    }

=head1 SEE ALSO

L<NIP-09|https://github.com/nostr-protocol/nips/blob/master/09.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
