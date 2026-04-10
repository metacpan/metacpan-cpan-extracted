package Net::Nostr::Wallet;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Net::Nostr::Event;

use Class::Tiny qw(
    privkey
    mints
    mint
    unit
    proofs
    del
    direction
    amount
    e_tags
    redeemed_ids
    mint_url
    expiration
);

my $json = JSON->new->utf8->canonical;
my $HEX64 = qr/\A[0-9a-f]{64}\z/;

sub new {
    my $class = shift;
    my %args = @_;
    $args{mints}        //= [];
    $args{proofs}       //= [];
    $args{del}          //= [];
    $args{e_tags}       //= [];
    $args{redeemed_ids} //= [];
    my $self = bless \%args, $class;
    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;
    return $self;
}

# === Event creation ===

sub wallet_event {
    my ($class, %args) = @_;

    my $pubkey  = $args{pubkey}  // croak "wallet_event requires 'pubkey'";
    my $content = $args{content} // croak "wallet_event requires 'content'";

    delete @args{qw(content)};
    return Net::Nostr::Event->new(%args, kind => 17375, content => $content, tags => []);
}

sub token_event {
    my ($class, %args) = @_;

    my $pubkey  = $args{pubkey}  // croak "token_event requires 'pubkey'";
    my $content = $args{content} // croak "token_event requires 'content'";

    delete @args{qw(content)};
    return Net::Nostr::Event->new(%args, kind => 7375, content => $content, tags => []);
}

sub history_event {
    my ($class, %args) = @_;

    my $pubkey       = $args{pubkey}       // croak "history_event requires 'pubkey'";
    my $content      = $args{content}      // croak "history_event requires 'content'";
    my $redeemed_ids = $args{redeemed_ids} // [];

    my @tags;
    for my $entry (@$redeemed_ids) {
        croak "redeemed event_id must be 64-char lowercase hex" unless $entry->[0] =~ $HEX64;
        push @tags, ['e', $entry->[0], $entry->[1] // '', 'redeemed'];
    }

    delete @args{qw(content redeemed_ids)};
    return Net::Nostr::Event->new(%args, kind => 7376, content => $content, tags => \@tags);
}

sub quote_event {
    my ($class, %args) = @_;

    my $pubkey     = $args{pubkey}     // croak "quote_event requires 'pubkey'";
    my $content    = $args{content}    // croak "quote_event requires 'content'";
    my $mint_url   = $args{mint_url}   // croak "quote_event requires 'mint_url'";
    my $expiration = $args{expiration} // croak "quote_event requires 'expiration'";

    my @tags = (
        ['expiration', '' . $expiration],
        ['mint', $mint_url],
    );

    delete @args{qw(content mint_url expiration)};
    return Net::Nostr::Event->new(%args, kind => 7374, content => $content, tags => \@tags);
}

sub delete_token {
    my ($class, %args) = @_;

    my $pubkey    = $args{pubkey}    // croak "delete_token requires 'pubkey'";
    my $event_ids = $args{event_ids} // croak "delete_token requires 'event_ids'";

    my @tags;
    for my $id (@$event_ids) {
        croak "event_id must be 64-char lowercase hex" unless $id =~ $HEX64;
        push @tags, ['e', $id];
    }
    push @tags, ['k', '7375'];

    delete @args{qw(event_ids)};
    return Net::Nostr::Event->new(%args, kind => 5, content => '', tags => \@tags);
}

# === Content builders (return JSON for NIP-44 encryption) ===

sub wallet_content {
    my ($class, %args) = @_;

    my $privkey = $args{privkey} // croak "wallet_content requires 'privkey'";
    my $mints   = $args{mints}   // croak "wallet_content requires 'mints'";
    croak "wallet_content requires one or more mints" unless @$mints;

    my @data = (['privkey', $privkey]);
    for my $url (@$mints) {
        push @data, ['mint', $url];
    }
    return $json->encode(\@data);
}

sub token_content {
    my ($class, %args) = @_;

    my $mint   = $args{mint}   // croak "token_content requires 'mint'";
    my $proofs = $args{proofs} // croak "token_content requires 'proofs'";
    my $unit   = $args{unit}   // 'sat';

    my %data = (
        mint   => $mint,
        unit   => $unit,
        proofs => $proofs,
    );
    $data{del} = $args{del} if defined $args{del};

    return $json->encode(\%data);
}

sub history_content {
    my ($class, %args) = @_;

    my $direction = $args{direction} // croak "history_content requires 'direction'";
    my $amount    = $args{amount}    // croak "history_content requires 'amount'";
    my $unit      = $args{unit}      // 'sat';
    my $e_tags    = $args{e_tags}    // croak "history_content requires 'e_tags'";

    my @data = (
        ['direction', $direction],
        ['amount', '' . $amount],
        ['unit', $unit],
    );
    for my $e (@$e_tags) {
        push @data, ['e', @$e];
    }
    return $json->encode(\@data);
}

# === Content parsers (accept decrypted JSON) ===

sub parse_wallet_content {
    my ($class, $plaintext) = @_;
    my $data = $json->decode($plaintext);

    my ($privkey, @mints);
    for my $tag (@$data) {
        if ($tag->[0] eq 'privkey') {
            $privkey = $tag->[1];
        } elsif ($tag->[0] eq 'mint') {
            push @mints, $tag->[1];
        }
    }

    return $class->new(
        privkey => $privkey,
        mints   => \@mints,
    );
}

sub parse_token_content {
    my ($class, $plaintext) = @_;
    my $data = $json->decode($plaintext);

    return $class->new(
        mint   => $data->{mint},
        unit   => $data->{unit} // 'sat',
        proofs => $data->{proofs} // [],
        del    => $data->{del} // [],
    );
}

sub parse_history_content {
    my ($class, $plaintext) = @_;
    my $data = $json->decode($plaintext);

    my ($direction, $amount, $unit, @e_tags);
    for my $tag (@$data) {
        if ($tag->[0] eq 'direction') {
            $direction = $tag->[1];
        } elsif ($tag->[0] eq 'amount') {
            $amount = $tag->[1];
        } elsif ($tag->[0] eq 'unit') {
            $unit = $tag->[1];
        } elsif ($tag->[0] eq 'e') {
            push @e_tags, [@{$tag}[1 .. $#$tag]];
        }
    }

    return $class->new(
        direction => $direction,
        amount    => $amount,
        unit      => $unit // 'sat',
        e_tags    => \@e_tags,
    );
}

# === Event parsing ===

sub from_event {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 17375) {
        return $class->new;
    } elsif ($kind == 7375) {
        return $class->new;
    } elsif ($kind == 7376) {
        return $class->_parse_history_event($event);
    } elsif ($kind == 7374) {
        return $class->_parse_quote_event($event);
    }
    return undef;
}

sub _parse_history_event {
    my ($class, $event) = @_;
    my @redeemed_ids;

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'e' && defined $tag->[3] && $tag->[3] eq 'redeemed') {
            push @redeemed_ids, $tag->[1];
        }
    }

    return $class->new(redeemed_ids => \@redeemed_ids);
}

sub _parse_quote_event {
    my ($class, $event) = @_;
    my ($mint_url, $expiration);

    for my $tag (@{$event->tags}) {
        if ($tag->[0] eq 'mint') {
            $mint_url //= $tag->[1];
        } elsif ($tag->[0] eq 'expiration') {
            $expiration //= $tag->[1];
        }
    }

    return $class->new(
        mint_url   => $mint_url,
        expiration => $expiration,
    );
}

# === Validation ===

sub validate {
    my ($class, $event) = @_;
    my $kind = $event->kind;

    if ($kind == 17375) {
        return 1; # content is encrypted, can't validate structure
    } elsif ($kind == 7375) {
        return 1; # content is encrypted
    } elsif ($kind == 7376) {
        return 1; # content is encrypted, public tags optional
    } elsif ($kind == 7374) {
        my ($has_exp, $has_mint);
        for my $tag (@{$event->tags}) {
            $has_exp  = 1 if $tag->[0] eq 'expiration';
            $has_mint = 1 if $tag->[0] eq 'mint';
        }
        croak "kind 7374 MUST have an expiration tag" unless $has_exp;
        croak "kind 7374 MUST have a mint tag" unless $has_mint;
        return 1;
    }

    croak "wallet event MUST be kind 17375, 7375, 7376, or 7374";
}

1;

__END__

=head1 NAME

Net::Nostr::Wallet - NIP-60 Cashu wallet state management

=head1 SYNOPSIS

    use Net::Nostr::Wallet;

    my $pubkey = 'aa' x 32;

    # Build wallet content (plaintext for NIP-44 encryption)
    my $wallet_plaintext = Net::Nostr::Wallet->wallet_content(
        privkey => 'bb' x 32,
        mints   => ['https://mint1', 'https://mint2'],
    );

    # Create wallet event (kind 17375) with pre-encrypted content
    my $wallet_ev = Net::Nostr::Wallet->wallet_event(
        pubkey  => $pubkey,
        content => $encrypted_wallet,  # NIP-44 encrypted
    );

    # Build token content (plaintext for NIP-44 encryption)
    my $token_plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://stablenut.umint.cash',
        unit   => 'sat',
        proofs => [
            {
                id     => '005c2502034d4f12',
                amount => 1,
                secret => 'z+zyxAVLRqN9lEjxuNPSyRJzEstbl69Jc1vtimvtkPg=',
                C      => '0241d98a8197ef238a192d47edf191a9de78b657308937b4f7dd0aa53beae72c46',
            },
        ],
        del => ['old-token-event-id'],
    );

    # Create token event (kind 7375)
    my $token_ev = Net::Nostr::Wallet->token_event(
        pubkey  => $pubkey,
        content => $encrypted_token,  # NIP-44 encrypted
    );

    # Build history content
    my $history_plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        unit      => 'sat',
        e_tags    => [
            ['event-id-1', '', 'destroyed'],
            ['event-id-2', '', 'created'],
        ],
    );

    # Create history event (kind 7376) with unencrypted redeemed e tags
    my $history_ev = Net::Nostr::Wallet->history_event(
        pubkey       => $pubkey,
        content      => $encrypted_history,  # NIP-44 encrypted
        redeemed_ids => [['nutzap-id', 'wss://relay']],
    );

    # Create quote event (kind 7374, optional)
    my $quote_ev = Net::Nostr::Wallet->quote_event(
        pubkey     => $pubkey,
        content    => $encrypted_quote_id,  # NIP-44 encrypted
        mint_url   => 'https://mint1',
        expiration => time() + 2 * 7 * 86400,  # ~2 weeks
    );

    # Delete spent token (NIP-09 with k:7375 tag)
    my $delete_ev = Net::Nostr::Wallet->delete_token(
        pubkey    => $pubkey,
        event_ids => ['spent-token-event-id'],
    );

    # Parse decrypted content
    my $wallet = Net::Nostr::Wallet->parse_wallet_content($decrypted);
    say $wallet->privkey;
    say join ', ', @{$wallet->mints};

    my $token = Net::Nostr::Wallet->parse_token_content($decrypted);
    say $token->mint;
    say scalar @{$token->proofs};

    my $hist = Net::Nostr::Wallet->parse_history_content($decrypted);
    say $hist->direction;  # 'in' or 'out'
    say $hist->amount;

    # Parse event public tags
    my $parsed = Net::Nostr::Wallet->from_event($event);

=head1 DESCRIPTION

Implements NIP-60 Cashu wallet state management over Nostr. A Cashu wallet
stores its state in relay events so it is accessible across applications.

Four event kinds are involved:

=over

=item B<kind 17375> - Wallet event (replaceable). Contains NIP-44 encrypted
wallet private key and trusted mint URLs. The private key is used exclusively
for P2PK ecash operations and MUST NOT be the user's Nostr private key.

=item B<kind 7375> - Token event. Contains NIP-44 encrypted unspent Cashu
proofs. Multiple token events can exist per mint, and each can hold multiple
proofs. When proofs are spent, the token event MUST be NIP-09 deleted and
unspent proofs rolled over into a new token event.

=item B<kind 7376> - Spending history event. Records balance changes with
direction, amount, and event references. Clients SHOULD publish these when
the balance changes. The C<e> tags with C<redeemed> markers SHOULD be left
unencrypted in public tags.

=item B<kind 7374> - Quote redemption event (optional). Tracks mint quote
IDs with a NIP-40 expiration of approximately two weeks. Application
developers SHOULD prefer local state when possible.

=back

All content fields are NIP-44 encrypted. This module accepts pre-encrypted
content for event creation and provides helper methods to build the plaintext
payloads and parse decrypted content.

=head1 CONSTRUCTOR

=head2 new

    my $w = Net::Nostr::Wallet->new(%fields);

Creates a new C<Net::Nostr::Wallet> object. Typically returned by
L</from_event> or the C<parse_*> methods; calling C<new> directly is
useful for testing. Croaks on unknown arguments.

=head1 CLASS METHODS

=head2 wallet_event

    my $event = Net::Nostr::Wallet->wallet_event(
        pubkey  => $hex_pubkey,
        content => $encrypted,  # NIP-44 encrypted wallet_content()
    );

Creates a kind 17375 wallet L<Net::Nostr::Event>. C<pubkey> and C<content>
are required. Tags are always empty (all data is in the encrypted content).

=head2 token_event

    my $event = Net::Nostr::Wallet->token_event(
        pubkey  => $hex_pubkey,
        content => $encrypted,  # NIP-44 encrypted token_content()
    );

Creates a kind 7375 token L<Net::Nostr::Event>. C<pubkey> and C<content>
are required. Tags are always empty.

=head2 history_event

    my $event = Net::Nostr::Wallet->history_event(
        pubkey       => $hex_pubkey,
        content      => $encrypted,  # NIP-44 encrypted history_content()
        redeemed_ids => [[$event_id, $relay_hint], ...],  # optional
    );

Creates a kind 7376 spending history L<Net::Nostr::Event>. C<pubkey> and
C<content> are required. C<redeemed_ids> is an optional arrayref of
C<[$event_id, $relay_hint]> pairs that become unencrypted C<e> tags with
the C<redeemed> marker.

=head2 quote_event

    my $event = Net::Nostr::Wallet->quote_event(
        pubkey     => $hex_pubkey,
        content    => $encrypted,  # NIP-44 encrypted quote ID
        mint_url   => 'https://mint',
        expiration => $timestamp,
    );

Creates a kind 7374 quote redemption L<Net::Nostr::Event>. All parameters
are required. The expiration should be approximately two weeks (the maximum
time a Lightning payment may be in-flight).

=head2 delete_token

    my $event = Net::Nostr::Wallet->delete_token(
        pubkey    => $hex_pubkey,
        event_ids => [$token_event_id, ...],
    );

Creates a kind 5 NIP-09 deletion L<Net::Nostr::Event> for spent token
events. Includes C<e> tags for each token and a C<["k", "7375"]> tag
as required by the spec to allow easy filtering.

=head2 wallet_content

    my $plaintext = Net::Nostr::Wallet->wallet_content(
        privkey => $hex_privkey,
        mints   => ['https://mint1', 'https://mint2'],
    );

Builds the JSON plaintext for a wallet event's content. Returns a JSON
string ready for NIP-44 encryption. C<privkey> is the P2PK private key
(not the user's Nostr key). C<mints> must have at least one entry.

=head2 token_content

    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint',
        proofs => [{ id => '...', amount => 1, secret => '...', C => '...' }],
        unit   => 'sat',             # optional, default 'sat'
        del    => ['old-token-id'],  # optional
    );

Builds the JSON plaintext for a token event's content. C<mint> and C<proofs>
are required. C<unit> defaults to C<sat>. C<del> lists token event IDs that
were destroyed in creating this token (assists with state transitions).

=head2 history_content

    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',          # 'in' or 'out'
        amount    => '4',
        unit      => 'sat',          # optional, default 'sat'
        e_tags    => [
            [$event_id, $relay_hint, $marker],
            ...
        ],
    );

Builds the JSON plaintext for a history event's content. C<direction>,
C<amount>, and C<e_tags> are required. Each C<e_tag> entry is an arrayref
of C<[$event_id, $relay_hint, $marker]> where marker is C<created>,
C<destroyed>, or C<redeemed>.

=head2 parse_wallet_content

    my $wallet = Net::Nostr::Wallet->parse_wallet_content($decrypted_json);
    say $wallet->privkey;
    say join ', ', @{$wallet->mints};

Parses decrypted wallet content into a C<Net::Nostr::Wallet> object.

=head2 parse_token_content

    my $token = Net::Nostr::Wallet->parse_token_content($decrypted_json);
    say $token->mint;
    say $token->unit;
    say scalar @{$token->proofs};
    say join ', ', @{$token->del};

Parses decrypted token content into a C<Net::Nostr::Wallet> object.
C<unit> defaults to C<sat> if not present. C<del> defaults to an empty
arrayref.

=head2 parse_history_content

    my $hist = Net::Nostr::Wallet->parse_history_content($decrypted_json);
    say $hist->direction;  # 'in' or 'out'
    say $hist->amount;
    say $hist->unit;
    for my $e (@{$hist->e_tags}) {
        say "$e->[0] ($e->[2])";  # event_id (marker)
    }

Parses decrypted history content into a C<Net::Nostr::Wallet> object.
C<unit> defaults to C<sat> if not present.

=head2 from_event

    my $parsed = Net::Nostr::Wallet->from_event($event);

Parses a kind 17375, 7375, 7376, or 7374 event into a C<Net::Nostr::Wallet>
object using only public (unencrypted) tags. For kind 7376, extracts
C<redeemed_ids> from public C<e> tags. For kind 7374, extracts C<mint_url>
and C<expiration>. Returns C<undef> for unrecognized kinds.

To access encrypted content, first decrypt the event's content with NIP-44,
then use L</parse_wallet_content>, L</parse_token_content>, or
L</parse_history_content>.

=head2 validate

    Net::Nostr::Wallet->validate($event);

Validates a wallet-related event. Croaks on invalid structure. For kinds
17375, 7375, and 7376, validation passes since content is encrypted and
public tags are optional. For kind 7374, requires C<expiration> and C<mint>
tags.

=head1 ACCESSORS

Available on objects returned by L</from_event> and the C<parse_*> methods.
Which accessors contain data depends on what was parsed.

=head2 privkey

The P2PK private key (from parsed wallet content).

=head2 mints

Arrayref of mint URLs (from parsed wallet content).

=head2 mint

The mint URL (from parsed token content).

=head2 unit

The base unit, e.g. C<sat>, C<usd> (from parsed token or history content).

=head2 proofs

Arrayref of proof hashrefs (from parsed token content).

=head2 del

Arrayref of destroyed token event IDs (from parsed token content).

=head2 direction

Transaction direction: C<in> or C<out> (from parsed history content).

=head2 amount

Transaction amount as string (from parsed history content).

=head2 e_tags

Arrayref of C<[$event_id, $relay_hint, $marker]> entries (from parsed
history content).

=head2 redeemed_ids

Arrayref of redeemed nutzap event IDs from public C<e> tags (from
L</from_event> on kind 7376).

=head2 mint_url

The mint URL from the C<mint> tag (from L</from_event> on kind 7374).

=head2 expiration

The expiration timestamp (from L</from_event> on kind 7374).

=head1 SEE ALSO

L<NIP-60|https://github.com/nostr-protocol/nips/blob/master/60.md>,
L<Net::Nostr>, L<Net::Nostr::Event>, L<Net::Nostr::Nutzap>

=cut
