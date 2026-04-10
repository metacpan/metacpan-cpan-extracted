package Net::Nostr::MediaAttachment;

use strictures 2;

use Carp qw(croak);

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
    image
    summary
    alt
    service
    fallback
    fields
);

# Fields that can appear multiple times
my %MULTI_FIELDS = (fallback => 1);

# Known single-value fields (NIP-94)
my %KNOWN_FIELDS = map { $_ => 1 }
    qw(url m x ox size dim magnet i blurhash thumb image summary alt service);

sub new {
    my $class = shift;
    my %args = @_;
    $args{fallback} //= [];
    $args{fields}   //= {};
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub imeta_tag {
    my ($class, %args) = @_;

    my $url = $args{url} // croak "imeta_tag requires 'url'";

    my @entries = ("url $url");

    my $has_other = 0;
    for my $key (qw(m x ox size dim magnet i blurhash thumb image summary alt service)) {
        if (defined $args{$key}) {
            push @entries, "$key $args{$key}";
            $has_other = 1;
        }
    }

    if ($args{fallback}) {
        for my $fb (@{$args{fallback}}) {
            push @entries, "fallback $fb";
            $has_other = 1;
        }
    }

    croak "imeta tag MUST have at least one field besides url"
        unless $has_other;

    return ['imeta', @entries];
}

sub from_tag {
    my ($class, $tag) = @_;

    my %attrs;
    my @fallback;
    my %fields;

    for my $idx (1 .. $#$tag) {
        my $entry = $tag->[$idx];
        my ($key, $value) = $entry =~ /^(\S+)\s(.*)$/s;
        next unless defined $key;

        if ($key eq 'fallback') {
            push @fallback, $value;
        } elsif ($KNOWN_FIELDS{$key}) {
            $attrs{$key} = $value;
        } else {
            $fields{$key} = $value;
        }
    }

    return $class->new(
        %attrs,
        fallback => \@fallback,
        fields   => \%fields,
    );
}

sub from_event {
    my ($class, $event) = @_;

    my @attachments;
    for my $tag (@{$event->tags}) {
        next unless $tag->[0] eq 'imeta';
        push @attachments, $class->from_tag($tag);
    }

    return @attachments;
}

sub for_url {
    my ($class, $event, $url) = @_;

    for my $tag (@{$event->tags}) {
        next unless $tag->[0] eq 'imeta';
        for my $entry (@$tag) {
            if ($entry eq "url $url") {
                return $class->from_tag($tag);
            }
        }
    }

    return undef;
}

1;

__END__


=head1 NAME

Net::Nostr::MediaAttachment - NIP-92 Media Attachments

=head1 SYNOPSIS

    use Net::Nostr::MediaAttachment;

    # Build an imeta tag
    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        dim      => '1920x1080',
        alt      => 'A scenic photo',
        blurhash => 'eVF$^OI',
        fallback => ['https://alt.example.com/photo.jpg'],
    );

    # Attach to an event
    my $event = Net::Nostr::Event->new(
        pubkey  => $pubkey,
        kind    => 1,
        content => 'Check this out https://example.com/photo.jpg',
        tags    => [$tag],
    );

    # Parse imeta tags from an event
    my @attachments = Net::Nostr::MediaAttachment->from_event($event);
    for my $att (@attachments) {
        say $att->url;
        say $att->m;        # MIME type
        say $att->dim;      # e.g. '1920x1080'
        say $att->alt;      # accessibility description
    }

    # Get metadata for a specific URL
    my $info = Net::Nostr::MediaAttachment->for_url($event, $url);

=head1 CONSTRUCTOR

=head2 new

    my $att = Net::Nostr::MediaAttachment->new(
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        dim      => '1920x1080',
        fallback => ['https://alt.example.com/photo.jpg'],
    );

Creates a new media attachment object. All fields are optional.
C<fallback> defaults to C<[]> and C<fields> defaults to C<{}>.
Croaks on unknown arguments.

=head1 DESCRIPTION

Implements NIP-92 (Media Attachments). Provides methods to build C<imeta>
tags, parse them from events, and look up metadata by URL.

Each C<imeta> tag is variadic with space-delimited key/value entries. It
MUST have a C<url> and at least one other field. Fields from NIP-94 are
supported: C<m>, C<x>, C<ox>, C<size>, C<dim>, C<magnet>, C<i>,
C<blurhash>, C<thumb>, C<image>, C<summary>, C<alt>, C<service>, and
C<fallback> (which may appear multiple times).

=head2 imeta_tag

    my $tag = Net::Nostr::MediaAttachment->imeta_tag(
        url      => 'https://example.com/photo.jpg',
        m        => 'image/jpeg',
        dim      => '1920x1080',
        alt      => 'Description',
        x        => $sha256_hex,
        fallback => ['https://alt1.com/photo.jpg'],
    );

Creates an C<imeta> tag arrayref. C<url> is required, and at least one
other field must be provided. C<fallback> accepts an arrayref of URLs.

=head2 from_tag

    my $info = Net::Nostr::MediaAttachment->from_tag($imeta_tag);
    say $info->url;
    say $info->m;

Parses a single C<imeta> tag arrayref into a L<Net::Nostr::MediaAttachment>
object. Unknown fields are available via the C<fields> accessor hashref.

=head2 from_event

    my @attachments = Net::Nostr::MediaAttachment->from_event($event);

Returns a list of L<Net::Nostr::MediaAttachment> objects, one for each
C<imeta> tag in the event.

=head2 for_url

    my $info = Net::Nostr::MediaAttachment->for_url($event, $url);

Returns the L<Net::Nostr::MediaAttachment> for the given URL, or C<undef>
if not found.

=head1 ACCESSORS

=head2 url

Media URL.

=head2 m

MIME type (e.g. C<'image/jpeg'>).

=head2 x

SHA-256 hash of the file.

=head2 ox

SHA-256 hash of the original file before any transformations.

=head2 size

File size in bytes.

=head2 dim

Dimensions string (e.g. C<'1920x1080'>).

=head2 magnet

Magnet URI.

=head2 i

Torrent infohash.

=head2 blurhash

Blurhash string.

=head2 thumb

Thumbnail URL.

=head2 image

Image URL.

=head2 summary

Description or summary.

=head2 alt

Accessibility description.

=head2 service

Service URL.

=head2 fallback

Arrayref of fallback URLs.

=head2 fields

Hashref of unknown/extension fields.

=head1 SEE ALSO

L<NIP-92|https://github.com/nostr-protocol/nips/blob/master/92.md>,
L<NIP-94|https://github.com/nostr-protocol/nips/blob/master/94.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
