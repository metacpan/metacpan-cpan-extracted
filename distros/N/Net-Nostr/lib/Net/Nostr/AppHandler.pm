package Net::Nostr::AppHandler;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    event_kind
    identifier
    kinds
    content
    apps
    platforms
);

# Known platform tag names
my %PLATFORM_TAGS = map { $_ => 1 } qw(web ios android);

sub new {
    my $class = shift;
    my %args = @_;
    $args{apps}      //= [];
    $args{kinds}     //= [];
    $args{platforms} //= [];
    $args{content}   //= '';
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub recommendation {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "recommendation requires 'pubkey'";
    my $event_kind = $args{event_kind} // croak "recommendation requires 'event_kind'";

    my @tags;
    push @tags, ['d', "$event_kind"];

    for my $app (@{$args{apps} // []}) {
        my @a_tag = ('a', $app->{coordinate});
        push @a_tag, $app->{relay} if defined $app->{relay};
        push @a_tag, $app->{platform} if defined $app->{platform};
        push @tags, \@a_tag;
    }

    return Net::Nostr::Event->new(
        kind    => 31989,
        pubkey  => $pubkey,
        content => '',
        tags    => \@tags,
    );
}

sub handler {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "handler requires 'pubkey'";
    my $identifier = $args{identifier} // croak "handler requires 'identifier'";
    my $kinds      = $args{kinds}      // croak "handler requires 'kinds'";

    my @tags;
    push @tags, ['d', $identifier];

    for my $k (@$kinds) {
        push @tags, ['k', "$k"];
    }

    for my $p (@{$args{platforms} // []}) {
        my @p_tag = ($p->{platform}, $p->{url});
        push @p_tag, $p->{entity} if defined $p->{entity};
        push @tags, \@p_tag;
    }

    return Net::Nostr::Event->new(
        kind    => 31990,
        pubkey  => $pubkey,
        content => $args{content} // '',
        tags    => \@tags,
    );
}

sub client_tag {
    my ($class, %args) = @_;
    croak "client_tag requires 'name'" unless defined $args{name};
    croak "client_tag requires 'coordinate'" unless defined $args{coordinate};
    my @tag = ('client', $args{name}, $args{coordinate});
    push @tag, $args{relay} if defined $args{relay};
    return \@tag;
}

sub from_event {
    my ($class, $event) = @_;

    if ($event->kind == 31989) {
        return $class->_parse_recommendation($event);
    } elsif ($event->kind == 31990) {
        return $class->_parse_handler($event);
    }

    return undef;
}

sub _parse_recommendation {
    my ($class, $event) = @_;

    my $event_kind;
    my @apps;

    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $name = $tag->[0];
        if ($name eq 'd') {
            $event_kind = $tag->[1] // '';
        } elsif ($name eq 'a') {
            my %app = (coordinate => $tag->[1]);
            $app{relay}    = $tag->[2] if @$tag > 2 && defined $tag->[2];
            $app{platform} = $tag->[3] if @$tag > 3 && defined $tag->[3];
            push @apps, \%app;
        }
    }

    return $class->new(
        event_kind => $event_kind,
        apps       => \@apps,
    );
}

sub _parse_handler {
    my ($class, $event) = @_;

    my ($identifier, @kinds, @platforms);

    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $name = $tag->[0];
        if ($name eq 'd') {
            $identifier = $tag->[1] // '';
        } elsif ($name eq 'k') {
            push @kinds, $tag->[1];
        } elsif ($PLATFORM_TAGS{$name}) {
            my %p = (platform => $name, url => $tag->[1]);
            $p{entity} = $tag->[2] if @$tag > 2 && defined $tag->[2];
            push @platforms, \%p;
        }
    }

    return $class->new(
        identifier => $identifier,
        kinds      => \@kinds,
        content    => $event->content,
        platforms  => \@platforms,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "app handler MUST be kind 31989 or 31990"
        unless $event->kind == 31989 || $event->kind == 31990;

    my $has_d = grep { $_->[0] eq 'd' } @{$event->tags};
    croak "app handler MUST include a d tag" unless $has_d;

    if ($event->kind == 31990) {
        my $has_k = grep { $_->[0] eq 'k' } @{$event->tags};
        croak "handler (kind 31990) MUST include at least one k tag" unless $has_k;
    }

    return 1;
}

sub recommendation_filter {
    my ($class, %args) = @_;
    return {
        kinds   => [31989],
        '#d'    => ["$args{event_kind}"],
        authors => $args{authors},
    };
}

sub handler_filter {
    my ($class, %args) = @_;
    return {
        kinds   => [31990],
        '#k'    => ["$args{event_kind}"],
        authors => $args{authors},
    };
}

1;

__END__

=head1 NAME

Net::Nostr::AppHandler - NIP-89 recommended application handlers

=head1 SYNOPSIS

    use Net::Nostr::AppHandler;

    my $pubkey = 'aa' x 32;
    my $app_pk = 'bb' x 32;

    # Recommend an app for handling kind 31337 events
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $pubkey,
        event_kind => '31337',
        apps       => [
            {
                coordinate => "31990:$app_pk:zapstr",
                relay      => 'wss://relay.example.com',
                platform   => 'web',
            },
        ],
    );

    # Publish handler information for an app
    my $handler = Net::Nostr::AppHandler->handler(
        pubkey     => $app_pk,
        identifier => 'zapstr',
        kinds      => ['31337'],
        content    => '{"name":"Zapstr","picture":"https://example.com/icon.png"}',
        platforms  => [
            { platform => 'web', url => 'https://zapstr.live/a/<bech32>', entity => 'nevent' },
            { platform => 'web', url => 'https://zapstr.live/p/<bech32>', entity => 'nprofile' },
            { platform => 'ios', url => 'com.zapstr:///<bech32>' },
        ],
    );

    # Add a client tag to any event (MAY)
    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',
        coordinate => "31990:$app_pk:my-client",
        relay      => 'wss://relay1',
    );

    # Parse a recommendation or handler event
    my $info = Net::Nostr::AppHandler->from_event($event);
    say $info->event_kind;  # '31337'

    # Query filters for discovery
    my $filter = Net::Nostr::AppHandler->recommendation_filter(
        event_kind => '31337',
        authors    => [$pubkey],
    );

=head1 DESCRIPTION

Implements NIP-89 recommended application handlers. This NIP provides a way
to discover applications that can handle unknown event kinds through two
event types:

=over 4

=item B<Recommendations> (kind 31989)

Addressable events where a user recommends one or more applications for
handling a specific event kind. The C<d> tag contains the supported event
kind, and C<a> tags reference handler information events.

=item B<Handler information> (kind 31990)

Addressable events published by applications describing how to redirect
users. Contains C<k> tags for supported event kinds and platform-specific
URL templates with C<E<lt>bech32E<gt>> placeholders that clients replace
with NIP-19-encoded entities.

=back

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::AppHandler->new(%fields);

Creates a new C<Net::Nostr::AppHandler> object. Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::AppHandler->new(
        event_kind => '31337',
        apps       => [],
        kinds      => [1, 30023],
    );

Accepted fields: C<event_kind>, C<identifier>, C<kinds> (defaults to C<[]>),
C<content> (defaults to C<''>), C<apps> (defaults to C<[]>),
C<platforms> (defaults to C<[]>). Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 recommendation

    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $hex_pubkey,           # required
        event_kind => '31337',               # required (d tag value)
        apps       => [                      # optional
            {
                coordinate => '31990:pubkey:id',  # required
                relay      => 'wss://...',        # optional (SHOULD)
                platform   => 'web',              # optional (SHOULD)
            },
        ],
    );

Creates a kind 31989 recommendation L<Net::Nostr::Event>. C<pubkey> and
C<event_kind> are required. Each app in the C<apps> arrayref becomes an
C<a> tag. The C<relay> and C<platform> fields are optional but SHOULD be
included per spec.

=head2 handler

    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $hex_pubkey,           # required
        identifier => 'my-app',             # required (d tag)
        kinds      => ['31337', '30023'],   # required (k tags)
        content    => '{"name":"App"}',     # optional (kind:0-style JSON)
        platforms  => [                     # optional
            { platform => 'web', url => 'https://app.com/<bech32>', entity => 'nevent' },
            { platform => 'ios', url => 'com.app:///<bech32>' },
        ],
    );

Creates a kind 31990 handler information L<Net::Nostr::Event>. C<pubkey>,
C<identifier>, and C<kinds> are required.

The C<content> field is an optional stringified JSON object with kind:0-style
metadata. If empty, clients should use the pubkey's kind:0 profile instead.

Each entry in C<platforms> becomes a platform tag. The C<entity> field is
an optional NIP-19 entity type (e.g. C<nevent>, C<nprofile>). A platform
tag without an entity type is a generic handler for any NIP-19 entity.

=head2 client_tag

    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',                # required
        coordinate => '31990:pubkey:identifier',  # required
        relay      => 'wss://relay.com',          # optional
    );

Creates a C<client> tag arrayref suitable for inclusion in any event's tags.
C<name> and C<coordinate> are required; croaks if either is missing.
Clients MAY include this tag to identify themselves. This has privacy
implications, so clients SHOULD allow users to opt out.

    my $event = Net::Nostr::Event->new(
        kind    => 1,
        pubkey  => $pubkey,
        content => 'Hello!',
        tags    => [$tag],
    );

=head2 from_event

    my $info = Net::Nostr::AppHandler->from_event($event);

Parses a kind 31989 or 31990 L<Net::Nostr::Event>. Returns a
C<Net::Nostr::AppHandler> object with accessors, or C<undef> if the
event is not a handler kind.

For kind 31989 (recommendation), the returned object has C<event_kind>
and C<apps> accessors.

For kind 31990 (handler), the returned object has C<identifier>, C<kinds>,
C<content>, and C<platforms> accessors.

=head2 validate

    Net::Nostr::AppHandler->validate($event);

Validates that an event is a well-formed NIP-89 event. Croaks if:

=over

=item * Kind is not 31989 or 31990

=item * Missing C<d> tag

=item * Kind 31990 missing C<k> tag

=back

=head2 recommendation_filter

    my $filter = Net::Nostr::AppHandler->recommendation_filter(
        event_kind => '31337',
        authors    => [$user_pk, @follows],
    );

Returns a hashref suitable for use as a Nostr filter to query for
recommendations for a given event kind.

=head2 handler_filter

    my $filter = Net::Nostr::AppHandler->handler_filter(
        event_kind => '31337',
        authors    => [$app_pk],
    );

Returns a hashref suitable for use as a Nostr filter to query for
handler information for a given event kind.

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 event_kind

    my $kind = $info->event_kind;  # '31337'

The event kind being recommended (from the C<d> tag of kind 31989).

=head2 apps

    my $apps = $info->apps;
    # [{ coordinate => '31990:pk:id', relay => 'wss://...', platform => 'web' }]

Arrayref of hashrefs describing recommended apps (from C<a> tags of kind
31989). Each hashref has a C<coordinate> key, and optional C<relay> and
C<platform> keys.

=head2 identifier

    my $id = $info->identifier;

The C<d> tag value identifying the handler (kind 31990).

=head2 kinds

    my $kinds = $info->kinds;  # ['31337', '30023']

Arrayref of supported event kind strings (from C<k> tags of kind 31990).

=head2 content

    my $json = $info->content;  # '{"name":"Zapstr"}' or ''

The handler's metadata content (kind:0-style JSON string), or empty string.

=head2 platforms

    my $platforms = $info->platforms;
    # [{ platform => 'web', url => 'https://.../<bech32>', entity => 'nevent' }]

Arrayref of hashrefs describing platform handlers (kind 31990). Each
hashref has C<platform> and C<url> keys. The C<entity> key is optional
and specifies the NIP-19 entity type the URL handles.

=head1 SEE ALSO

L<NIP-89|https://github.com/nostr-protocol/nips/blob/master/89.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
