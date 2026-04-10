package Net::Nostr::LiveActivity;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    identifier
    title
    summary
    image
    streaming
    recording
    starts
    ends
    status
    current_participants
    total_participants
    hashtags
    participants
    relays
    pinned
    activity
    relay_hint
    reply_to
    room
    service
    endpoint
    space_ref
    hand
);

my %KINDS = (
    30311 => 'live_event',
    1311  => 'chat_message',
    30312 => 'meeting_space',
    30313 => 'meeting_room',
    10312 => 'room_presence',
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{hashtags}     //= [];
    $args{participants} //= [];
    $args{relays}       //= [];
    $args{pinned}       //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub live_event {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "live_event requires 'identifier'";
    my $title                = delete $args{title};
    my $summary              = delete $args{summary};
    my $image                = delete $args{image};
    my $streaming            = delete $args{streaming};
    my $recording            = delete $args{recording};
    my $starts               = delete $args{starts};
    my $ends                 = delete $args{ends};
    my $status               = delete $args{status};
    my $current_participants = delete $args{current_participants};
    my $total_participants   = delete $args{total_participants};
    my $hashtags             = delete $args{hashtags} // [];
    my $participants         = delete $args{participants} // [];
    my $relays               = delete $args{relays};
    my $pinned               = delete $args{pinned} // [];

    my @tags;
    push @tags, ['d', $identifier];
    push @tags, ['title', $title]         if defined $title;
    push @tags, ['summary', $summary]     if defined $summary;
    push @tags, ['image', $image]         if defined $image;
    push @tags, ['streaming', $streaming] if defined $streaming;
    push @tags, ['recording', $recording] if defined $recording;
    push @tags, ['starts', $starts]       if defined $starts;
    push @tags, ['ends', $ends]           if defined $ends;
    push @tags, ['status', $status]       if defined $status;
    push @tags, ['current_participants', $current_participants]
        if defined $current_participants;
    push @tags, ['total_participants', $total_participants]
        if defined $total_participants;
    push @tags, ['t', $_] for @$hashtags;
    push @tags, ['p', @$_] for @$participants;
    push @tags, ['relays', @$relays] if $relays;
    push @tags, ['pinned', $_] for @$pinned;

    return Net::Nostr::Event->new(
        %args,
        kind    => 30311,
        content => '',
        tags    => \@tags,
    );
}

sub chat_message {
    my ($class, %args) = @_;

    my $activity   = delete $args{activity}
        // croak "chat_message requires 'activity'";
    my $relay_hint = delete $args{relay_hint};
    my $reply_to   = delete $args{reply_to};
    my $content    = delete $args{content} // '';

    my @tags;
    if (defined $relay_hint) {
        push @tags, ['a', $activity, $relay_hint, 'root'];
    } else {
        push @tags, ['a', $activity];
    }
    push @tags, ['e', $reply_to] if defined $reply_to;

    return Net::Nostr::Event->new(
        %args,
        kind    => 1311,
        content => $content,
        tags    => \@tags,
    );
}

sub meeting_space {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "meeting_space requires 'identifier'";
    my $room = delete $args{room}
        // croak "meeting_space requires 'room'";
    my $status = delete $args{status}
        // croak "meeting_space requires 'status'";
    my $service = delete $args{service}
        // croak "meeting_space requires 'service'";
    my $participants = delete $args{participants}
        // croak "meeting_space requires 'participants'";
    my $summary  = delete $args{summary};
    my $image    = delete $args{image};
    my $endpoint = delete $args{endpoint};
    my $hashtags = delete $args{hashtags} // [];
    my $relays   = delete $args{relays};

    my @tags;
    push @tags, ['d', $identifier];
    push @tags, ['room', $room];
    push @tags, ['status', $status];
    push @tags, ['service', $service];
    push @tags, ['summary', $summary]   if defined $summary;
    push @tags, ['image', $image]       if defined $image;
    push @tags, ['endpoint', $endpoint] if defined $endpoint;
    push @tags, ['t', $_] for @$hashtags;
    push @tags, ['p', @$_] for @$participants;
    push @tags, ['relays', @$relays] if $relays;

    return Net::Nostr::Event->new(
        %args,
        kind    => 30312,
        content => '',
        tags    => \@tags,
    );
}

sub meeting_room {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "meeting_room requires 'identifier'";
    my $space_ref = delete $args{space_ref}
        // croak "meeting_room requires 'space_ref'";
    my $title = delete $args{title}
        // croak "meeting_room requires 'title'";
    my $starts = delete $args{starts}
        // croak "meeting_room requires 'starts'";
    my $status = delete $args{status}
        // croak "meeting_room requires 'status'";
    my $summary              = delete $args{summary};
    my $image                = delete $args{image};
    my $ends                 = delete $args{ends};
    my $current_participants = delete $args{current_participants};
    my $total_participants   = delete $args{total_participants};
    my $participants         = delete $args{participants} // [];

    my @tags;
    push @tags, ['d', $identifier];
    push @tags, ['a', @$space_ref];
    push @tags, ['title', $title];
    push @tags, ['starts', $starts];
    push @tags, ['status', $status];
    push @tags, ['summary', $summary] if defined $summary;
    push @tags, ['image', $image]     if defined $image;
    push @tags, ['ends', $ends]       if defined $ends;
    push @tags, ['current_participants', $current_participants]
        if defined $current_participants;
    push @tags, ['total_participants', $total_participants]
        if defined $total_participants;
    push @tags, ['p', @$_] for @$participants;

    return Net::Nostr::Event->new(
        %args,
        kind    => 30313,
        content => '',
        tags    => \@tags,
    );
}

sub room_presence {
    my ($class, %args) = @_;

    my $activity   = delete $args{activity}
        // croak "room_presence requires 'activity'";
    my $relay_hint = delete $args{relay_hint};
    my $hand       = delete $args{hand};

    my @tags;
    push @tags, ['a', $activity, $relay_hint // '', 'root'];
    push @tags, ['hand', $hand] if defined $hand;

    return Net::Nostr::Event->new(
        %args,
        kind    => 10312,
        content => '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless exists $KINDS{$kind};

    my %attrs;
    my (@hashtags, @participants, @relays, @pinned);

    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $t = $tag->[0];
        if    ($t eq 'd')                    { $attrs{identifier} = $tag->[1] }
        elsif ($t eq 'title')                { $attrs{title} = $tag->[1] }
        elsif ($t eq 'summary')              { $attrs{summary} = $tag->[1] }
        elsif ($t eq 'image')                { $attrs{image} = $tag->[1] }
        elsif ($t eq 'streaming')            { $attrs{streaming} = $tag->[1] }
        elsif ($t eq 'recording')            { $attrs{recording} = $tag->[1] }
        elsif ($t eq 'starts')               { $attrs{starts} = $tag->[1] }
        elsif ($t eq 'ends')                 { $attrs{ends} = $tag->[1] }
        elsif ($t eq 'status')               { $attrs{status} = $tag->[1] }
        elsif ($t eq 'current_participants') { $attrs{current_participants} = $tag->[1] }
        elsif ($t eq 'total_participants')   { $attrs{total_participants} = $tag->[1] }
        elsif ($t eq 't')                    { push @hashtags, $tag->[1] }
        elsif ($t eq 'p')                    { push @participants, [@{$tag}[1 .. $#$tag]] }
        elsif ($t eq 'relays')               { @relays = @{$tag}[1 .. $#$tag] }
        elsif ($t eq 'pinned')               { push @pinned, $tag->[1] }
        elsif ($t eq 'a') {
            if ($kind == 30313) {
                $attrs{space_ref} = [@{$tag}[1 .. $#$tag]];
            } else {
                $attrs{activity}   = $tag->[1];
                $attrs{relay_hint} = $tag->[2] if @$tag > 2 && defined $tag->[2] && $tag->[2] ne '';
            }
        }
        elsif ($t eq 'e')        { $attrs{reply_to} = $tag->[1] }
        elsif ($t eq 'room')     { $attrs{room} = $tag->[1] }
        elsif ($t eq 'service')  { $attrs{service} = $tag->[1] }
        elsif ($t eq 'endpoint') { $attrs{endpoint} = $tag->[1] }
        elsif ($t eq 'hand')     { $attrs{hand} = $tag->[1] }
    }

    return $class->new(
        %attrs,
        hashtags     => \@hashtags,
        participants => \@participants,
        relays       => \@relays,
        pinned       => \@pinned,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "live activity event MUST be kind 30311, 1311, 30312, 30313, or 10312"
        unless exists $KINDS{$kind};

    my %has;
    for my $tag (@{$event->tags}) {
        $has{$tag->[0]} = 1;
    }

    if ($kind == 30311) {
        croak "live event MUST have a 'd' tag" unless $has{d};
    }

    if ($kind == 1311) {
        croak "chat message MUST have an 'a' tag" unless $has{a};
    }

    if ($kind == 30312) {
        croak "meeting space MUST have a 'd' tag"       unless $has{d};
        croak "meeting space MUST have a 'room' tag"    unless $has{room};
        croak "meeting space MUST have a 'status' tag"  unless $has{status};
        croak "meeting space MUST have a 'service' tag" unless $has{service};
        croak "meeting space MUST have a 'p' tag"       unless $has{p};
    }

    if ($kind == 30313) {
        croak "meeting room MUST have a 'd' tag"      unless $has{d};
        croak "meeting room MUST have an 'a' tag"     unless $has{a};
        croak "meeting room MUST have a 'title' tag"  unless $has{title};
        croak "meeting room MUST have a 'starts' tag" unless $has{starts};
        croak "meeting room MUST have a 'status' tag" unless $has{status};
    }

    if ($kind == 10312) {
        croak "room presence MUST have an 'a' tag" unless $has{a};
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::LiveActivity - NIP-53 Live Activities

=head1 SYNOPSIS

    use Net::Nostr::LiveActivity;

    # Live streaming event (kind 30311)
    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey     => $hex_pubkey,
        identifier => 'my-stream',
        title      => 'My Stream',
        status     => 'live',
    );

    # Live chat message (kind 1311)
    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey   => $hex_pubkey,
        activity => "30311:$author_pk:$d_id",
        content  => 'Hello!',
    );

    # Meeting space (kind 30312)
    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $hex_pubkey,
        identifier   => 'main-room',
        room         => 'Main Conference Hall',
        status       => 'open',
        service      => 'https://meet.example.com/room',
        participants => [[$host_pk, 'wss://relay.com/', 'Host']],
    );

    # Meeting room event (kind 30313)
    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey     => $hex_pubkey,
        identifier => 'annual-meeting',
        space_ref  => ["30312:$space_pk:main-room", 'wss://relay.com'],
        title      => 'Annual Meeting',
        starts     => '1676262123',
        status     => 'planned',
    );

    # Room presence (kind 10312)
    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey   => $hex_pubkey,
        activity => "30312:$space_pk:main-room",
        hand     => '1',
    );

    # Parse any live activity event
    my $parsed = Net::Nostr::LiveActivity->from_event($event);

    # Validate
    Net::Nostr::LiveActivity->validate($event);

=head1 DESCRIPTION

Implements NIP-53 (Live Activities). Five event kinds are used:

=over 4

=item * B<Live Streaming Event> (kind 30311) - An addressable event
advertising a live stream. Contains tags for title, summary, image,
streaming URL, recording URL, start/end times, status, participant
counts, hashtags, participant roles, relay lists, and pinned chat
messages. Updated continuously as participants join and leave.

=item * B<Live Chat Message> (kind 1311) - A regular event for live
chat. MUST include an C<a> tag referencing the parent live activity.
MAY include an C<e> tag for replies.

=item * B<Meeting Space> (kind 30312) - An addressable event defining
a virtual interactive space. MUST have C<room>, C<status>, C<service>,
and at least one C<p> tag with a Host role.

=item * B<Meeting Room Event> (kind 30313) - An addressable event
representing a scheduled or ongoing meeting. MUST reference a parent
space via C<a> tag and have C<title>, C<starts>, and C<status>.

=item * B<Room Presence> (kind 10312) - A replaceable event signaling
a user's presence in a room. Contains an C<a> tag with the room
reference and an optional C<hand> tag for raised hand.

=back

=head1 CONSTRUCTOR

=head2 new

    my $la = Net::Nostr::LiveActivity->new(
        identifier => 'my-stream',
        status     => 'live',
    );

Creates a new C<Net::Nostr::LiveActivity> object. Croaks on unknown
arguments. Array fields (C<hashtags>, C<participants>, C<relays>,
C<pinned>) default to C<[]>.

=head1 CLASS METHODS

=head2 live_event

    my $event = Net::Nostr::LiveActivity->live_event(
        pubkey               => $hex_pubkey,       # required
        identifier           => $id,               # required (d tag)
        title                => $title,            # optional
        summary              => $summary,          # optional
        image                => $url,              # optional
        streaming            => $url,              # optional
        recording            => $url,              # optional
        starts               => $timestamp,        # optional
        ends                 => $timestamp,        # optional
        status               => $status,           # optional (planned/live/ended)
        current_participants => $count,            # optional
        total_participants   => $count,            # optional
        hashtags             => [$tag, ...],       # optional (t tags)
        participants         => [[$pk, $relay, $role, $proof], ...], # optional (p tags)
        relays               => [$url, ...],       # optional (relays tag)
        pinned               => [$event_id, ...],  # optional (pinned tags)
    );

Creates a kind 30311 live streaming L<Net::Nostr::Event>. Each C<p>
tag SHOULD have a displayable role name (e.g. C<Host>, C<Speaker>,
C<Participant>). The relay and proof fields in participant entries are
optional. Content defaults to C<''>.

=head2 chat_message

    my $event = Net::Nostr::LiveActivity->chat_message(
        pubkey     => $hex_pubkey,                 # required
        activity   => "30311:$pk:$d_id",           # required (a tag)
        relay_hint => $relay_url,                  # optional
        reply_to   => $event_id,                   # optional (e tag)
        content    => $message,                    # optional, defaults to ''
    );

Creates a kind 1311 live chat L<Net::Nostr::Event>. The C<a> tag
references the parent live activity. When a relay hint is provided,
the C<a> tag includes a C<root> marker.

=head2 meeting_space

    my $event = Net::Nostr::LiveActivity->meeting_space(
        pubkey       => $hex_pubkey,               # required
        identifier   => $id,                       # required (d tag)
        room         => $name,                     # required (room tag)
        status       => $status,                   # required (open/private/closed)
        service      => $url,                      # required (service tag)
        participants => [[$pk, $relay, $role, $proof], ...], # required (p tags; $proof optional)
        summary      => $summary,                  # optional
        image        => $url,                      # optional
        endpoint     => $url,                      # optional
        hashtags     => [$tag, ...],               # optional (t tags)
        relays       => [$url, ...],               # optional (relays tag)
    );

Creates a kind 30312 meeting space L<Net::Nostr::Event>. MUST have
at least one provider with a Host role. Status MUST be C<open>,
C<private>, or C<closed>. Content defaults to C<''>.

=head2 meeting_room

    my $event = Net::Nostr::LiveActivity->meeting_room(
        pubkey               => $hex_pubkey,       # required
        identifier           => $id,               # required (d tag)
        space_ref            => [$coord, $relay],   # required (a tag)
        title                => $title,            # required
        starts               => $timestamp,        # required
        status               => $status,           # required (planned/live/ended)
        summary              => $summary,          # optional
        image                => $url,              # optional
        ends                 => $timestamp,        # optional
        current_participants => $count,            # optional
        total_participants   => $count,            # optional
        participants         => [[$pk, $relay, $role], ...], # optional
    );

Creates a kind 30313 meeting room L<Net::Nostr::Event>. The C<a> tag
references the parent meeting space. Content defaults to C<''>.

=head2 room_presence

    my $event = Net::Nostr::LiveActivity->room_presence(
        pubkey     => $hex_pubkey,                 # required
        activity   => $room_a_tag,                 # required (a tag)
        relay_hint => $relay_url,                  # optional
        hand       => '1',                         # optional (hand raised)
    );

Creates a kind 10312 room presence L<Net::Nostr::Event>. This is a
replaceable event, so presence can only be indicated in one room at a
time. The C<a> tag always includes a C<root> marker. When no relay
hint is provided, the relay field defaults to C<''>.

=head2 from_event

    my $la = Net::Nostr::LiveActivity->from_event($event);

Parses a kind 30311, 1311, 30312, 30313, or 10312 event into a
C<Net::Nostr::LiveActivity> object. Returns C<undef> for unrecognized
kinds.

=head2 validate

    Net::Nostr::LiveActivity->validate($event);

Validates a NIP-53 event. Croaks if:

=over

=item * Kind is not 30311, 1311, 30312, 30313, or 10312

=item * Kind 30311 missing C<d> tag

=item * Kind 1311 missing C<a> tag

=item * Kind 30312 missing C<d>, C<room>, C<status>, C<service>, or C<p> tag

=item * Kind 30313 missing C<d>, C<a>, C<title>, C<starts>, or C<status> tag

=item * Kind 10312 missing C<a> tag

=back

Returns 1 on success.

=head1 ACCESSORS

=head2 identifier

The C<d> tag value (kinds 30311, 30312, 30313).

=head2 title

Event title (kinds 30311, 30313).

=head2 summary

Event description.

=head2 image

Preview image URL.

=head2 streaming

Live stream URL (kind 30311).

=head2 recording

Recording URL (kind 30311).

=head2 starts

Start timestamp in seconds.

=head2 ends

End timestamp in seconds.

=head2 status

Event status. For live events: C<planned>, C<live>, or C<ended>. For
meeting spaces: C<open>, C<private>, or C<closed>.

=head2 current_participants

Current participant count string.

=head2 total_participants

Total participant count string.

=head2 hashtags

Arrayref of hashtag strings from C<t> tags. Defaults to C<[]>.

=head2 participants

Arrayref of arrayrefs from C<p> tags. Each contains
C<[$pubkey, $relay, $role]> and optionally a proof field.
Defaults to C<[]>.

=head2 relays

Arrayref of relay URL strings from C<relays> tag. Defaults to C<[]>.

=head2 pinned

Arrayref of pinned event IDs from C<pinned> tags. Defaults to C<[]>.

=head2 activity

The C<a> tag coordinate (kinds 1311, 10312).

=head2 relay_hint

Relay hint from C<a> tag.

=head2 reply_to

Parent event ID from C<e> tag (kind 1311).

=head2 room

Room display name from C<room> tag (kind 30312).

=head2 service

Service URL from C<service> tag (kind 30312).

=head2 endpoint

API endpoint URL from C<endpoint> tag (kind 30312).

=head2 space_ref

Arrayref C<[$coord, $relay]> from C<a> tag referencing parent space
(kind 30313).

=head2 hand

Hand raised flag from C<hand> tag (kind 10312).

=head1 SEE ALSO

L<NIP-53|https://github.com/nostr-protocol/nips/blob/master/53.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
