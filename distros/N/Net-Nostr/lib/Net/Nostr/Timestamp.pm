package Net::Nostr::Timestamp;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(pubkey event_id kind ots_data relay_url);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub to_event {
    my ($self, %args) = @_;

    my $pubkey   = $self->pubkey   // croak "pubkey is required";
    my $event_id = $self->event_id // croak "event_id is required";
    my $kind     = $self->kind     // croak "kind is required";
    my $ots_data = $self->ots_data // croak "ots_data is required";

    croak "event_id must be 64-char lowercase hex" unless $event_id =~ $HEX64;

    my @e_tag = ('e', $event_id);
    push @e_tag, $self->relay_url if defined $self->relay_url;

    my @tags = (
        \@e_tag,
        ['k', "$kind"],
    );

    return Net::Nostr::Event->new(
        %args,
        pubkey  => $pubkey,
        kind    => 1040,
        content => $ots_data,
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    croak "event must be kind 1040" unless $event->kind == 1040;

    my ($event_id, $relay_url, $kind);

    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        if ($tag->[0] eq 'e') {
            $event_id = $tag->[1];
            $relay_url = $tag->[2] if @$tag > 2 && defined $tag->[2];
        } elsif ($tag->[0] eq 'k') {
            $kind = 0 + $tag->[1];
        }
    }

    return $class->new(
        pubkey    => $event->pubkey,
        event_id  => $event_id,
        kind      => $kind,
        ots_data  => $event->content,
        (defined $relay_url ? (relay_url => $relay_url) : ()),
    );
}

1;

__END__

=head1 NAME

Net::Nostr::Timestamp - NIP-03 OpenTimestamps attestations for events

=head1 SYNOPSIS

    use Net::Nostr::Timestamp;

    # Create a timestamp attestation
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $my_pubkey,
        event_id  => $target_event_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => 'wss://relay.example.com',    # optional
    );
    my $event = $ts->to_event;
    $key->sign_event($event);
    $client->publish($event);

    # Parse a received timestamp attestation
    my $ts2 = Net::Nostr::Timestamp->from_event($event);
    say $ts2->event_id;   # target event ID
    say $ts2->kind;        # target event kind
    say $ts2->ots_data;    # base64-encoded OTS proof

=head1 DESCRIPTION

Implements NIP-03 OpenTimestamps attestations. A timestamp attestation is a
kind 1040 event containing an L<OpenTimestamps|https://opentimestamps.org/>
proof for another event.

The C<content> field contains the full base64-encoded C<.ots> file data. The
proof MUST prove the referenced event ID as its digest. The C<.ots> file
SHOULD contain a single Bitcoin attestation and no pending attestations.

=head1 CONSTRUCTOR

=head2 new

    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $pubkey_hex,
        event_id  => $target_event_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => 'wss://relay.example.com',  # optional
    );

Creates a new timestamp attestation. C<pubkey>, C<event_id>, C<kind>, and
C<ots_data> are required. C<relay_url> is optional and will be included in
the C<e> tag if provided. Croaks on unknown arguments.

=head2 from_event

    my $ts = Net::Nostr::Timestamp->from_event($event);

Parses a kind 1040 event into a Timestamp object. Croaks if the event is
not kind 1040.

    my $ts = Net::Nostr::Timestamp->from_event($event);
    say $ts->event_id;
    say $ts->ots_data;

=head1 METHODS

=head2 to_event

    my $event = $ts->to_event;
    my $event = $ts->to_event(created_at => time());

Creates a kind 1040 L<Net::Nostr::Event> from the timestamp attestation.
Extra arguments are passed through to the Event constructor.

=head2 event_id

    my $id = $ts->event_id;

Returns the target event ID referenced by the C<e> tag.

=head2 kind

    my $kind = $ts->kind;

Returns the target event kind from the C<k> tag.

=head2 ots_data

    my $data = $ts->ots_data;

Returns the base64-encoded OpenTimestamps proof data.

=head2 pubkey

    my $pk = $ts->pubkey;

Returns the pubkey of the attestation author.

=head2 relay_url

    my $url = $ts->relay_url;

Returns the relay URL from the C<e> tag, or C<undef> if none was provided.

=head1 SEE ALSO

L<NIP-03|https://github.com/nostr-protocol/nips/blob/master/03.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
