package Net::Nostr::ClassifiedListing;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;
use Net::Nostr::Bech32 qw(encode_naddr);

use Class::Tiny qw(
    identifier
    title
    summary
    published_at
    location
    price
    status
    images
    hashtags
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{hashtags} //= [];
    $args{images}   //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub _build_event {
    my ($class, $kind, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "listing requires 'pubkey'";
    my $content    = $args{content}    // croak "listing requires 'content'";
    my $identifier = $args{identifier} // croak "listing requires 'identifier'";

    my @tags;
    push @tags, ['d', $identifier];

    if (defined $args{title}) {
        push @tags, ['title', $args{title}];
    }
    if (defined $args{summary}) {
        push @tags, ['summary', $args{summary}];
    }
    if (defined $args{published_at}) {
        push @tags, ['published_at', '' . $args{published_at}];
    }
    if (defined $args{location}) {
        push @tags, ['location', $args{location}];
    }
    if (defined $args{price}) {
        push @tags, ['price', @{$args{price}}];
    }
    if (defined $args{status}) {
        push @tags, ['status', $args{status}];
    }
    for my $img (@{$args{images} // []}) {
        push @tags, ['image', @$img];
    }
    for my $ht (@{$args{hashtags} // []}) {
        push @tags, ['t', $ht];
    }
    for my $tag (@{$args{extra_tags} // []}) {
        push @tags, $tag;
    }

    delete @args{qw(identifier title summary published_at location price status images hashtags extra_tags)};
    return Net::Nostr::Event->new(%args, kind => $kind, tags => \@tags);
}

sub listing {
    my ($class, %args) = @_;
    return $class->_build_event(30402, %args);
}

sub draft {
    my ($class, %args) = @_;
    return $class->_build_event(30403, %args);
}

sub from_event {
    my ($class, $event) = @_;
    return undef unless $event->kind == 30402 || $event->kind == 30403;

    my ($identifier, $title, $summary, $published_at, $location, $status);
    my @price;
    my @images;
    my @hashtags;

    for my $tag (@{$event->tags}) {
        my $name = $tag->[0];
        if ($name eq 'd')              { $identifier   = $tag->[1] // '' }
        elsif ($name eq 'title')       { $title        = $tag->[1] }
        elsif ($name eq 'summary')     { $summary      = $tag->[1] }
        elsif ($name eq 'published_at') { $published_at = $tag->[1] }
        elsif ($name eq 'location')    { $location     = $tag->[1] }
        elsif ($name eq 'price')       { @price        = @{$tag}[1..$#$tag] }
        elsif ($name eq 'status')      { $status       = $tag->[1] }
        elsif ($name eq 'image')       { push @images, [@{$tag}[1..$#$tag]] }
        elsif ($name eq 't')           { push @hashtags, $tag->[1] }
    }

    return $class->new(
        identifier   => $identifier,
        title        => $title,
        summary      => $summary,
        published_at => $published_at,
        location     => $location,
        price        => (@price ? \@price : undef),
        status       => $status,
        images       => \@images,
        hashtags     => \@hashtags,
    );
}

sub validate {
    my ($class, $event) = @_;

    croak "classified listing MUST be kind 30402 or 30403"
        unless $event->kind == 30402 || $event->kind == 30403;

    my $has_d = grep { $_->[0] eq 'd' } @{$event->tags};
    croak "classified listing MUST include a d tag" unless $has_d;

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

Net::Nostr::ClassifiedListing - NIP-99 classified listings

=head1 SYNOPSIS

    use Net::Nostr::ClassifiedListing;

    my $pubkey = 'aa' x 32;

    # Create a classified listing (kind 30402)
    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $pubkey,
        content      => "# Vintage Guitar\n\nGreat condition, barely played.",
        identifier   => 'vintage-guitar',
        title        => 'Vintage Guitar',
        summary      => 'A beautiful vintage guitar in great condition',
        published_at => 1296962229,
        location     => 'NYC',
        price        => ['500', 'USD'],
        status       => 'active',
        hashtags     => ['music', 'instruments'],
        images       => [
            ['https://example.com/guitar1.jpg', '800x600'],
            ['https://example.com/guitar2.jpg'],
        ],
    );

    # Create a draft/inactive listing (kind 30403, same structure)
    my $draft = Net::Nostr::ClassifiedListing->draft(
        pubkey     => $pubkey,
        content    => "# WIP Listing\n\nNot ready yet.",
        identifier => 'my-draft',
        title      => 'Work in Progress',
    );

    # Recurring price (e.g. monthly rent)
    my $rental = Net::Nostr::ClassifiedListing->listing(
        pubkey     => $pubkey,
        content    => "Apartment for rent.",
        identifier => 'apartment-rent',
        title      => '2BR Apartment',
        price      => ['1500', 'USD', 'month'],
        location   => 'Brooklyn',
    );

    # Parse listing metadata from an event
    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    say $info->title;        # 'Vintage Guitar'
    say $info->location;     # 'NYC'
    say $info->price->[0];   # '500'
    say $info->price->[1];   # 'USD'

    # Generate an naddr for linking
    my $naddr = Net::Nostr::ClassifiedListing->to_naddr($event,
        relays => ['wss://relay.example.com'],
    );

    # Validate a listing event
    Net::Nostr::ClassifiedListing->validate($event);

=head1 DESCRIPTION

Implements NIP-99 classified listings. Classified listings are kind 30402
addressable events that describe products, services, or other things for
sale or offer. The structure is similar to NIP-23 long-form content, with
additional metadata tags for pricing, location, and status.

Content should be a Markdown description of what is being offered. The
C<pubkey> field identifies the party creating the listing.

Draft or inactive listings use kind 30403, which has the same structure
as kind 30402.

=head1 CONSTRUCTOR

=head2 new

    my $info = Net::Nostr::ClassifiedListing->new(%fields);

Creates a new C<Net::Nostr::ClassifiedListing> object. Typically returned by
L</from_event>; calling C<new> directly is useful for testing or
manual construction.

    my $info = Net::Nostr::ClassifiedListing->new(
        identifier => 'my-listing',
        title      => 'Guitar',
        price      => '500 USD',
        location   => 'NYC',
    );

Accepted fields: C<identifier>, C<title>, C<summary>, C<published_at>,
C<location>, C<price>, C<status>, C<images> (defaults to C<[]>),
C<hashtags> (defaults to C<[]>). Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 listing

    my $event = Net::Nostr::ClassifiedListing->listing(
        pubkey       => $hex_pubkey,         # required
        content      => $markdown,           # required
        identifier   => 'listing-slug',      # required (d tag)
        title        => 'Listing Title',     # optional
        summary      => 'Short tagline.',    # optional
        published_at => 1296962229,          # optional (unix timestamp)
        location     => 'NYC',               # optional
        price        => ['100', 'USD'],      # optional
        status       => 'active',            # optional ("active" or "sold")
        hashtags     => ['electronics'],      # optional (t tags)
        images       => [['url', '256x256']],# optional (image tags)
        extra_tags   => [['g', 'dr5regw']],  # optional (additional tags)
        created_at   => time(),              # optional
    );

Creates a kind 30402 classified listing L<Net::Nostr::Event>. C<pubkey>,
C<content>, and C<identifier> are required.

The C<price> parameter is an arrayref of C<[amount, currency]> or
C<[amount, currency, frequency]> where currency is an ISO 4217 code
(or crypto code like C<btc>) and frequency is optional (e.g. C<month>,
C<year>).

    # One-time: $50 USD
    price => ['50', 'USD']

    # Recurring: 15 EUR/month
    price => ['15', 'EUR', 'month']

The C<images> parameter is an arrayref of arrayrefs. Each inner arrayref
contains a URL and an optional dimensions string (C<WxH> in pixels), per
NIP-58.

    images => [
        ['https://example.com/photo.jpg', '800x600'],
        ['https://example.com/detail.jpg'],
    ]

=head2 draft

    my $event = Net::Nostr::ClassifiedListing->draft(
        pubkey     => $hex_pubkey,
        content    => $markdown,
        identifier => 'draft-slug',
        # same optional params as listing()
    );

Creates a kind 30403 draft/inactive listing. Accepts the same parameters
as L</listing>.

=head2 from_event

    my $info = Net::Nostr::ClassifiedListing->from_event($event);

Parses listing metadata from a kind 30402 or 30403 L<Net::Nostr::Event>.
Returns a C<Net::Nostr::ClassifiedListing> object with accessors, or
C<undef> if the event is not a listing kind.

    my $info = Net::Nostr::ClassifiedListing->from_event($event);
    say $info->identifier;   # 'my-listing'
    say $info->title;        # 'Vintage Guitar' or undef
    say $info->price->[1] if $info->price;  # 'USD'

=head2 validate

    Net::Nostr::ClassifiedListing->validate($event);

Validates that an event is a well-formed NIP-99 listing. Croaks if:

=over

=item * Kind is not 30402 or 30403

=item * Missing C<d> tag

=back

    eval { Net::Nostr::ClassifiedListing->validate($event) };
    warn "Invalid listing: $@" if $@;

=head2 to_naddr

    my $naddr = Net::Nostr::ClassifiedListing->to_naddr($event,
        relays => ['wss://relay.com'],
    );

Generates a NIP-19 C<naddr> bech32 string for linking to the listing.
The C<relays> parameter is optional.

=head1 ACCESSORS

These are available on objects returned by L</from_event>.

=head2 identifier

    my $id = $info->identifier;

The C<d> tag value identifying the listing.

=head2 title

    my $title = $info->title;  # or undef

The listing title, or C<undef> if not set.

=head2 summary

    my $text = $info->summary;  # or undef

Short tagline or summary for the listing, or C<undef>.

=head2 published_at

    my $ts = $info->published_at;  # '1296962229' or undef

The original publication timestamp (stringified unix seconds), or C<undef>.

=head2 location

    my $loc = $info->location;  # 'NYC' or undef

The listing location, or C<undef>.

=head2 price

    my $price = $info->price;  # ['100', 'USD'] or ['15', 'EUR', 'month'] or undef

Arrayref of C<[amount, currency]> or C<[amount, currency, frequency]>,
or C<undef> if no price tag is present.

=head2 status

    my $status = $info->status;  # 'active', 'sold', or undef

The listing status, or C<undef>.

=head2 images

    my $imgs = $info->images;  # [['url', '256x256'], ['url2']]

Arrayref of arrayrefs, each containing a URL and optional dimensions.
Empty arrayref if no image tags are present.

=head2 hashtags

    my $tags = $info->hashtags;  # ['electronics', 'gadgets']

Arrayref of hashtag strings from C<t> tags. Empty arrayref if none.

=head1 SEE ALSO

L<NIP-99|https://github.com/nostr-protocol/nips/blob/master/99.md>,
L<Net::Nostr::Article>, L<Net::Nostr>, L<Net::Nostr::Event>

=cut
