package Net::Nostr::MintDiscovery;

use strictures 2;

use Carp qw(croak);
use Net::Nostr::Event;

use Class::Tiny qw(
    identifier
    mint_kind
    urls
    mint_refs
    nuts
    modules
    network
    description
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{urls}      //= [];
    $args{mint_refs} //= [];
    $args{description} //= '';
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

sub recommendation {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "recommendation requires 'identifier'";
    my $mint_kind = delete $args{mint_kind}
        // croak "recommendation requires 'mint_kind'";
    my $content = delete $args{content} // '';
    my $urls = delete $args{urls} // [];
    my $mint_refs = delete $args{mint_refs} // [];

    my @tags;
    push @tags, ['k', $mint_kind];
    push @tags, ['d', $identifier];

    for my $u (@$urls) {
        push @tags, ['u', @$u];
    }

    for my $ref (@$mint_refs) {
        push @tags, ['a', @$ref];
    }

    return Net::Nostr::Event->new(
        %args,
        kind    => 38000,
        content => $content,
        tags    => \@tags,
    );
}

sub cashu_mint {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "cashu_mint requires 'identifier'";
    my $content = delete $args{content} // '';
    my $urls    = delete $args{urls} // [];
    my $nuts    = delete $args{nuts};
    my $network = delete $args{network};

    my @tags;
    push @tags, ['d', $identifier];

    for my $u (@$urls) {
        push @tags, ['u', $u];
    }

    push @tags, ['nuts', $nuts] if defined $nuts;
    push @tags, ['n', $network] if defined $network;

    return Net::Nostr::Event->new(
        %args,
        kind    => 38172,
        content => $content,
        tags    => \@tags,
    );
}

sub fedimint {
    my ($class, %args) = @_;

    my $identifier = delete $args{identifier}
        // croak "fedimint requires 'identifier'";
    my $content = delete $args{content} // '';
    my $urls    = delete $args{urls} // [];
    my $modules = delete $args{modules};
    my $network = delete $args{network};

    my @tags;
    push @tags, ['d', $identifier];

    for my $u (@$urls) {
        push @tags, ['u', $u];
    }

    push @tags, ['modules', $modules] if defined $modules;
    push @tags, ['n', $network] if defined $network;

    return Net::Nostr::Event->new(
        %args,
        kind    => 38173,
        content => $content,
        tags    => \@tags,
    );
}

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    return undef unless $kind == 38000 || $kind == 38172 || $kind == 38173;

    if ($kind == 38000) {
        return $class->_parse_recommendation($event);
    }

    return $class->_parse_mint($event);
}

sub _parse_recommendation {
    my ($class, $event) = @_;

    my (%attrs, @urls, @mint_refs);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'd') { $attrs{identifier} = $tag->[1] }
        elsif ($t eq 'k') { $attrs{mint_kind} = $tag->[1] }
        elsif ($t eq 'u') { push @urls, [@{$tag}[1 .. $#$tag]] }
        elsif ($t eq 'a') { push @mint_refs, [@{$tag}[1 .. $#$tag]] }
    }

    return $class->new(
        %attrs,
        urls        => \@urls,
        mint_refs   => \@mint_refs,
        description => $event->content,
    );
}

sub _parse_mint {
    my ($class, $event) = @_;

    my (%attrs, @urls);

    for my $tag (@{$event->tags}) {
        my $t = $tag->[0];
        if    ($t eq 'd')       { $attrs{identifier} = $tag->[1] }
        elsif ($t eq 'u')       { push @urls, $tag->[1] }
        elsif ($t eq 'nuts')    { $attrs{nuts} = $tag->[1] }
        elsif ($t eq 'modules') { $attrs{modules} = $tag->[1] }
        elsif ($t eq 'n')       { $attrs{network} = $tag->[1] }
    }

    return $class->new(
        %attrs,
        urls        => \@urls,
        description => $event->content,
    );
}

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    croak "mint discovery event MUST be kind 38000, 38172, or 38173"
        unless $kind == 38000 || $kind == 38172 || $kind == 38173;

    my %has;
    for my $tag (@{$event->tags}) {
        $has{$tag->[0]} = $tag->[1];
    }

    if ($kind == 38000) {
        croak "recommendation MUST have a 'd' tag" unless exists $has{d};
        croak "recommendation MUST have a 'k' tag" unless exists $has{k};
    }

    if ($kind == 38172 || $kind == 38173) {
        croak "mint info MUST have a 'd' tag" unless exists $has{d};
    }

    return 1;
}

1;

__END__


=head1 NAME

Net::Nostr::MintDiscovery - NIP-87 Ecash Mint Discoverability

=head1 SYNOPSIS

    use Net::Nostr::MintDiscovery;

    # Recommend a mint (kind 38000)
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $hex_pubkey,
        identifier => 'my-rec',
        mint_kind  => '38173',
        urls       => [['fed11abc..', 'fedimint']],
        mint_refs  => [["38173:$mint_pk:fed-id", 'wss://relay1']],
        content    => 'I trust this mint with my life',
    );

    # Cashu mint information (kind 38172)
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $hex_pubkey,
        identifier => $mint_pubkey,
        urls       => ['https://cashu.example.com'],
        nuts       => '1,2,3,4,5,6,7',
        network    => 'mainnet',
    );

    # Fedimint information (kind 38173)
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $hex_pubkey,
        identifier => $federation_id,
        urls       => ['fed11abc..', 'fed11xyz..'],
        modules    => 'lightning,wallet,mint',
        network    => 'signet',
    );

    # Parse any mint discovery event
    my $parsed = Net::Nostr::MintDiscovery->from_event($event);

    # Validate
    Net::Nostr::MintDiscovery->validate($event);

=head1 DESCRIPTION

Implements NIP-87 (Ecash Mint Discoverability). Three event kinds are
used:

=over 4

=item * B<Recommendation> (kind 38000) - A parameterized-replaceable
event recommending an ecash mint. Contains a C<k> tag indicating the
recommended mint kind (38172 or 38173), optional C<u> tags with URLs
or invite codes, and C<a> tags pointing to mint info events.

=item * B<Cashu Mint> (kind 38172) - Announces a Cashu mint's
capabilities. The C<d> tag SHOULD be the mint's pubkey. Lists
supported NUTs via a C<nuts> tag.

=item * B<Fedimint> (kind 38173) - Announces a Fedimint's
capabilities. The C<d> tag SHOULD be the federation ID. Lists invite
codes via C<u> tags and supported modules via a C<modules> tag.

=back

All three kinds are addressable.

=head1 CONSTRUCTOR

=head2 new

    my $mint = Net::Nostr::MintDiscovery->new(
        identifier => 'mint-id',
    );

Creates a new C<Net::Nostr::MintDiscovery> object. Croaks on unknown
arguments. Array fields default to C<[]>. C<description> defaults to
C<''>.

=head1 CLASS METHODS

=head2 recommendation

    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $hex_pubkey,          # required
        identifier => $id,                  # required (d tag)
        mint_kind  => '38173',              # required (k tag)
        urls       => [[$url, $type]],      # optional (u tags; $type optional)
        mint_refs  => [[$coord, $relay, $type]], # optional (a tags; $type optional)
        content    => $review,              # optional, defaults to ''
    );

Creates a kind 38000 recommendation L<Net::Nostr::Event>. The C<k> tag
indicates which mint kind is being recommended (C<38172> for Cashu,
C<38173> for Fedimint). C<urls> entries are arrayrefs of
C<[$url_or_invite]> or C<[$url_or_invite, $type]>. C<mint_refs>
entries are arrayrefs of C<[$coord, $relay_hint]> or
C<[$coord, $relay_hint, $type]>.

=head2 cashu_mint

    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $hex_pubkey,          # required
        identifier => $mint_pubkey,         # required (d tag)
        urls       => [$url],               # optional (u tags)
        nuts       => '1,2,3,4,5,6,7',     # optional (nuts tag)
        network    => 'mainnet',            # optional (n tag)
        content    => $metadata_json,       # optional, defaults to ''
    );

Creates a kind 38172 Cashu mint info L<Net::Nostr::Event>. The C<d>
tag SHOULD be the mint's pubkey (from C</v1/info>). The C<u> tag
SHOULD be the URL to the Cashu mint. C<nuts> is a comma-separated
list of supported NUT numbers. C<network> is one of C<mainnet>,
C<testnet>, C<signet>, or C<regtest>. C<content> may contain
stringified JSON metadata (kind 0 style).

=head2 fedimint

    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $hex_pubkey,          # required
        identifier => $federation_id,       # required (d tag)
        urls       => [$invite_code],       # optional (u tags)
        modules    => 'lightning,wallet',   # optional (modules tag)
        network    => 'signet',             # optional (n tag)
        content    => $metadata_json,       # optional, defaults to ''
    );

Creates a kind 38173 Fedimint info L<Net::Nostr::Event>. The C<d> tag
SHOULD be the federation ID. C<urls> lists known Fedimint invite
codes. C<modules> is a comma-separated list of supported modules.
C<network> is one of C<mainnet>, C<testnet>, C<signet>, or
C<regtest>. C<content> may contain stringified JSON metadata (kind 0
style).

=head2 from_event

    my $mint = Net::Nostr::MintDiscovery->from_event($event);

Parses a kind 38000, 38172, or 38173 event into a
C<Net::Nostr::MintDiscovery> object. Returns C<undef> for
unrecognized kinds.

=head2 validate

    Net::Nostr::MintDiscovery->validate($event);

Validates a NIP-87 event. Croaks if:

=over

=item * Kind is not 38000, 38172, or 38173

=item * Kind 38000 missing C<d> or C<k> tag

=item * Kind 38172/38173 missing C<d> tag

=back

Returns 1 on success.

=head1 ACCESSORS

=head2 identifier

The C<d> tag value. For recommendations, this is the mint event
identifier. For Cashu mints, this SHOULD be the mint's pubkey. For
Fedimints, this SHOULD be the federation ID.

=head2 mint_kind

The C<k> tag value (recommendation only). Either C<38172> or
C<38173>.

=head2 urls

For recommendations: arrayref of arrayrefs C<[$url_or_invite]> or
C<[$url_or_invite, $type]> from C<u> tags. For mint info events:
arrayref of URL/invite code strings. Defaults to C<[]>.

=head2 mint_refs

Arrayref of arrayrefs from C<a> tags (recommendation only). Each
contains C<[$coord, $relay_hint]> or C<[$coord, $relay_hint, $type]>.
Defaults to C<[]>.

=head2 nuts

Comma-separated list of supported NUT numbers (Cashu mint only).

=head2 modules

Comma-separated list of supported modules (Fedimint only).

=head2 network

Network identifier: C<mainnet>, C<testnet>, C<signet>, or
C<regtest>.

=head2 description

The event content. For recommendations, this is a review. For mint
info events, this may be stringified JSON metadata. Defaults to
C<''>.

=head1 SEE ALSO

L<NIP-87|https://github.com/nostr-protocol/nips/blob/master/87.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
