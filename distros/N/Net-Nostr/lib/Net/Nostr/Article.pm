package Net::Nostr::Article;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;
use Net::Nostr::Bech32 qw(encode_naddr);

use Class::Tiny qw(
    identifier
    title
    image
    summary
    published_at
    hashtags
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{hashtags} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub _build_event {
    my ($class, $kind, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "article requires 'pubkey'";
    my $content    = $args{content}    // croak "article requires 'content'";
    my $identifier = $args{identifier} // croak "article requires 'identifier'";

    my @tags;
    push @tags, ['d', $identifier];

    if (defined $args{title}) {
        push @tags, ['title', $args{title}];
    }
    if (defined $args{image}) {
        push @tags, ['image', $args{image}];
    }
    if (defined $args{summary}) {
        push @tags, ['summary', $args{summary}];
    }
    if (defined $args{published_at}) {
        push @tags, ['published_at', '' . $args{published_at}];
    }
    for my $ht (@{$args{hashtags} // []}) {
        push @tags, ['t', $ht];
    }
    for my $tag (@{$args{extra_tags} // []}) {
        push @tags, $tag;
    }

    delete @args{qw(identifier title image summary published_at hashtags extra_tags)};
    return Net::Nostr::Event->new(%args, kind => $kind, tags => \@tags);
}

sub article {
    my ($class, %args) = @_;
    return $class->_build_event(30023, %args);
}

sub draft {
    my ($class, %args) = @_;
    return $class->_build_event(30024, %args);
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 30023 || $event->kind == 30024;

    my ($identifier, $title, $image, $summary, $published_at);
    my @hashtags;

    for my $tag (@{$event->tags}) {
        next unless @$tag >= 2;
        my $name = $tag->[0];
        if ($name eq 'd')            { $identifier   = $tag->[1] // '' }
        elsif ($name eq 'title')     { $title        = $tag->[1] }
        elsif ($name eq 'image')     { $image        = $tag->[1] }
        elsif ($name eq 'summary')   { $summary      = $tag->[1] }
        elsif ($name eq 'published_at') { $published_at = $tag->[1] }
        elsif ($name eq 't')         { push @hashtags, $tag->[1] }
    }

    return $class->new(
        identifier   => $identifier,
        title        => $title,
        image        => $image,
        summary      => $summary,
        published_at => $published_at,
        hashtags     => \@hashtags,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "article MUST be kind 30023 or 30024"
        unless $event->kind == 30023 || $event->kind == 30024;

    my $has_d = grep { $_->[0] eq 'd' } @{$event->tags};
    croak "article MUST include a d tag" unless $has_d;

    return 1;
}

sub to_naddr {
    my ($class, $event, %args) = @_;
    return encode_naddr(
        identifier => $event->d_tag,
        pubkey     => $event->pubkey,
        kind       => $event->kind,
        relays     => $args{relays} // [],
    );
}

1;

__END__

=head1 NAME

Net::Nostr::Article - NIP-23 long-form content

=head1 SYNOPSIS

    use Net::Nostr::Article;

    my $pubkey = 'aa' x 32;

    # Create an article (kind 30023)
    my $event = Net::Nostr::Article->article(
        pubkey       => $pubkey,
        content      => "# My Article\n\nMarkdown content here.",
        identifier   => 'my-article',
        title        => 'My Article',
        summary      => 'A short summary.',
        image        => 'https://example.com/banner.png',
        published_at => 1296962229,
        hashtags     => ['nostr', 'blog'],
    );

    # Create a draft (kind 30024, same structure)
    my $draft = Net::Nostr::Article->draft(
        pubkey     => $pubkey,
        content    => "# WIP\n\nNot finished yet.",
        identifier => 'my-draft',
        title      => 'Work in Progress',
    );

    # Parse article metadata from an event
    my $info = Net::Nostr::Article->from_event($event);
    say $info->title;        # 'My Article'
    say $info->identifier;   # 'my-article'
    say $info->published_at; # '1296962229'

    # Generate an naddr for linking
    my $naddr = Net::Nostr::Article->to_naddr($event,
        relays => ['wss://relay.example.com'],
    );

    # Validate an article event
    Net::Nostr::Article->validate($event);

=head1 DESCRIPTION

Implements NIP-23 long-form content (articles and drafts). Articles are
kind 30023 addressable events with Markdown content and optional metadata
tags. Drafts are kind 30024 with the same structure.

Content should be Markdown text. Clients creating articles MUST NOT hard
line-break paragraphs and MUST NOT include HTML in the Markdown.

Articles are editable via the C<d> tag identifier. The C<created_at> field
represents the date of the last update. Use the C<published_at> tag for the
original publication date.

References to other Nostr entities in the content should use C<nostr:> URIs
(NIP-21).

Replies to articles MUST use NIP-22 kind 1111 comments (see
L<Net::Nostr::Comment>).

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::Article->new(%fields);

Creates a new C<Net::Nostr::Article> object. Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::Article->new(
        identifier => 'my-article',
        title      => 'My Article',
        summary    => 'A brief overview.',
        image      => 'https://example.com/cover.jpg',
    );

Accepted fields: C<identifier>, C<title>, C<image>, C<summary>,
C<published_at>, C<hashtags> (defaults to C<[]>). Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 article

    my $event = Net::Nostr::Article->article(
        pubkey       => $hex_pubkey,         # required
        content      => $markdown,          # required
        identifier   => 'article-slug',     # required (d tag)
        title        => 'Article Title',    # optional
        image        => 'https://...',      # optional
        summary      => 'Short summary.',   # optional
        published_at => 1296962229,         # optional (unix timestamp)
        hashtags     => ['topic1'],         # optional (t tags)
        extra_tags   => [['e', $id, $r]],   # optional (additional tags)
        created_at   => time(),             # optional
    );

Creates a kind 30023 article L<Net::Nostr::Event>. C<pubkey>, C<content>,
and C<identifier> are required. All metadata fields are optional.

The C<published_at> value is stringified in the tag per spec. The
C<extra_tags> parameter accepts an arrayref of additional tags (e.g. C<e>,
C<a>, C<p> tags for references).

    my $event = Net::Nostr::Article->article(
        pubkey     => 'aa' x 32,
        content    => "# Hello\n\nWorld.",
        identifier => 'hello-world',
        title      => 'Hello',
        hashtags   => ['greeting'],
    );

=head2 draft

    my $event = Net::Nostr::Article->draft(
        pubkey     => $hex_pubkey,
        content    => $markdown,
        identifier => 'draft-slug',
        # same optional params as article()
    );

Creates a kind 30024 draft event. Accepts the same parameters as
L</article>. Drafts have the same structure as articles but are not
intended for publication.

=head2 from_event

    my $info = Net::Nostr::Article->from_event($event);

Parses article metadata from a kind 30023 or 30024 L<Net::Nostr::Event>.
Returns a C<Net::Nostr::Article> object with accessors, or C<undef> if the
event is not an article or draft kind.

    my $info = Net::Nostr::Article->from_event($event);
    say $info->identifier;   # 'my-article'
    say $info->title;        # 'My Article' or undef
    say $info->hashtags;     # ['nostr', 'blog']

=head2 validate

    Net::Nostr::Article->validate($event);

Validates that an event is a well-formed NIP-23 article. Croaks if:

=over

=item * Kind is not 30023 or 30024

=item * Missing C<d> tag

=back

    eval { Net::Nostr::Article->validate($event) };
    warn "Invalid article: $@" if $@;

=head2 to_naddr

    my $naddr = Net::Nostr::Article->to_naddr($event,
        relays => ['wss://relay.com'],
    );

Generates a NIP-19 C<naddr> bech32 string for linking to the article.
The C<relays> parameter is optional.

    my $naddr = Net::Nostr::Article->to_naddr($article_event);
    # naddr1...

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 identifier

    my $id = $info->identifier;

The C<d> tag value identifying the article.

=head2 title

    my $title = $info->title;  # or undef

The article title, or C<undef> if not set.

=head2 image

    my $url = $info->image;  # or undef

URL of the article's header image, or C<undef>.

=head2 summary

    my $text = $info->summary;  # or undef

The article summary, or C<undef>.

=head2 published_at

    my $ts = $info->published_at;  # '1296962229' or undef

The original publication timestamp (stringified unix seconds), or C<undef>.

=head2 hashtags

    my $tags = $info->hashtags;  # ['nostr', 'blog']

Arrayref of hashtag strings from C<t> tags. Empty arrayref if none.

=head1 SEE ALSO

L<NIP-23|https://github.com/nostr-protocol/nips/blob/master/23.md>,
L<Net::Nostr::Comment>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
