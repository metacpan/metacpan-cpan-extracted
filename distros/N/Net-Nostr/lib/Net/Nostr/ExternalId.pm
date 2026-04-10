package Net::Nostr::ExternalId;

use strictures 2;

use Carp qw(croak);

use Class::Tiny qw(
    type
    value
    blockchain
    chain_id
    hint
);

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

# Tag builders -- each returns ($i_tag, $k_tag)

sub url_tags {
    my ($class, $url, %opts) = @_;
    # Strip fragment
    $url =~ s/#.*//;
    my @i = ('i', $url);
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'web']);
}

sub isbn_tags {
    my ($class, $isbn, %opts) = @_;
    $isbn =~ s/-//g;
    my @i = ('i', "isbn:$isbn");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'isbn']);
}

sub geo_tags {
    my ($class, $geohash, %opts) = @_;
    $geohash = lc $geohash;
    my @i = ('i', "geo:$geohash");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'geo']);
}

sub country_tags {
    my ($class, $code, %opts) = @_;
    $code = uc $code;
    my @i = ('i', "iso3166:$code");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'iso3166']);
}

sub isan_tags {
    my ($class, $isan, %opts) = @_;
    my @i = ('i', "isan:$isan");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'isan']);
}

sub doi_tags {
    my ($class, $doi, %opts) = @_;
    $doi = lc $doi;
    my @i = ('i', "doi:$doi");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'doi']);
}

sub hashtag_tags {
    my ($class, $topic, %opts) = @_;
    $topic = lc $topic;
    my @i = ('i', "#$topic");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', '#']);
}

sub podcast_feed_tags {
    my ($class, $guid, %opts) = @_;
    my @i = ('i', "podcast:guid:$guid");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'podcast:guid']);
}

sub podcast_episode_tags {
    my ($class, $guid, %opts) = @_;
    my @i = ('i', "podcast:item:guid:$guid");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'podcast:item:guid']);
}

sub podcast_publisher_tags {
    my ($class, $guid, %opts) = @_;
    my @i = ('i', "podcast:publisher:guid:$guid");
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', 'podcast:publisher:guid']);
}

sub blockchain_tx_tags {
    my ($class, $blockchain, $txid, %opts) = @_;
    $txid = lc $txid;
    my $id_str;
    if (defined $opts{chain_id}) {
        $id_str = "$blockchain:$opts{chain_id}:tx:$txid";
    } else {
        $id_str = "$blockchain:tx:$txid";
    }
    my @i = ('i', $id_str);
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', "$blockchain:tx"]);
}

sub blockchain_address_tags {
    my ($class, $blockchain, $address, %opts) = @_;
    # Ethereum addresses are hex, lowercase. Bitcoin base58 is case-sensitive.
    if ($blockchain eq 'ethereum') {
        $address = lc $address;
    }
    my $id_str;
    if (defined $opts{chain_id}) {
        $id_str = "$blockchain:$opts{chain_id}:address:$address";
    } else {
        $id_str = "$blockchain:address:$address";
    }
    my @i = ('i', $id_str);
    push @i, $opts{hint} if defined $opts{hint};
    return (\@i, ['k', "$blockchain:address"]);
}

# Parse an i tag value into its components

sub parse {
    my ($class, $value) = @_;

    # URL
    if ($value =~ m{^https?://}) {
        return { type => 'web', value => $value };
    }

    # Hashtag
    if ($value =~ /^#(.+)/) {
        return { type => '#', value => $1 };
    }

    # Podcast types (must check before generic colon split)
    if ($value =~ /^podcast:publisher:guid:(.+)/) {
        return { type => 'podcast:publisher:guid', value => $1 };
    }
    if ($value =~ /^podcast:item:guid:(.+)/) {
        return { type => 'podcast:item:guid', value => $1 };
    }
    if ($value =~ /^podcast:guid:(.+)/) {
        return { type => 'podcast:guid', value => $1 };
    }

    # Simple prefixed types: isbn, geo, iso3166, isan, doi
    if ($value =~ /^(isbn|geo|iso3166|isan|doi):(.+)/) {
        return { type => $1, value => $2 };
    }

    # Blockchain with chain_id: <chain>:<chainId>:<tx|address>:<value>
    if ($value =~ /^(\w+):(\d+):(tx|address):(.+)/) {
        return {
            type       => "$1:$3",
            value      => $4,
            blockchain => $1,
            chain_id   => int($2),
        };
    }

    # Blockchain without chain_id: <chain>:<tx|address>:<value>
    if ($value =~ /^(\w+):(tx|address):(.+)/) {
        return {
            type       => "$1:$2",
            value      => $3,
            blockchain => $1,
            chain_id   => undef,
        };
    }

    return undef;
}

# Derive the k tag value from an i tag value

sub kind_for {
    my ($class, $value) = @_;
    my $parsed = $class->parse($value);
    return undef unless $parsed;
    return $parsed->{type};
}

1;

__END__


=head1 NAME

Net::Nostr::ExternalId - NIP-73 External Content IDs

=head1 SYNOPSIS

    use Net::Nostr::ExternalId;

    # Build i/k tag pairs for an event
    my ($i, $k) = Net::Nostr::ExternalId->url_tags(
        'https://myblog.example.com/post/2012-03-27/hello-world',
    );
    # $i = ['i', 'https://myblog.example.com/post/2012-03-27/hello-world']
    # $k = ['k', 'web']

    my ($i, $k) = Net::Nostr::ExternalId->isbn_tags('978-0-7653-8203-0');
    # $i = ['i', 'isbn:9780765382030']  (hyphens stripped)

    my ($i, $k) = Net::Nostr::ExternalId->geo_tags('EZS42E44YX96');
    # $i = ['i', 'geo:ezs42e44yx96']  (lowercased)

    my ($i, $k) = Net::Nostr::ExternalId->country_tags('ve');
    # $i = ['i', 'iso3166:VE']  (uppercased)

    # Optional URL hint (MAY)
    my ($i, $k) = Net::Nostr::ExternalId->isan_tags(
        '0000-0000-401A-0000-7',
        hint => 'https://www.imdb.com/title/tt0120737',
    );
    # $i = ['i', 'isan:0000-0000-401A-0000-7', 'https://www.imdb.com/title/tt0120737']

    # Parse an i tag value
    my $parsed = Net::Nostr::ExternalId->parse('isbn:9780765382030');
    # { type => 'isbn', value => '9780765382030' }

    # Derive the k tag kind from an i tag value
    my $kind = Net::Nostr::ExternalId->kind_for('geo:ezs42e44yx96');
    # 'geo'

=head1 DESCRIPTION

Implements NIP-73 (External Content IDs). Provides builders for C<i>/C<k>
tag pairs that reference external content identifiers, a parser to
decompose C<i> tag values, and a helper to derive the C<k> tag kind.

C<i> tags reference external content IDs. C<k> tags represent the
external content ID kind so clients can query all events for a specific
kind.

Each builder normalizes its input per the spec requirements:

=over 4

=item * ISBN hyphens are stripped (MUST)

=item * Geohashes are lowercased (MUST)

=item * ISO 3166 codes are uppercased (MUST)

=item * DOI identifiers are lowercased

=item * Hashtag topics are lowercased

=item * URL fragments are stripped

=item * Blockchain transaction IDs are lowercased (hex)

=item * Ethereum addresses are lowercased (hex)

=back

Each C<i> tag MAY include a URL hint as an optional third element to
redirect people to a website if the client isn't opinionated about how
to interpret the id. Pass C<< hint => $url >> to any builder.

=head1 CONSTRUCTOR

=head2 new

    my $id = Net::Nostr::ExternalId->new(
        type  => 'isbn',
        value => '9780765382030',
    );

Creates a new C<Net::Nostr::ExternalId> object. Croaks on unknown
arguments.

=head1 CLASS METHODS

=head2 url_tags

    my ($i, $k) = Net::Nostr::ExternalId->url_tags($url, hint => $hint);

Returns C<i>/C<k> tag pair for a URL. Fragments are stripped per the spec.
The C<k> tag kind is C<"web">.

=head2 isbn_tags

    my ($i, $k) = Net::Nostr::ExternalId->isbn_tags($isbn, hint => $hint);

Returns C<i>/C<k> tag pair for a book ISBN. Hyphens are stripped per the
spec requirement that ISBNs MUST be referenced without hyphens. The C<k>
tag kind is C<"isbn">.

=head2 geo_tags

    my ($i, $k) = Net::Nostr::ExternalId->geo_tags($geohash, hint => $hint);

Returns C<i>/C<k> tag pair for a geohash. The value is lowercased per the
spec requirement that geohashes MUST be lowercase. The C<k> tag kind is
C<"geo">.

=head2 country_tags

    my ($i, $k) = Net::Nostr::ExternalId->country_tags($code, hint => $hint);

Returns C<i>/C<k> tag pair for an ISO 3166 country or subdivision code
(e.g. C<"VE">, C<"US-CA">). The code is uppercased per the spec
requirement that ISO 3166 codes MUST be uppercase. The C<k> tag kind is
C<"iso3166">.

=head2 isan_tags

    my ($i, $k) = Net::Nostr::ExternalId->isan_tags($isan, hint => $hint);

Returns C<i>/C<k> tag pair for a movie ISAN. ISANs SHOULD be referenced
without the version part. The C<k> tag kind is C<"isan">.

=head2 doi_tags

    my ($i, $k) = Net::Nostr::ExternalId->doi_tags($doi, hint => $hint);

Returns C<i>/C<k> tag pair for a paper DOI. The DOI is lowercased. The
C<k> tag kind is C<"doi">.

=head2 hashtag_tags

    my ($i, $k) = Net::Nostr::ExternalId->hashtag_tags($topic, hint => $hint);

Returns C<i>/C<k> tag pair for a hashtag. The topic is lowercased. The
C<i> value is prefixed with C<#>. The C<k> tag kind is C<"#">.

=head2 podcast_feed_tags

    my ($i, $k) = Net::Nostr::ExternalId->podcast_feed_tags($guid, hint => $hint);

Returns C<i>/C<k> tag pair for a podcast RSS feed GUID. The C<k> tag kind
is C<"podcast:guid">.

=head2 podcast_episode_tags

    my ($i, $k) = Net::Nostr::ExternalId->podcast_episode_tags($guid, hint => $hint);

Returns C<i>/C<k> tag pair for a podcast RSS item GUID. The C<k> tag kind
is C<"podcast:item:guid">.

=head2 podcast_publisher_tags

    my ($i, $k) = Net::Nostr::ExternalId->podcast_publisher_tags($guid, hint => $hint);

Returns C<i>/C<k> tag pair for a podcast RSS publisher GUID. The C<k> tag
kind is C<"podcast:publisher:guid">.

=head2 blockchain_tx_tags

    my ($i, $k) = Net::Nostr::ExternalId->blockchain_tx_tags(
        $blockchain, $txid, chain_id => $chain_id, hint => $hint,
    );

Returns C<i>/C<k> tag pair for a blockchain transaction. C<$blockchain>
is the chain name (e.g. C<"bitcoin">, C<"ethereum">). C<$txid> is
lowercased (hex). If C<chain_id> is provided (e.g. for Ethereum), it is
included in the identifier. The C<k> tag kind is C<"$blockchain:tx">.

=head2 blockchain_address_tags

    my ($i, $k) = Net::Nostr::ExternalId->blockchain_address_tags(
        $blockchain, $address, chain_id => $chain_id, hint => $hint,
    );

Returns C<i>/C<k> tag pair for a blockchain address. Bitcoin base58
addresses are case-sensitive; Bitcoin bech32 and Ethereum hex addresses
are lowercase. If C<chain_id> is provided, it is included in the
identifier. The C<k> tag kind is C<"$blockchain:address">.

=head2 parse

    my $parsed = Net::Nostr::ExternalId->parse($i_tag_value);

Parses an C<i> tag value and returns a hashref with C<type> (the C<k> tag
kind) and C<value> (the extracted identifier). For blockchain types,
C<blockchain> and C<chain_id> are also included. Returns C<undef> for
unrecognized formats.

=head2 kind_for

    my $kind = Net::Nostr::ExternalId->kind_for($i_tag_value);

Returns the C<k> tag kind string for a given C<i> tag value. This is a
convenience wrapper around L</parse>. Returns C<undef> for unrecognized
formats.

=head1 ACCESSORS

=head2 type

The external content ID type (C<k> tag kind value).

=head2 value

The extracted identifier value.

=head2 blockchain

The blockchain name (for blockchain types only).

=head2 chain_id

The chain ID (for blockchain types with a chain ID, e.g. Ethereum).

=head2 hint

An optional URL hint.

=head1 SEE ALSO

L<NIP-73|https://github.com/nostr-protocol/nips/blob/master/73.md>,
L<Net::Nostr>, L<Net::Nostr::Metadata>

=cut
