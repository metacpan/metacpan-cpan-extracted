package Net::Nostr::Torrent;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    info_hash
    title
    description
    files
    trackers
    identifiers
    hashtags
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{files}       //= [];
    $args{trackers}    //= [];
    $args{identifiers} //= [];
    $args{hashtags}    //= [];
    $args{description} //= '';
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub to_event {
    my ($class, %args) = @_;

    my $info_hash = delete $args{info_hash}
        // croak "to_event requires 'info_hash'";
    my $title = delete $args{title}
        // croak "to_event requires 'title'";
    my $content     = delete $args{content}     // '';
    my $files       = delete $args{files}       // [];
    my $trackers    = delete $args{trackers}    // [];
    my $identifiers = delete $args{identifiers} // [];
    my $hashtags    = delete $args{hashtags}    // [];

    my @tags;
    push @tags, ['title', $title];
    push @tags, ['x', $info_hash];

    for my $file (@$files) {
        push @tags, ['file', @$file];
    }

    for my $tracker (@$trackers) {
        push @tags, ['tracker', $tracker];
    }

    for my $id (@$identifiers) {
        push @tags, ['i', $id];
    }

    for my $tag (@$hashtags) {
        push @tags, ['t', $tag];
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 2003,
        content => $content,
        tags    => \@tags,
    );
}

sub comment {
    my ($class, %args) = @_;

    return Net::Nostr::Event->new(
        %args,
        kind => 2004,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless $kind == 2003 || $kind == 2004;

    if ($kind == 2004) {
        return $class->new(description => $event->content);
    }

    my ($info_hash, $title, @files, @trackers, @identifiers, @hashtags);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if ($t eq 'x') {
            $info_hash = $tag->[1];
        } elsif ($t eq 'title') {
            $title = $tag->[1];
        } elsif ($t eq 'file') {
            push @files, [@{$tag}[1 .. $#$tag]];
        } elsif ($t eq 'tracker') {
            push @trackers, $tag->[1];
        } elsif ($t eq 'i') {
            push @identifiers, $tag->[1];
        } elsif ($t eq 't') {
            push @hashtags, $tag->[1];
        }
    }

    return $class->new(
        info_hash   => $info_hash,
        title       => $title,
        description => $event->content,
        files       => \@files,
        trackers    => \@trackers,
        identifiers => \@identifiers,
        hashtags    => \@hashtags,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "torrent event MUST be kind 2003 or 2004"
        unless $kind == 2003 || $kind == 2004;

    if ($kind == 2003) {
        my $has_x = grep { $_->[0] eq 'x' } @{$event->tags};
        croak "torrent MUST have an 'x' tag (info hash)" unless $has_x;

        my $has_title = grep { $_->[0] eq 'title' } @{$event->tags};
        croak "torrent MUST have a 'title' tag" unless $has_title;
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::Torrent - NIP-35 Torrents

=head1 SYNOPSIS

    use Net::Nostr::Torrent;

    # Create a torrent event (kind 2003)
    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $hex_pubkey,
        info_hash   => 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3',
        title       => 'Example Torrent',
        content     => 'A long description',
        files       => [
            ['video.mkv', '4294967296'],
            ['subs.srt', '2048'],
        ],
        trackers    => ['udp://tracker.example.com:6969'],
        identifiers => ['imdb:tt15239678', 'tmdb:movie:693134'],
        hashtags    => ['movie', '4k'],
    );

    # Create a torrent comment (kind 2004)
    my $comment = Net::Nostr::Torrent->comment(
        pubkey  => $hex_pubkey,
        content => 'Great torrent!',
        tags    => [['e', $torrent_event_id, '', 'root']],
    );

    # Parse a torrent event
    my $torrent = Net::Nostr::Torrent->from_event($event);
    say $torrent->title;       # Example Torrent
    say $torrent->info_hash;   # d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3

    # Validate
    Net::Nostr::Torrent->validate($event);

=head1 DESCRIPTION

Implements NIP-35 (Torrents). Kind 2003 events are a simple torrent index
containing enough information to search for content and construct a magnet
link. No torrent files exist on nostr.

Kind 2004 events are torrent comments that work exactly like kind 1 text
notes and should follow NIP-10 for tagging.

=head2 Tags

=over 4

=item * C<x> - V1 BitTorrent Info Hash, as seen in the magnet link
C<magnet:?xt=urn:btih:HASH>

=item * C<title> - The torrent title

=item * C<file> - A file entry including the full path and file size in bytes

=item * C<tracker> - (Optional) A tracker URL for this torrent

=back

=head2 Tag prefixes

Tag prefixes (C<i> tags) label content with external references:

=over 4

=item * C<tcat> - Comma-separated text category path (e.g.
C<tcat:video,movie,4k>)

=item * C<newznab> - Category ID from newznab

=item * C<tmdb> - The Movie Database ID (e.g. C<tmdb:movie:693134>)

=item * C<ttvdb> - TV Database ID (e.g. C<ttvdb:movie:290272>)

=item * C<imdb> - IMDB ID (e.g. C<imdb:tt15239678>)

=item * C<mal> - MyAnimeList ID (e.g. C<mal:anime:9253>, C<mal:manga:17517>)

=item * C<anilist> - AniList ID

=back

A second-level prefix should be included where the database supports
multiple media types.

To make torrents searchable by general category, you SHOULD include
C<t> tags like C<movie>, C<tv>, C<HD>, C<UHD>, etc.

=head1 CONSTRUCTOR

=head2 new

    my $torrent = Net::Nostr::Torrent->new(
        info_hash => 'abc123',
        title     => 'Example',
    );

Creates a new C<Net::Nostr::Torrent> object. Croaks on unknown arguments.
Array fields (C<files>, C<trackers>, C<identifiers>, C<hashtags>) default
to C<[]>. C<description> defaults to C<''>.

=head1 CLASS METHODS

=head2 to_event

    my $event = Net::Nostr::Torrent->to_event(
        pubkey      => $hex_pubkey,          # required
        info_hash   => $info_hash,           # required (x tag)
        title       => $title,               # required (title tag)
        content     => $description,         # optional, defaults to ''
        files       => [[$path, $size]],     # optional
        trackers    => [$tracker_url],       # optional
        identifiers => [$id_string],         # optional (i tags)
        hashtags    => [$tag],               # optional (t tags)
        created_at  => time(),               # optional
    );

Creates a kind 2003 torrent L<Net::Nostr::Event>. C<info_hash> and
C<title> are required. The info hash becomes the C<x> tag. Files become
C<file> tags with path and size. Trackers become C<tracker> tags.
Identifiers become C<i> tags. Hashtags become C<t> tags.

=head2 comment

    my $event = Net::Nostr::Torrent->comment(
        pubkey  => $hex_pubkey,
        content => 'Great torrent!',
        tags    => [['e', $torrent_id, '', 'root']],
    );

Creates a kind 2004 torrent comment L<Net::Nostr::Event>. Works exactly
like a kind 1 event and should follow NIP-10 for tagging. All arguments
are passed through to L<Net::Nostr::Event/new>.

=head2 from_event

    my $torrent = Net::Nostr::Torrent->from_event($event);

Parses a kind 2003 or 2004 event into a C<Net::Nostr::Torrent> object.
Returns C<undef> for unrecognized kinds. For kind 2003, extracts
C<info_hash>, C<title>, C<description>, C<files>, C<trackers>,
C<identifiers>, and C<hashtags>. For kind 2004, only C<description>
(from content) is populated.

=head2 validate

    Net::Nostr::Torrent->validate($event);

Validates a NIP-35 event. Croaks if:

=over

=item * Kind is not 2003 or 2004

=item * Kind 2003 missing C<x> tag (info hash)

=item * Kind 2003 missing C<title> tag

=back

Returns 1 on success.

=head1 ACCESSORS

=head2 info_hash

The V1 BitTorrent Info Hash (C<x> tag value).

=head2 title

The torrent title.

=head2 description

The long description (event content). Defaults to C<''>.

=head2 files

Arrayref of arrayrefs, each containing a file path and size in bytes.
Defaults to C<[]>.

=head2 trackers

Arrayref of tracker URL strings. Defaults to C<[]>.

=head2 identifiers

Arrayref of C<i> tag value strings (tag prefixes like C<imdb:tt1234567>).
Defaults to C<[]>.

=head2 hashtags

Arrayref of C<t> tag value strings. Defaults to C<[]>.

=head1 SEE ALSO

L<NIP-35|https://github.com/nostr-protocol/nips/blob/master/35.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
