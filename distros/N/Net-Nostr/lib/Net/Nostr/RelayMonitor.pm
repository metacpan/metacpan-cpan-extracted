package Net::Nostr::RelayMonitor;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    relay_url
    network
    relay_type
    nips
    requirements
    topics
    kinds
    geohash
    languages
    rtt_open
    rtt_read
    rtt_write
    nip11
    frequency
    timeouts
    checks
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{nips}         //= [];
    $args{requirements} //= [];
    $args{topics}       //= [];
    $args{kinds}        //= [];
    $args{languages}    //= [];
    $args{timeouts}     //= [];
    $args{checks}       //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub discovery_event {
    my ($class, %args) = @_;

    my $relay_url = delete $args{relay_url}
        // croak "discovery_event requires 'relay_url'";
    my $nip11 = delete $args{nip11};

    my @tags;
    push @tags, ['d', $relay_url];

    # Single-value optional tags
    for my $pair (
        [network    => 'n'],
        [relay_type => 'T'],
        [geohash    => 'g'],
        [rtt_open   => 'rtt-open'],
        [rtt_read   => 'rtt-read'],
        [rtt_write  => 'rtt-write'],
    ) {
        my ($key, $tag_name) = @$pair;
        my $val = delete $args{$key};
        push @tags, [$tag_name, $val] if defined $val;
    }

    # Repeated tags
    for my $pair (
        [nips         => 'N'],
        [requirements => 'R'],
        [topics       => 't'],
        [kinds        => 'k'],
    ) {
        my ($key, $tag_name) = @$pair;
        my $vals = delete $args{$key};
        next unless $vals;
        for my $v (@$vals) {
            push @tags, [$tag_name, "$v"];
        }
    }

    # Language tags with ISO-639-1 namespace
    my $langs = delete $args{languages};
    if ($langs) {
        for my $lang (@$langs) {
            push @tags, ['l', $lang, 'ISO-639-1'];
        }
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 30166,
        content => $nip11 // '',
        tags    => \@tags,
    );
}

sub announcement_event {
    my ($class, %args) = @_;

    my $frequency = delete $args{frequency}
        // croak "announcement_event requires 'frequency'";

    my @tags;

    # Timeout tags
    my $timeouts = delete $args{timeouts};
    if ($timeouts) {
        for my $t (@$timeouts) {
            if (defined $t->{test}) {
                push @tags, ['timeout', $t->{test}, $t->{ms}];
            } else {
                push @tags, ['timeout', $t->{ms}];
            }
        }
    }

    push @tags, ['frequency', "$frequency"];

    # Checks (repeated c tags)
    my $checks = delete $args{checks};
    if ($checks) {
        for my $c (@$checks) {
            push @tags, ['c', $c];
        }
    }

    # Geohash
    my $geohash = delete $args{geohash};
    push @tags, ['g', $geohash] if defined $geohash;

    return Net::Nostr::Event->new(
        %args,
        kind    => 10166,
        content => '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 30166) {
        return $class->_from_discovery($event);
    } elsif ($kind == 10166) {
        return $class->_from_announcement($event);
    }
    return undef;
}

sub _from_discovery {
    my ($class, $event) = @_;

    my %attrs;
    my (@nips, @reqs, @topics, @kinds, @langs);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if    ($name eq 'd')        { $attrs{relay_url}  = $tag->[1] }
        elsif ($name eq 'n')        { $attrs{network}    = $tag->[1] }
        elsif ($name eq 'T')        { $attrs{relay_type} = $tag->[1] }
        elsif ($name eq 'g')        { $attrs{geohash}    = $tag->[1] }
        elsif ($name eq 'rtt-open') { $attrs{rtt_open}   = $tag->[1] }
        elsif ($name eq 'rtt-read') { $attrs{rtt_read}   = $tag->[1] }
        elsif ($name eq 'rtt-write'){ $attrs{rtt_write}  = $tag->[1] }
        elsif ($name eq 'N')        { push @nips, $tag->[1] }
        elsif ($name eq 'R')        { push @reqs, $tag->[1] }
        elsif ($name eq 't')        { push @topics, $tag->[1] }
        elsif ($name eq 'k')        { push @kinds, $tag->[1] }
        elsif ($name eq 'l')        { push @langs, $tag->[1] }
    }

    my $content = $event->content;
    $attrs{nip11} = $content if defined $content && length $content;

    return $class->new(
        %attrs,
        nips         => \@nips,
        requirements => \@reqs,
        topics       => \@topics,
        kinds        => \@kinds,
        languages    => \@langs,
    );
}

sub _from_announcement {
    my ($class, $event) = @_;

    my %attrs;
    my (@timeouts, @checks);

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'frequency') {
            $attrs{frequency} = $tag->[1];
        } elsif ($name eq 'timeout') {
            if (defined $tag->[2]) {
                push @timeouts, { test => $tag->[1], ms => $tag->[2] };
            } else {
                push @timeouts, { ms => $tag->[1] };
            }
        } elsif ($name eq 'c') {
            push @checks, $tag->[1];
        } elsif ($name eq 'g') {
            $attrs{geohash} = $tag->[1];
        }
    }

    return $class->new(
        %attrs,
        timeouts => \@timeouts,
        checks   => \@checks,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 30166) {
        my $has_d;
        for my $tag (@{$event->tags}) {
            $has_d = 1 if $tag->[0] eq 'd';
        }
        croak "discovery event MUST have a 'd' tag set to the relay URL"
            unless $has_d;
        return 1;
    }

    if ($kind == 10166) {
        my $has_freq;
        for my $tag (@{$event->tags}) {
            $has_freq = 1 if $tag->[0] eq 'frequency';
        }
        croak "announcement event MUST have a 'frequency' tag"
            unless $has_freq;
        return 1;
    }

    croak "event kind must be 30166 (discovery) or 10166 (announcement)";
}

1;

__END__


=head1 NAME

Net::Nostr::RelayMonitor - NIP-66 Relay Discovery and Liveness Monitoring

=head1 SYNOPSIS

    use Net::Nostr::RelayMonitor;

    # Build a relay discovery event (kind 30166)
    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $pubkey,
        relay_url    => 'wss://relay.example.com/',
        network      => 'clearnet',
        nips         => [1, 11, 42],
        rtt_open     => '150',
        requirements => ['!payment', 'auth'],
    );

    # Build a monitor announcement event (kind 10166)
    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $pubkey,
        frequency => '3600',
        checks    => [qw(ws nip11 ssl dns)],
        timeouts  => [{ test => 'open', ms => '5000' }],
    );

    # Parse either kind
    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    say $mon->relay_url;    # discovery events
    say $mon->frequency;    # announcement events

    # Validate
    Net::Nostr::RelayMonitor->validate($event);

=head1 DESCRIPTION

Implements NIP-66 (Relay Discovery and Liveness Monitoring). Provides
methods to build and parse two event types:

=over 4

=item B<Kind 30166> -- Relay Discovery Events

Addressable events published by monitors documenting relay characteristics
inferred from NIP-11 documents or probing. The C<d> tag MUST be set to the
relay's normalized URL (or a hex pubkey for non-URL relays). The C<content>
MAY include the stringified JSON of the relay's NIP-11 document.

=item B<Kind 10166> -- Relay Monitor Announcements

Replaceable events advertising a monitor's intent to publish discovery
events at a regular frequency.

=back

Clients MUST NOT require C<30166> events to function. Clients SHOULD NOT
trust a single monitor source.

=head1 CONSTRUCTOR

=head2 new

    my $mon = Net::Nostr::RelayMonitor->new(%fields);

Creates a new C<Net::Nostr::RelayMonitor> object. All fields are optional.
Array fields (C<nips>, C<requirements>, C<topics>, C<kinds>, C<languages>,
C<timeouts>, C<checks>) default to C<[]>. Croaks on unknown arguments.
Typically returned by L</from_event>.

=head1 CLASS METHODS

=head2 discovery_event

    my $event = Net::Nostr::RelayMonitor->discovery_event(
        pubkey       => $hex_pubkey,
        relay_url    => 'wss://relay.example.com/',
        network      => 'clearnet',
        relay_type   => 'PrivateInbox',
        nips         => [1, 11, 42],
        requirements => ['!payment', 'auth'],
        topics       => ['nsfw'],
        kinds        => ['1', '!20000'],
        geohash      => 'ww8p1r4t8',
        languages    => ['en'],
        rtt_open     => '234',
        rtt_read     => '150',
        rtt_write    => '300',
        nip11        => '{"name":"My Relay"}',
        created_at   => time(),
    );

Creates a kind 30166 addressable L<Net::Nostr::Event>. C<relay_url> is
required and becomes the C<d> tag. C<nip11>, if provided, becomes the
event C<content> (otherwise empty string). Multi-value tags (C<nips>,
C<requirements>, C<topics>, C<kinds>, C<languages>) are emitted as
repeated tags per the spec. Any remaining arguments are passed through
to L<Net::Nostr::Event/new>.

=head2 announcement_event

    my $event = Net::Nostr::RelayMonitor->announcement_event(
        pubkey    => $hex_pubkey,
        frequency => '3600',
        timeouts  => [
            { test => 'open', ms => '5000' },
            { test => 'read', ms => '3000' },
            { ms => '10000' },                  # applies to all tests
        ],
        checks    => [qw(ws nip11 ssl dns geo)],
        geohash   => 'ww8p1r4t8',
        created_at => time(),
    );

Creates a kind 10166 replaceable L<Net::Nostr::Event>. C<frequency> is
required (seconds between publications). C<timeouts> is an arrayref of
hashrefs with C<ms> (milliseconds) and optional C<test> (test type).
When C<test> is omitted, the timeout applies to all tests. C<checks> is
an arrayref of lowercase check names. Any remaining arguments are passed
through to L<Net::Nostr::Event/new>.

=head2 from_event

    my $mon = Net::Nostr::RelayMonitor->from_event($event);

Parses a kind 30166 or 10166 event into a C<Net::Nostr::RelayMonitor>
object. Returns C<undef> if the event kind is neither 30166 nor 10166.

    my $mon = Net::Nostr::RelayMonitor->from_event($event);
    if ($event->kind == 30166) {
        say $mon->relay_url;
        say $mon->network;
    } else {
        say $mon->frequency;
        say join ', ', @{$mon->checks};
    }

=head2 validate

    Net::Nostr::RelayMonitor->validate($event);

Validates a NIP-66 event. For kind 30166, checks that a C<d> tag is
present. For kind 10166, checks that a C<frequency> tag is present.
Croaks if the kind is unsupported or required tags are missing.
Returns 1 on success.

    eval { Net::Nostr::RelayMonitor->validate($event) };
    warn "Invalid: $@" if $@;

=head1 ACCESSORS

=head2 Discovery Event Fields (kind 30166)

=head3 relay_url

Relay URL from the C<d> tag. For non-URL relays, may be a hex pubkey.

=head3 network

Network type. SHOULD be one of C<clearnet>, C<tor>, C<i2p>, C<loki>.

=head3 relay_type

Relay type in PascalCase (e.g. C<PrivateInbox>).

=head3 nips

Arrayref of supported NIP numbers (as strings).

=head3 requirements

Arrayref of requirement strings. False values use C<!> prefix
(e.g. C<!payment>). Corresponds to NIP-11 C<limitations>.

=head3 topics

Arrayref of topic strings.

=head3 kinds

Arrayref of accepted/unaccepted kind strings. Unaccepted kinds use
C<!> prefix (e.g. C<!20000>).

=head3 geohash

NIP-52 geohash string. Used by both discovery and announcement events.

=head3 languages

Arrayref of ISO-639-1 language codes.

=head3 rtt_open

Open round-trip time in milliseconds (string).

=head3 rtt_read

Read round-trip time in milliseconds (string).

=head3 rtt_write

Write round-trip time in milliseconds (string).

=head3 nip11

Stringified JSON of the relay's NIP-11 informational document, or C<undef>.

=head2 Announcement Event Fields (kind 10166)

=head3 frequency

Publication frequency in seconds (string).

=head3 timeouts

Arrayref of timeout hashrefs. Each has C<ms> (milliseconds) and optional
C<test> (test type). When C<test> is absent, the timeout applies to all
tests.

    # With test type
    { test => 'open', ms => '5000' }

    # Without test type (applies to all)
    { ms => '5000' }

=head3 checks

Arrayref of lowercase check name strings (e.g. C<ws>, C<nip11>, C<ssl>,
C<dns>, C<geo>).

=head1 SEE ALSO

L<NIP-66|https://github.com/nostr-protocol/nips/blob/master/66.md>,
L<Net::Nostr::RelayInfo>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
