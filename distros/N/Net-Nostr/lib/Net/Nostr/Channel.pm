package Net::Nostr::Channel;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

my $JSON = JSON->new->utf8;
my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub create {
    my ($class, %args) = @_;
    my $pubkey = $args{pubkey} // croak "create requires 'pubkey'";
    my $name   = $args{name}   // croak "create requires 'name'";

    my %meta = (name => $name);
    $meta{about}   = $args{about}   if defined $args{about};
    $meta{picture} = $args{picture} if defined $args{picture};
    $meta{relays}  = $args{relays}  if defined $args{relays};

    # Clients MAY add additional metadata fields
    if ($args{metadata}) {
        %meta = (%meta, %{$args{metadata}});
    }

    delete @args{qw(name about picture relays metadata)};
    return Net::Nostr::Event->new(%args, kind => 40, content => $JSON->encode(\%meta), tags => []);
}

sub set_metadata {
    my ($class, %args) = @_;
    my $pubkey     = $args{pubkey}     // croak "set_metadata requires 'pubkey'";
    my $channel_id = $args{channel_id} // croak "set_metadata requires 'channel_id'";
    croak "channel_id must be 64-char lowercase hex" unless defined $channel_id && $channel_id =~ $HEX64;

    my $relay_url  = $args{relay_url}  // '';
    my $categories = $args{categories};

    my %meta;
    $meta{name}    = $args{name}    if defined $args{name};
    $meta{about}   = $args{about}   if defined $args{about};
    $meta{picture} = $args{picture} if defined $args{picture};
    $meta{relays}  = $args{relays}  if defined $args{relays};

    # Clients MAY add additional metadata fields
    if ($args{metadata}) {
        %meta = (%meta, %{$args{metadata}});
    }

    my @tags;
    push @tags, ['e', $channel_id, $relay_url, 'root'];
    if ($categories) {
        push @tags, ['t', $_] for @$categories;
    }

    delete @args{qw(channel_id relay_url name about picture relays categories metadata)};
    return Net::Nostr::Event->new(%args, kind => 41, content => $JSON->encode(\%meta), tags => \@tags);
}

sub message {
    my ($class, %args) = @_;
    my $pubkey     = $args{pubkey}     // croak "message requires 'pubkey'";
    my $channel_id = $args{channel_id} // croak "message requires 'channel_id'";
    croak "channel_id must be 64-char lowercase hex" unless defined $channel_id && $channel_id =~ $HEX64;
    my $content    = $args{content}    // croak "message requires 'content'";

    my $relay_url = $args{relay_url} // '';

    my @tags;
    push @tags, ['e', $channel_id, $relay_url, 'root'];

    delete @args{qw(channel_id relay_url)};
    return Net::Nostr::Event->new(%args, kind => 42, tags => \@tags);
}

sub reply {
    my ($class, %args) = @_;
    my $pubkey     = $args{pubkey}     // croak "reply requires 'pubkey'";
    my $channel_id = $args{channel_id} // croak "reply requires 'channel_id'";
    croak "channel_id must be 64-char lowercase hex" unless defined $channel_id && $channel_id =~ $HEX64;
    my $to         = $args{to}         // croak "reply requires 'to'";
    my $content    = $args{content}    // croak "reply requires 'content'";

    my $relay_url = $args{relay_url} // '';

    my @tags;
    push @tags, ['e', $channel_id, $relay_url, 'root'];
    push @tags, ['e', $to->id, $relay_url, 'reply'];

    # Add p tag for parent author unless replying to self
    if ($to->pubkey ne $pubkey) {
        push @tags, ['p', $to->pubkey, $relay_url];
    }

    delete @args{qw(channel_id relay_url to)};
    return Net::Nostr::Event->new(%args, kind => 42, tags => \@tags);
}

sub hide_message {
    my ($class, %args) = @_;
    my $pubkey     = $args{pubkey}     // croak "hide_message requires 'pubkey'";
    my $message_id = $args{message_id} // croak "hide_message requires 'message_id'";
    croak "message_id must be 64-char lowercase hex" unless defined $message_id && $message_id =~ $HEX64;

    my $content = '';
    if (defined $args{reason}) {
        $content = $JSON->encode({ reason => $args{reason} });
    }

    my @tags = (['e', $message_id]);

    delete @args{qw(message_id reason)};
    return Net::Nostr::Event->new(%args, kind => 43, content => $content, tags => \@tags);
}

sub mute_user {
    my ($class, %args) = @_;
    my $pubkey      = $args{pubkey}      // croak "mute_user requires 'pubkey'";
    my $user_pubkey = $args{user_pubkey} // croak "mute_user requires 'user_pubkey'";
    croak "user_pubkey must be 64-char lowercase hex" unless defined $user_pubkey && $user_pubkey =~ $HEX64;

    my $content = '';
    if (defined $args{reason}) {
        $content = $JSON->encode({ reason => $args{reason} });
    }

    my @tags = (['p', $user_pubkey]);

    delete @args{qw(user_pubkey reason)};
    return Net::Nostr::Event->new(%args, kind => 44, content => $content, tags => \@tags);
}

sub metadata_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 40 or 41" unless $event->kind == 40 || $event->kind == 41;
    return $JSON->decode($event->content);
}

sub channel_id {
    my ($class, $event) = @_;
    for my $tag (@{$event->tags}) {
        return $tag->[1] if $tag->[0] eq 'e' && defined $tag->[3] && $tag->[3] eq 'root';
    }
    return undef;
}

sub hide_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 43" unless $event->kind == 43;

    my $message_id;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'e') {
            $message_id = $tag->[1];
            last;
        }
    }

    my $reason;
    if (defined $event->content && length($event->content) > 0) {
        my $parsed = $JSON->decode($event->content);
        $reason = $parsed->{reason};
    }

    return { message_id => $message_id, reason => $reason };
}

sub mute_from_event {
    my ($class, $event) = @_;
    croak "event must be kind 44" unless $event->kind == 44;

    my $pubkey;
    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'p') {
            $pubkey = $tag->[1];
            last;
        }
    }

    my $reason;
    if (defined $event->content && length($event->content) > 0) {
        my $parsed = $JSON->decode($event->content);
        $reason = $parsed->{reason};
    }

    return { pubkey => $pubkey, reason => $reason };
}

1;

__END__

=head1 NAME

Net::Nostr::Channel - NIP-28 public chat channels

=head1 SYNOPSIS

    use Net::Nostr::Channel;
    use Net::Nostr::Key;

    my $key = Net::Nostr::Key->new;

    # Create a channel (kind 40)
    my $event = Net::Nostr::Channel->create(
        pubkey  => $key->pubkey_hex,
        name    => 'Perl Nostr',
        about   => 'Discussion about Perl and Nostr',
        picture => 'https://example.com/perl.png',
        relays  => ['wss://relay.example.com/'],
    );
    $key->sign_event($event);
    $client->publish($event);
    my $channel_id = $event->id;

    # Update channel metadata (kind 41)
    my $update = Net::Nostr::Channel->set_metadata(
        pubkey     => $key->pubkey_hex,
        channel_id => $channel_id,
        name       => 'Perl Nostr Chat',
        relay_url  => 'wss://relay.example.com/',
        categories => ['perl', 'nostr'],
    );

    # Send a message (kind 42)
    my $msg = Net::Nostr::Channel->message(
        pubkey     => $key->pubkey_hex,
        channel_id => $channel_id,
        content    => 'Hello, channel!',
        relay_url  => 'wss://relay.example.com/',
    );

    # Reply to a message (kind 42)
    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $key->pubkey_hex,
        channel_id => $channel_id,
        to         => $msg,
        content    => 'Welcome!',
    );

    # Hide a message (kind 43, client-side moderation)
    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $key->pubkey_hex,
        message_id => $msg->id,
        reason     => 'spam',
    );

    # Mute a user (kind 44, client-side moderation)
    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $key->pubkey_hex,
        user_pubkey => $spammer_pk,
        reason      => 'spammer',
    );

    # Parse channel metadata from a received event
    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    say $meta->{name};     # 'Perl Nostr'
    say $meta->{about};    # 'Discussion about Perl and Nostr'
    say $meta->{picture};  # 'https://example.com/perl.png'

    # Get channel ID from a message or metadata update
    my $ch_id = Net::Nostr::Channel->channel_id($msg_event);

    # Parse hide/mute info from received events
    my $hide_info = Net::Nostr::Channel->hide_from_event($hide_event);
    say $hide_info->{message_id};
    say $hide_info->{reason};  # or undef

    my $mute_info = Net::Nostr::Channel->mute_from_event($mute_event);
    say $mute_info->{pubkey};
    say $mute_info->{reason};  # or undef

=head1 DESCRIPTION

Implements NIP-28 public chat channels. Channels are created with kind 40
events, metadata is updated with kind 41, and messages are sent as kind 42.
Client-side moderation is provided via kind 43 (hide message) and kind 44
(mute user).

All moderation is client-centric: clients decide what content to show or
hide, with no additional requirements on relays.

=head1 CLASS METHODS

=head2 create

    my $event = Net::Nostr::Channel->create(
        pubkey   => $hex_pubkey,
        name     => 'Channel Name',
        about    => 'Description',       # optional
        picture  => 'https://pic.url',   # optional
        relays   => ['wss://relay.com'], # optional
        metadata => { rules => '...' },  # optional, extra metadata fields
    );

Creates a kind 40 channel creation event. The C<content> field is JSON
containing the channel metadata. C<name> is required. C<metadata> is
an optional hashref of additional metadata fields to include in the
JSON content. Extra arguments are passed through to
L<Net::Nostr::Event/new>.

The event ID of the returned event becomes the channel identifier used
by all other methods.

    my $event = Net::Nostr::Channel->create(
        pubkey => $key->pubkey_hex,
        name   => 'My Channel',
    );
    my $channel_id = $event->id;

=head2 set_metadata

    my $event = Net::Nostr::Channel->set_metadata(
        pubkey     => $hex_pubkey,
        channel_id => $channel_id,
        name       => 'New Name',         # optional
        about      => 'New description',  # optional
        picture    => 'https://new.pic',  # optional
        relays     => ['wss://r.com'],    # optional
        relay_url  => 'wss://relay.com/', # optional, defaults to ''
        categories => ['topic1'],         # optional, added as t tags
        metadata   => { rules => '...' }, # optional, extra metadata fields
    );

Creates a kind 41 channel metadata update event. C<channel_id> is
required. The C<e> tag uses NIP-10 marked C<root> format. C<metadata>
is an optional hashref of additional metadata fields. Only the most
recent kind 41 per channel should be used.

Clients should ignore kind 41 events from pubkeys other than the
channel creator.

    my $update = Net::Nostr::Channel->set_metadata(
        pubkey     => $key->pubkey_hex,
        channel_id => $channel_id,
        name       => 'Updated Name',
        categories => ['nostr', 'perl'],
    );
    # tags: [['e', $channel_id, '', 'root'], ['t', 'nostr'], ['t', 'perl']]

=head2 message

    my $event = Net::Nostr::Channel->message(
        pubkey     => $hex_pubkey,
        channel_id => $channel_id,
        content    => 'Hello!',
        relay_url  => 'wss://relay.com/',  # optional, defaults to ''
    );

Creates a kind 42 root channel message. The C<e> tag points to the
channel creation event with NIP-10 C<root> marker.

    my $msg = Net::Nostr::Channel->message(
        pubkey     => $key->pubkey_hex,
        channel_id => $channel_id,
        content    => 'First message!',
    );
    # tags: [['e', $channel_id, '', 'root']]

=head2 reply

    my $event = Net::Nostr::Channel->reply(
        pubkey     => $hex_pubkey,
        channel_id => $channel_id,
        to         => $parent_event,
        content    => 'Reply text',
        relay_url  => 'wss://relay.com/',  # optional, defaults to ''
    );

Creates a kind 42 reply to a channel message. Has two C<e> tags: one
with C<root> marker pointing to the channel, and one with C<reply>
marker pointing to the parent message. A C<p> tag for the parent
author is appended unless replying to self.

    my $reply = Net::Nostr::Channel->reply(
        pubkey     => $key->pubkey_hex,
        channel_id => $channel_id,
        to         => $msg,
        content    => 'I agree!',
    );
    # tags: [['e', $channel_id, '', 'root'],
    #        ['e', $msg->id, '', 'reply'],
    #        ['p', $msg->pubkey, '']]

=head2 hide_message

    my $event = Net::Nostr::Channel->hide_message(
        pubkey     => $hex_pubkey,
        message_id => $msg_event_id,
        reason     => 'spam',  # optional
    );

Creates a kind 43 event indicating the user no longer wants to see the
specified message. C<reason> is optional; when provided, the C<content>
is JSON C<{"reason":"..."}>.

Clients should hide kind 42 events if there is a matching kind 43 from
the user. Clients may also hide for other users based on multiple hide
events.

    my $hide = Net::Nostr::Channel->hide_message(
        pubkey     => $key->pubkey_hex,
        message_id => $msg->id,
        reason     => 'off-topic',
    );

=head2 mute_user

    my $event = Net::Nostr::Channel->mute_user(
        pubkey      => $hex_pubkey,
        user_pubkey => $target_pubkey,
        reason      => 'spammer',  # optional
    );

Creates a kind 44 event indicating the user no longer wants to see
messages from the specified user. C<reason> is optional; when provided,
the C<content> is JSON C<{"reason":"..."}>.

Clients should hide kind 42 events from the muted pubkey if there is
a matching kind 44 from the user.

    my $mute = Net::Nostr::Channel->mute_user(
        pubkey      => $key->pubkey_hex,
        user_pubkey => $spammer,
        reason      => 'posting spam',
    );

=head2 metadata_from_event

    my $meta = Net::Nostr::Channel->metadata_from_event($event);
    # { name => '...', about => '...', picture => '...', relays => [...] }

Parses channel metadata from a kind 40 or kind 41 event. Returns a
hashref decoded from the event's JSON content. Fields not present in
the content will not be in the hashref. Croaks if the event is not
kind 40 or 41.

    my $meta = Net::Nostr::Channel->metadata_from_event($channel_event);
    say $meta->{name};

=head2 channel_id

    my $id = Net::Nostr::Channel->channel_id($event);  # or undef

Extracts the channel ID (the kind 40 event ID) from a kind 41 or kind 42
event by finding the C<e> tag with C<root> marker. Returns C<undef> if
no root C<e> tag is found.

    my $ch_id = Net::Nostr::Channel->channel_id($msg_event);
    # the event ID of the kind 40 channel creation event

=head2 hide_from_event

    my $info = Net::Nostr::Channel->hide_from_event($event);
    # { message_id => '...', reason => '...' or undef }

Parses a kind 43 event. Returns a hashref with C<message_id> (from the
C<e> tag) and C<reason> (from the JSON content, or C<undef>). Croaks
if the event is not kind 43.

    my $info = Net::Nostr::Channel->hide_from_event($hide_event);
    say "Hidden: $info->{message_id}";
    say "Reason: $info->{reason}" if $info->{reason};

=head2 mute_from_event

    my $info = Net::Nostr::Channel->mute_from_event($event);
    # { pubkey => '...', reason => '...' or undef }

Parses a kind 44 event. Returns a hashref with C<pubkey> (from the
C<p> tag) and C<reason> (from the JSON content, or C<undef>). Croaks
if the event is not kind 44.

    my $info = Net::Nostr::Channel->mute_from_event($mute_event);
    say "Muted: $info->{pubkey}";
    say "Reason: $info->{reason}" if $info->{reason};

=head1 SEE ALSO

L<NIP-28|https://github.com/nostr-protocol/nips/blob/master/28.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Thread>

=cut
