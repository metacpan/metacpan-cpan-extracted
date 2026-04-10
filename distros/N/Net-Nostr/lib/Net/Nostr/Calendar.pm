package Net::Nostr::Calendar;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    identifier
    title
    description
    start
    end
    summary
    image
    locations
    geohash
    participants
    hashtags
    references
    calendars
    calendar_events
    start_tzid
    end_tzid
    days
    event_coord
    event_id
    status
    fb
    event_author
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{locations}       //= [];
    $args{participants}    //= [];
    $args{hashtags}        //= [];
    $args{references}      //= [];
    $args{calendars}       //= [];
    $args{calendar_events} //= [];
    $args{days}            //= [];
    $args{description}     //= '';
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

# Shared tag builder for common calendar event tags

sub _build_common_tags {
    my ($class, $args) = @_;

    my @tags;

    my $identifier = delete $args->{identifier}
        // croak "requires 'identifier'";
    my $title = delete $args->{title}
        // croak "requires 'title'";

    push @tags, ['d', $identifier];
    push @tags, ['title', $title];

    if (defined(my $v = delete $args->{summary})) {
        push @tags, ['summary', $v];
    }
    if (defined(my $v = delete $args->{image})) {
        push @tags, ['image', $v];
    }
    if (my $locs = delete $args->{locations}) {
        push @tags, ['location', $_] for @$locs;
    }
    if (defined(my $v = delete $args->{geohash})) {
        push @tags, ['g', $v];
    }
    if (my $parts = delete $args->{participants}) {
        push @tags, ['p', @$_] for @$parts;
    }
    if (my $tags_list = delete $args->{hashtags}) {
        push @tags, ['t', $_] for @$tags_list;
    }
    if (my $refs = delete $args->{references}) {
        push @tags, ['r', $_] for @$refs;
    }
    if (my $cals = delete $args->{calendars}) {
        push @tags, ['a', $_] for @$cals;
    }

    return @tags;
}

sub date_event {
    my ($class, %args) = @_;

    my $start = delete $args{start}
        // croak "date_event requires 'start'";
    my $content = delete $args{content} // '';

    my @tags = $class->_build_common_tags(\%args);

    push @tags, ['start', $start];
    if (defined(my $end = delete $args{end})) {
        push @tags, ['end', $end];
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 31922,
        content => $content,
        tags    => \@tags,
    );
}

sub time_event {
    my ($class, %args) = @_;

    my $start = delete $args{start}
        // croak "time_event requires 'start'";
    my $content = delete $args{content} // '';

    my @tags = $class->_build_common_tags(\%args);

    push @tags, ['start', "$start"];
    if (defined(my $end = delete $args{end})) {
        push @tags, ['end', "$end"];
    }
    if (my $days = delete $args{days}) {
        push @tags, ['D', "$_"] for @$days;
    }
    if (defined(my $v = delete $args{start_tzid})) {
        push @tags, ['start_tzid', $v];
    }
    if (defined(my $v = delete $args{end_tzid})) {
        push @tags, ['end_tzid', $v];
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 31923,
        content => $content,
        tags    => \@tags,
    );
}

sub calendar {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "calendar requires 'identifier'";
    my $title = delete $args{title}
        // croak "calendar requires 'title'";
    my $content = delete $args{content} // '';
    my $events = delete $args{events} // [];

    my @tags;
    push @tags, ['d', $identifier];
    push @tags, ['title', $title];

    for my $evt (@$events) {
        push @tags, ['a', @$evt];
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 31924,
        content => $content,
        tags    => \@tags,
    );
}

sub rsvp {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "rsvp requires 'identifier'";
    my $event_coord = delete $args{event_coord}
        // croak "rsvp requires 'event_coord'";
    my $status = delete $args{status}
        // croak "rsvp requires 'status'";
    my $content = delete $args{content} // '';

    my $event_relay      = delete $args{event_relay};
    my $event_id         = delete $args{event_id};
    my $event_id_relay   = delete $args{event_id_relay};
    my $fb               = delete $args{fb};
    my $event_author     = delete $args{event_author};
    my $event_author_relay = delete $args{event_author_relay};

    my @tags;

    # e tag before a tag (per spec example order)
    if (defined $event_id) {
        my @e = ('e', $event_id);
        push @e, $event_id_relay if defined $event_id_relay;
        push @tags, \@e;
    }

    # a tag
    my @a = ('a', $event_coord);
    push @a, $event_relay if defined $event_relay;
    push @tags, \@a;

    push @tags, ['d', $identifier];
    push @tags, ['status', $status];

    # fb MUST be omitted if status is declined
    if (defined $fb && $status ne 'declined') {
        push @tags, ['fb', $fb];
    }

    if (defined $event_author) {
        my @p = ('p', $event_author);
        push @p, $event_author_relay if defined $event_author_relay;
        push @tags, \@p;
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 31925,
        content => $content,
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless $kind == 31922 || $kind == 31923
                     || $kind == 31924 || $kind == 31925;

    if ($kind == 31924) {
        return $class->_parse_calendar($event);
    }
    if ($kind == 31925) {
        return $class->_parse_rsvp($event);
    }

    return $class->_parse_calendar_event($event);
}

sub _parse_calendar_event {
    my ($class, $event) = @_;

    my (%attrs, @locations, @participants, @hashtags, @references, @calendars, @days);
    my ($name_tag);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'd')          { $attrs{identifier} = $tag->[1] }
        elsif ($t eq 'title')      { $attrs{title} = $tag->[1] }
        elsif ($t eq 'name')       { $name_tag = $tag->[1] }
        elsif ($t eq 'start')      { $attrs{start} = $tag->[1] }
        elsif ($t eq 'end')        { $attrs{end} = $tag->[1] }
        elsif ($t eq 'summary')    { $attrs{summary} = $tag->[1] }
        elsif ($t eq 'image')      { $attrs{image} = $tag->[1] }
        elsif ($t eq 'location')   { push @locations, $tag->[1] }
        elsif ($t eq 'g')          { $attrs{geohash} = $tag->[1] }
        elsif ($t eq 'p')          { push @participants, [@{$tag}[1 .. $#$tag]] }
        elsif ($t eq 't')          { push @hashtags, $tag->[1] }
        elsif ($t eq 'r')          { push @references, $tag->[1] }
        elsif ($t eq 'a')          { push @calendars, $tag->[1] }
        elsif ($t eq 'start_tzid') { $attrs{start_tzid} = $tag->[1] }
        elsif ($t eq 'end_tzid')   { $attrs{end_tzid} = $tag->[1] }
        elsif ($t eq 'D')          { push @days, $tag->[1] }
    }

    # Deprecated: name mapped to title
    $attrs{title} //= $name_tag;

    return $class->new(
        %attrs,
        description  => $event->content,
        locations    => \@locations,
        participants => \@participants,
        hashtags     => \@hashtags,
        references   => \@references,
        calendars    => \@calendars,
        days         => \@days,
    );
}

sub _parse_calendar {
    my ($class, $event) = @_;

    my ($identifier, $title, @cal_events);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'd')     { $identifier = $tag->[1] }
        elsif ($t eq 'title') { $title = $tag->[1] }
        elsif ($t eq 'a')     { push @cal_events, [@{$tag}[1 .. $#$tag]] }
    }

    return $class->new(
        identifier      => $identifier,
        title           => $title,
        description     => $event->content,
        calendar_events => \@cal_events,
    );
}

sub _parse_rsvp {
    my ($class, $event) = @_;

    my %attrs;

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'd')      { $attrs{identifier} = $tag->[1] }
        elsif ($t eq 'a')      { $attrs{event_coord} = $tag->[1] }
        elsif ($t eq 'e')      { $attrs{event_id} = $tag->[1] }
        elsif ($t eq 'status') { $attrs{status} = $tag->[1] }
        elsif ($t eq 'fb')     { $attrs{fb} = $tag->[1] }
        elsif ($t eq 'p')      { $attrs{event_author} = $tag->[1] }
    }

    return $class->new(
        %attrs,
        description => $event->content,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "calendar event MUST be kind 31922, 31923, 31924, or 31925"
        unless $kind == 31922 || $kind == 31923
            || $kind == 31924 || $kind == 31925;

    my %has;
    for my $tag (@{$event->tags}) {
        $has{$tag->[0]} = $tag->[1];
    }

    if ($kind == 31922 || $kind == 31923) {
        croak "calendar event MUST have a 'd' tag"     unless exists $has{d};
        croak "calendar event MUST have a 'title' tag"  unless exists $has{title};
        croak "calendar event MUST have a 'start' tag"  unless exists $has{start};

        if (exists $has{end}) {
            croak "start MUST be less than end"
                if $has{start} ge $has{end};
        }
    }

    if ($kind == 31923) {
        croak "time-based calendar event MUST have a 'D' tag" unless exists $has{D};
    }

    if ($kind == 31924) {
        croak "calendar MUST have a 'd' tag"     unless exists $has{d};
        croak "calendar MUST have a 'title' tag"  unless exists $has{title};
    }

    if ($kind == 31925) {
        croak "RSVP MUST have a 'd' tag"      unless exists $has{d};
        croak "RSVP MUST have an 'a' tag"      unless exists $has{a};
        croak "RSVP MUST have a 'status' tag"  unless exists $has{status};
        croak "RSVP status MUST be accepted, declined, or tentative"
            unless $has{status} =~ /\A(?:accepted|declined|tentative)\z/;
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::Calendar - NIP-52 Calendar Events

=head1 SYNOPSIS

    use Net::Nostr::Calendar;

    # Date-based calendar event (kind 31922)
    my $event = Net::Nostr::Calendar->date_event(
        pubkey       => $hex_pubkey,
        identifier   => 'vacation-2024',
        title        => 'Summer Vacation',
        content      => 'Two weeks off',
        start        => '2024-07-01',
        end          => '2024-07-15',
        locations    => ['Beach Resort'],
        participants => [[$friend_pk, 'wss://relay', 'attendee']],
    );

    # Time-based calendar event (kind 31923)
    my $event = Net::Nostr::Calendar->time_event(
        pubkey     => $hex_pubkey,
        identifier => 'standup',
        title      => 'Daily Standup',
        start      => 1700000000,
        end        => 1700003600,
        start_tzid => 'America/New_York',
        days       => [19675],
    );

    # Calendar (kind 31924)
    my $cal = Net::Nostr::Calendar->calendar(
        pubkey     => $hex_pubkey,
        identifier => 'personal',
        title      => 'Personal Calendar',
        events     => [
            ["31922:$pk:vacation-2024", 'wss://relay'],
        ],
    );

    # RSVP (kind 31925)
    my $rsvp = Net::Nostr::Calendar->rsvp(
        pubkey       => $hex_pubkey,
        identifier   => 'rsvp-1',
        event_coord  => "31922:$organizer_pk:vacation-2024",
        status       => 'accepted',
        fb           => 'busy',
    );

    # Parse any calendar event
    my $parsed = Net::Nostr::Calendar->from_event($event);

    # Validate
    Net::Nostr::Calendar->validate($event);

=head1 DESCRIPTION

Implements NIP-52 (Calendar Events). Four addressable event kinds are
used:

=over 4

=item * B<Date-Based Calendar Event> (kind 31922) - All-day or multi-day
events where time and time zone hold no significance.

=item * B<Time-Based Calendar Event> (kind 31923) - Events spanning
between a start time and end time.

=item * B<Calendar> (kind 31924) - A collection of calendar events.

=item * B<Calendar Event RSVP> (kind 31925) - Attendance response to a
calendar event.

=back

All four kinds are addressable and deletable per NIP-09.

=head2 Common tags for calendar events

Both date-based and time-based calendar events share these tags:

=over 4

=item * C<d> (required) - unique identifier

=item * C<title> (required) - title of the event

=item * C<summary> (optional) - brief description

=item * C<image> (optional) - URL of an image

=item * C<location> (optional, repeated) - location string

=item * C<g> (optional) - geohash for searchable location

=item * C<p> (optional, repeated) - participant pubkey, relay URL, and role

=item * C<t> (optional, repeated) - hashtag

=item * C<r> (optional, repeated) - reference URL

=item * C<a> (repeated) - reference to kind 31924 calendar

=back

The deprecated C<name> tag is mapped to C<title> when parsing if
C<title> is not present.

=head1 CONSTRUCTOR

=head2 new

    my $cal = Net::Nostr::Calendar->new(
        identifier => 'meeting',
        title      => 'Team Meeting',
    );

Creates a new C<Net::Nostr::Calendar> object. Croaks on unknown
arguments. Array fields default to C<[]>. C<description> defaults to
C<''>.

=head1 CLASS METHODS

=head2 date_event

    my $event = Net::Nostr::Calendar->date_event(
        pubkey       => $hex_pubkey,          # required
        identifier   => $id,                  # required (d tag)
        title        => $title,               # required (title tag)
        start        => 'YYYY-MM-DD',         # required
        end          => 'YYYY-MM-DD',         # optional
        content      => $description,         # optional, defaults to ''
        summary      => $text,                # optional
        image        => $url,                 # optional
        locations    => [$location],           # optional
        geohash      => $geohash,             # optional
        participants => [[$pk, $relay, $role]], # optional
        hashtags     => [$tag],               # optional
        references   => [$url],               # optional
        calendars    => [$coord],             # optional (a tags)
        created_at   => time(),               # optional
    );

Creates a kind 31922 date-based calendar L<Net::Nostr::Event>. The
C<start> date is inclusive and in ISO 8601 format (YYYY-MM-DD). The
C<end> date is exclusive. If C<end> is omitted, the event ends on the
same date as C<start>. C<start> must be less than C<end> if both are
present (enforced by L</validate>).

=head2 time_event

    my $event = Net::Nostr::Calendar->time_event(
        pubkey       => $hex_pubkey,          # required
        identifier   => $id,                  # required (d tag)
        title        => $title,               # required (title tag)
        start        => $unix_timestamp,      # required
        end          => $unix_timestamp,      # optional
        start_tzid   => 'America/New_York',   # optional (IANA TZ)
        end_tzid     => 'America/New_York',   # optional (IANA TZ)
        days         => [$day_number],        # required per spec (D tags)
        content      => $description,         # optional, defaults to ''
        summary      => $text,                # optional
        image        => $url,                 # optional
        locations    => [$location],           # optional
        geohash      => $geohash,             # optional
        participants => [[$pk, $relay, $role]], # optional
        hashtags     => [$tag],               # optional
        references   => [$url],               # optional
        calendars    => [$coord],             # optional (a tags)
        created_at   => time(),               # optional
    );

Creates a kind 31923 time-based calendar L<Net::Nostr::Event>. The
C<start> timestamp is inclusive (Unix seconds). The C<end> timestamp is
exclusive. If C<end> is omitted, the event ends instantaneously.
C<start> must be less than C<end> if both are present (enforced by
L</validate>). C<days> are day-granularity timestamps (C<D> tags)
calculated as C<floor(unix_seconds / 86400)>. The spec requires at
least one C<D> tag (enforced by L</validate>).

=head2 calendar

    my $event = Net::Nostr::Calendar->calendar(
        pubkey     => $hex_pubkey,            # required
        identifier => $id,                    # required (d tag)
        title      => $title,                 # required (title tag)
        content    => $description,           # optional, defaults to ''
        events     => [[$coord, $relay]],     # optional (a tags)
    );

Creates a kind 31924 calendar L<Net::Nostr::Event>. C<events> is an
arrayref of arrayrefs, each containing a calendar event coordinate and
optional relay URL.

=head2 rsvp

    my $event = Net::Nostr::Calendar->rsvp(
        pubkey             => $hex_pubkey,    # required
        identifier         => $id,            # required (d tag)
        event_coord        => $coord,         # required (a tag)
        status             => 'accepted',     # required
        event_relay        => $url,           # optional (a tag relay)
        event_id           => $eid,           # optional (e tag)
        event_id_relay     => $url,           # optional (e tag relay)
        fb                 => 'busy',         # optional (free/busy)
        event_author       => $pk,            # optional (p tag)
        event_author_relay => $url,           # optional (p tag relay)
        content            => $note,          # optional, defaults to ''
    );

Creates a kind 31925 RSVP L<Net::Nostr::Event>. C<status> must be
C<accepted>, C<declined>, or C<tentative>. The C<fb> tag is
automatically omitted when C<status> is C<declined>.

=head2 from_event

    my $cal = Net::Nostr::Calendar->from_event($event);

Parses a kind 31922, 31923, 31924, or 31925 event into a
C<Net::Nostr::Calendar> object. Returns C<undef> for unrecognized kinds.
Handles the deprecated C<name> tag (mapped to C<title> if C<title> is
absent).

=head2 validate

    Net::Nostr::Calendar->validate($event);

Validates a NIP-52 event. Croaks if:

=over

=item * Kind is not 31922, 31923, 31924, or 31925

=item * Kind 31922/31923 missing C<d>, C<title>, or C<start> tag

=item * Kind 31922/31923 C<start> is not less than C<end> (when C<end>
is present)

=item * Kind 31923 missing C<D> tag

=item * Kind 31924 missing C<d> or C<title> tag

=item * Kind 31925 missing C<d>, C<a>, or C<status> tag

=item * Kind 31925 C<status> is not C<accepted>, C<declined>, or
C<tentative>

=back

Returns 1 on success.

=head1 ACCESSORS

=head2 identifier

The C<d> tag value.

=head2 title

The calendar event or calendar title.

=head2 description

The event content. Defaults to C<''>.

=head2 start

The start date (YYYY-MM-DD for kind 31922) or Unix timestamp string
(for kind 31923).

=head2 end

The end date or Unix timestamp string, or C<undef>.

=head2 summary

Brief description, or C<undef>.

=head2 image

Image URL, or C<undef>.

=head2 locations

Arrayref of location strings. Defaults to C<[]>.

=head2 geohash

Geohash string, or C<undef>.

=head2 participants

Arrayref of arrayrefs, each containing pubkey, optional relay URL, and
optional role. Defaults to C<[]>.

=head2 hashtags

Arrayref of hashtag strings. Defaults to C<[]>.

=head2 references

Arrayref of reference URL strings. Defaults to C<[]>.

=head2 calendars

Arrayref of kind 31924 calendar coordinates (from C<a> tags in calendar
events). Defaults to C<[]>.

=head2 calendar_events

Arrayref of arrayrefs, each containing a calendar event coordinate and
optional relay URL (from C<a> tags in calendars). Defaults to C<[]>.

=head2 start_tzid

IANA Time Zone Database identifier for the start time (kind 31923 only).

=head2 end_tzid

IANA Time Zone Database identifier for the end time (kind 31923 only).

=head2 days

Arrayref of day-granularity timestamp strings (C<D> tags, kind 31923
only). Defaults to C<[]>.

=head2 event_coord

The calendar event coordinate (C<a> tag value, RSVP only).

=head2 event_id

The specific calendar event revision ID (C<e> tag value, RSVP only).

=head2 status

RSVP status: C<accepted>, C<declined>, or C<tentative>.

=head2 fb

Free/busy indicator: C<free> or C<busy>. Must be omitted or ignored if
C<status> is C<declined>.

=head2 event_author

Pubkey of the calendar event author (RSVP only).

=head1 SEE ALSO

L<NIP-52|https://github.com/nostr-protocol/nips/blob/master/52.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
