package Net::Nostr::FileMetadata;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    url
    m
    x
    ox
    size
    dim
    magnet
    i
    blurhash
    thumb
    thumb_hash
    image
    image_hash
    summary
    alt
    fallback
    service
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

my %SIMPLE_TAGS = map { $_ => 1 }
    qw(url m x ox size dim magnet i blurhash summary alt service);

sub new {
    my $class = shift;
    my %args = @_;
    $args{fallback} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub to_event {
    my ($class, %args) = @_;

    my $url = delete $args{url} // croak "to_event requires 'url'";
    my $m   = delete $args{m}   // croak "to_event requires 'm'";
    my $x   = delete $args{x}   // croak "to_event requires 'x'";
    my $ox  = delete $args{ox}  // croak "to_event requires 'ox'";

    croak "x must be 64-char lowercase hex (SHA-256)" unless $x =~ $HEX64;
    croak "ox must be 64-char lowercase hex (SHA-256)" unless $ox =~ $HEX64;
    croak "m must be a lowercase MIME type (e.g. 'image/jpeg')"
        unless $m =~ m{/};
    croak "m must be a lowercase MIME type" unless $m eq lc($m);

    my @tags;
    push @tags, ['url', $url];
    push @tags, ['m', $m];
    push @tags, ['x', $x];
    push @tags, ['ox', $ox];

    for my $key (qw(size dim magnet i blurhash summary alt service)) {
        my $val = delete $args{$key};
        next unless defined $val;
        if ($key eq 'dim') {
            croak "dim must be in '<width>x<height>' format (e.g. '1920x1080')"
                unless $val =~ /\A\d+x\d+\z/;
        }
        push @tags, [$key, $val];
    }

    # thumb/image with optional hash
    for my $key (qw(thumb image)) {
        my $val  = delete $args{$key};
        my $hash = delete $args{"${key}_hash"};
        next unless defined $val;
        my @tag = ($key, $val);
        push @tag, $hash if defined $hash;
        push @tags, \@tag;
    }

    # fallback (zero or more)
    my $fallback = delete $args{fallback};
    if ($fallback) {
        for my $fb (@$fallback) {
            push @tags, ['fallback', $fb];
        }
    }

    # extra_tags
    my $extra = delete $args{extra_tags};
    if ($extra) {
        push @tags, @$extra;
    }

    return Net::Nostr::Event->new(%args, kind => 1063, tags => \@tags);
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 1063;

    my %attrs;
    my @fallback;

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'fallback') {
            push @fallback, $tag->[1];
        } elsif ($name eq 'thumb') {
            $attrs{thumb}      = $tag->[1];
            $attrs{thumb_hash} = $tag->[2] if defined $tag->[2];
        } elsif ($name eq 'image') {
            $attrs{image}      = $tag->[1];
            $attrs{image_hash} = $tag->[2] if defined $tag->[2];
        } elsif ($SIMPLE_TAGS{$name}) {
            $attrs{$name} = $tag->[1];
        }
    }

    return $class->new(%attrs, fallback => \@fallback);
}

sub validate {
    my ($class, $event) = @_;

    croak "file metadata event MUST be kind 1063" unless $event->kind == 1063;

    my %has;
    for my $tag (@{$event->tags}) {
        $has{$tag->[0]} = 1;
    }

    croak "file metadata event MUST have a 'url' tag" unless $has{url};
    croak "file metadata event MUST have an 'm' tag"  unless $has{m};
    croak "file metadata event MUST have an 'x' tag"  unless $has{x};
    croak "file metadata event MUST have an 'ox' tag" unless $has{ox};

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::FileMetadata - NIP-94 File Metadata events

=head1 SYNOPSIS

    use Net::Nostr::FileMetadata;

    # Build a kind 1063 file metadata event
    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey   => $pubkey,
        content  => 'A scenic photo',
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        x        => $sha256_hex,
        ox       => $original_sha256_hex,
        dim      => '1920x1080',
        alt      => 'A scenic photo',
        blurhash => 'eVF$^OI',
        fallback => ['https://alt.example.com/photo.jpg'],
    );

    # Parse file metadata from a kind 1063 event
    my $fm = Net::Nostr::FileMetadata->from_event($event);
    say $fm->url;       # https://example.com/photo.jpg
    say $fm->m;         # image/jpeg
    say $fm->dim;       # 1920x1080
    say $fm->alt;       # A scenic photo

    # Validate a file metadata event
    Net::Nostr::FileMetadata->validate($event);

=head1 DESCRIPTION

Implements NIP-94 (File Metadata). Provides methods to build kind 1063
file metadata events, parse them, and validate their structure.

Kind 1063 events describe shared files with metadata tags. The C<content>
field holds a description or caption. Required tags are C<url>, C<m>
(MIME type), C<x> (SHA-256 hash of the file), and C<ox> (SHA-256 hash of
the original file before any server transformations).

Optional tags include C<size>, C<dim>, C<magnet>, C<i>, C<blurhash>,
C<thumb>, C<image>, C<summary>, C<alt>, C<fallback> (zero or more), and
C<service>.

=head1 CONSTRUCTOR

=head2 new

    my $fm = Net::Nostr::FileMetadata->new(
        url  => 'https://example.com/photo.jpg',
        m    => 'image/jpeg',
        x    => $sha256_hex,
        ox   => $original_sha256_hex,
    );

Creates a new C<Net::Nostr::FileMetadata> object. All fields are optional.
C<fallback> defaults to C<[]>. Croaks on unknown arguments. Typically
returned by L</from_event>; calling C<new> directly is useful for testing.

=head1 CLASS METHODS

=head2 to_event

    my $event = Net::Nostr::FileMetadata->to_event(
        pubkey     => $hex_pubkey,
        content    => 'A scenic photo',
        url        => 'https://example.com/photo.jpg',
        m          => 'image/jpeg',
        x          => $sha256_hex,
        ox         => $original_sha256_hex,
        size       => '1048576',
        dim        => '1920x1080',
        magnet     => 'magnet:?xt=urn:btih:abc',
        i          => 'infohash',
        blurhash   => 'eVF$^OI',
        thumb      => 'https://example.com/thumb.jpg',
        thumb_hash => $thumb_sha256_hex,
        image      => 'https://example.com/preview.jpg',
        image_hash => $preview_sha256_hex,
        summary    => 'excerpt text',
        alt        => 'accessibility description',
        fallback   => ['https://alt.example.com/photo.jpg'],
        service    => 'nip96',
        extra_tags => [['t', 'photo']],
        created_at => time(),
    );

Creates a kind 1063 L<Net::Nostr::Event>. C<url>, C<m>, C<x>, and C<ox> are
required. C<x> and C<ox> must be 64-character lowercase hex (SHA-256). C<m>
must be a lowercase MIME type containing a slash. C<dim>, if provided, must be
in C<< <width>x<height> >> format.

C<thumb> and C<image> accept an optional hash via C<thumb_hash> and
C<image_hash>. C<fallback> accepts an arrayref of URLs. C<extra_tags> allows
injecting additional tags.

Any remaining arguments (C<pubkey>, C<content>, C<created_at>) are passed
through to L<Net::Nostr::Event/new>.

=head2 from_event

    my $fm = Net::Nostr::FileMetadata->from_event($event);

Parses a kind 1063 event into a C<Net::Nostr::FileMetadata> object. Returns
C<undef> if the event is not kind 1063.

    my $fm = Net::Nostr::FileMetadata->from_event($event);
    say $fm->url;
    say $fm->m;
    say $fm->size;

=head2 validate

    Net::Nostr::FileMetadata->validate($event);

Validates that an event is a well-formed NIP-94 file metadata event. Croaks
if the kind is not 1063 or if any required tag (C<url>, C<m>, C<x>, C<ox>)
is missing. Returns 1 on success.

    eval { Net::Nostr::FileMetadata->validate($event) };
    warn "Invalid: $@" if $@;

=head1 ACCESSORS

=head2 url

File URL.

=head2 m

MIME type (e.g. C<'image/jpeg'>). Must be lowercase.

=head2 x

SHA-256 hex hash of the file.

=head2 ox

SHA-256 hex hash of the original file before server transformations.

=head2 size

File size in bytes (string).

=head2 dim

Dimensions in C<< <width>x<height> >> format (e.g. C<'1920x1080'>).

=head2 magnet

Magnet URI.

=head2 i

Torrent infohash.

=head2 blurhash

Blurhash string for loading placeholder.

=head2 thumb

Thumbnail URL (same aspect ratio as original).

=head2 thumb_hash

SHA-256 hex hash of the thumbnail.

=head2 image

Preview image URL (same dimensions as original).

=head2 image_hash

SHA-256 hex hash of the preview image.

=head2 summary

Text excerpt.

=head2 alt

Accessibility description.

=head2 fallback

Arrayref of fallback file source URLs.

=head2 service

Service type serving the file (e.g. NIP-96).

=head1 SEE ALSO

L<NIP-94|https://github.com/nostr-protocol/nips/blob/master/94.md>,
L<Net::Nostr::MediaAttachment>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
