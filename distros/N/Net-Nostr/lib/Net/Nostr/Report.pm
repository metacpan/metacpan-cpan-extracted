package Net::Nostr::Report;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    reported_pubkey
    report_type
    event_id
    blob_hash
    server
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

my %REPORT_TYPES = map { $_ => 1 }
    qw(nudity malware profanity illegal spam impersonation other);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub report {
    my ($class, %args) = @_;

    my $pubkey      = $args{pubkey}      // croak "report requires 'pubkey'";
    my $reported_pk = $args{reported_pk} // croak "report requires 'reported_pk'";
    my $report_type = $args{report_type} // croak "report requires 'report_type'";

    croak "reported_pk must be 64-char lowercase hex"
        unless $reported_pk =~ $HEX64;

    croak "invalid report type '$report_type'"
        unless $REPORT_TYPES{$report_type};

    croak "event_id must be 64-char lowercase hex"
        if defined $args{event_id} && $args{event_id} !~ $HEX64;

    if ($args{blob_hash} && !$args{event_id}) {
        croak "blob report (x tag) requires 'event_id' (e tag)";
    }

    my @tags;

    if ($args{blob_hash}) {
        push @tags, ['x', $args{blob_hash}, $report_type];
        push @tags, ['e', $args{event_id}, $report_type];
        push @tags, ['p', $reported_pk];
        push @tags, ['server', $args{server}] if defined $args{server};
    } elsif ($args{event_id}) {
        push @tags, ['e', $args{event_id}, $report_type];
        push @tags, ['p', $reported_pk];
    } else {
        push @tags, ['p', $reported_pk, $report_type];
    }

    if ($args{labels}) {
        push @tags, @{$args{labels}};
    }

    return Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1984,
        content => $args{content} // '',
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;

    my ($reported_pubkey, $report_type, $event_id, $blob_hash, $server);

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'p' && !defined $reported_pubkey) {
            $reported_pubkey = $tag->[1];
            $report_type = $tag->[2] if defined $tag->[2] && !defined $report_type;
        } elsif ($tag->[0] eq 'e' && !defined $event_id) {
            $event_id = $tag->[1];
            $report_type = $tag->[2] if defined $tag->[2];
        } elsif ($tag->[0] eq 'x' && !defined $blob_hash) {
            $blob_hash = $tag->[1];
            $report_type = $tag->[2] if defined $tag->[2];
        } elsif ($tag->[0] eq 'server' && !defined $server) {
            $server = $tag->[1];
        }
    }

    return $class->new(
        reported_pubkey => $reported_pubkey,
        report_type     => $report_type,
        event_id        => $event_id,
        blob_hash       => $blob_hash,
        server          => $server,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "report event must be kind 1984"
        unless $event->kind == 1984;

    my ($has_p, $has_e, $has_x, $has_report_type);

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'p') {
            $has_p = 1;
        } elsif ($tag->[0] eq 'e') {
            $has_e = 1;
            $has_report_type = 1 if defined $tag->[2];
        } elsif ($tag->[0] eq 'x') {
            $has_x = 1;
            $has_report_type = 1 if defined $tag->[2];
        }
    }

    croak "report event MUST include a p tag"
        unless $has_p;

    if ($has_x && !$has_e) {
        croak "blob report (x tag) MUST include an e tag";
    }

    # If no e or x tag, report type must be on the p tag
    if (!$has_e && !$has_x) {
        my @p = grep { $_->[0] eq 'p' } @{$event->tags};
        croak "report type MUST be included as 3rd entry on p, e, or x tag"
            unless defined $p[0][2];
    }

    return 1;
}

sub report_filter {
    my ($class, %args) = @_;

    my %filter = (kinds => [1984]);

    $filter{'#p'} = [$args{reported_pk}] if defined $args{reported_pk};
    $filter{'#e'} = [$args{event_id}]    if defined $args{event_id};
    $filter{authors} = $args{authors}    if $args{authors};

    return \%filter;
}

1;

__END__


=head1 NAME

Net::Nostr::Report - NIP-56 Reporting

=head1 SYNOPSIS

    use Net::Nostr::Report;

    # Report a profile for spam
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $spammer_pk,
        report_type => 'spam',
    );

    # Report a note as illegal
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $author_pk,
        event_id    => $note_id,
        report_type => 'illegal',
        content     => 'Violates local law',
    );

    # Report a blob as malware
    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $author_pk,
        report_type => 'malware',
        blob_hash   => $hash,
        event_id    => $containing_event_id,
        server      => 'https://example.com/file.ext',
    );

    # Parse a report event
    my $info = Net::Nostr::Report->from_event($event);
    say $info->reported_pubkey;
    say $info->report_type;      # nudity, malware, profanity, etc.

    # Build a subscription filter
    my $filter = Net::Nostr::Report->report_filter(
        reported_pk => $target_pk,
    );

=head1 CONSTRUCTOR

=head2 new

    my $report = Net::Nostr::Report->new(
        reported_pubkey => $pubkey_hex,
        report_type     => 'spam',
        event_id        => $event_id_hex,
    );

Creates a new report object. All fields are optional. Croaks on unknown
arguments. This is the raw constructor; use L</report> to build a
complete kind 1984 event.

=head1 DESCRIPTION

Implements NIP-56 (Reporting). Provides methods to create kind 1984 report
events, parse existing reports, and build subscription filters.

Valid report types: C<nudity>, C<malware>, C<profanity>, C<illegal>,
C<spam>, C<impersonation>, C<other>.

=head2 report

    my $event = Net::Nostr::Report->report(
        pubkey      => $my_pubkey,
        reported_pk => $target_pk,
        report_type => 'spam',
        event_id    => $note_id,       # optional, for note reports
        blob_hash   => $hash,          # optional, for blob reports
        server      => $url,           # optional, for blob reports
        content     => 'reason',       # optional
        labels      => [               # optional, NIP-32
            ['L', 'namespace'],
            ['l', 'value', 'namespace'],
        ],
    );

Creates a kind 1984 report event. For profile-only reports, the report type
is placed on the C<p> tag. For note reports (C<event_id> provided), the type
is placed on the C<e> tag. For blob reports (C<blob_hash> provided), the
type is placed on the C<x> tag and C<event_id> is required.

=head2 from_event

    my $info = Net::Nostr::Report->from_event($event);
    say $info->reported_pubkey;
    say $info->report_type;
    say $info->event_id;    # undef for profile-only reports
    say $info->blob_hash;   # undef unless blob report
    say $info->server;      # undef unless provided

Parses a kind 1984 report event and returns a L<Net::Nostr::Report> object.

=head2 validate

    Net::Nostr::Report->validate($event);

Validates a kind 1984 report event. Croaks if the event is not kind 1984,
has no C<p> tag, or has an C<x> tag without a corresponding C<e> tag.

=head2 report_filter

    my $filter = Net::Nostr::Report->report_filter(
        reported_pk => $target_pk,
        event_id    => $note_id,
        authors     => [$reporter_pk],
    );

Returns a subscription filter hashref for querying report events. All
parameters are optional.

=head1 ACCESSORS

=head2 reported_pubkey

Hex pubkey of the reported user.

=head2 report_type

Report type string: C<nudity>, C<malware>, C<profanity>, C<illegal>,
C<spam>, C<impersonation>, or C<other>.

=head2 event_id

Reported event ID (64-char lowercase hex), or C<undef> for profile-only
reports.

=head2 blob_hash

Blob SHA-256 hash, or C<undef>.

=head2 server

Server URL for blob reports, or C<undef>.

=head1 SEE ALSO

L<NIP-56|https://github.com/nostr-protocol/nips/blob/master/56.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
