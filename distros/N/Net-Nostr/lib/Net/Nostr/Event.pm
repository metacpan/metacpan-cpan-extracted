package Net::Nostr::Event;

use strictures 2;

use Carp qw(croak);
use JSON ();
use Digest::SHA qw(sha256_hex);
use Storable ();
use Crypt::PK::ECC;
use Crypt::PK::ECC::Schnorr;

# Pre-declare read-only accessors so Class::Tiny registers them as
# attributes but does not generate read-write setters.
use subs qw(id pubkey created_at kind tags content sig);

use Class::Tiny qw(
    id
    pubkey
    created_at
    kind
    tags
    content
    sig
);

# Read-only accessors for body fields (affect event ID).
# Mutation after construction would silently invalidate the ID and any
# signature, so setters are intentionally forbidden.
for my $field (qw(id pubkey created_at kind tags content)) {
    no strict 'refs';
    *$field = sub {
        my $self = shift;
        croak "$field is read-only after construction" if @_;
        return $field eq 'tags'
            ? Storable::dclone($self->{$field})
            : $self->{$field};
    };
}
my $HEX64  = qr/\A[0-9a-f]{64}\z/;
my $HEX128 = qr/\A[0-9a-f]{128}\z/;
my $JSON   = JSON->new->utf8;

# sig is the only writable field -- it does not participate in the event
# ID computation, so mutating it (e.g. after signing) is safe.
# Validates format on set; accepts undef to clear before signing.
sub sig {
    my $self = shift;
    if (@_) {
        my $val = $_[0];
        croak "sig must be 128-char lowercase hex"
            if defined $val && $val !~ $HEX128;
        $self->{sig} = $val;
        return $val;
    }
    return $self->{sig};
}

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    my %known; @known{Class::Tiny->get_all_attributes_for($class)} = ();
    my @unknown = grep { !exists $known{$_} } keys %$self;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "pubkey is required"
        unless defined $self->{pubkey};
    croak "pubkey must be 64-char lowercase hex"
        unless $self->{pubkey} =~ $HEX64;

    croak "kind is required"
        unless defined $self->{kind};
    croak "kind must be an integer between 0 and 65535"
        unless $self->{kind} =~ /\A\d+\z/ && $self->{kind} >= 0 && $self->{kind} <= 65535;

    croak "content is required"
        unless defined $self->{content};

    croak "sig must be 128-char lowercase hex"
        if defined $self->{sig} && $self->{sig} !~ $HEX128;

    croak "id must be 64-char lowercase hex"
        if defined $self->{id} && $self->{id} !~ $HEX64;

    # created_at must be a non-negative integer (unix timestamp)
    if (defined $self->{created_at}) {
        croak "created_at must be a non-negative integer"
            unless $self->{created_at} =~ /\A\d+\z/;
    }

    $self->{created_at} = time() unless defined $self->{created_at};

    # tags must be an arrayref of arrayrefs of defined strings
    if (defined $self->{tags}) {
        croak "tags must be an arrayref"
            unless ref($self->{tags}) eq 'ARRAY';
        for my $tag (@{$self->{tags}}) {
            croak "each tag must be an arrayref of strings"
                unless ref($tag) eq 'ARRAY';
            for my $elem (@$tag) {
                croak "tag elements must be defined strings"
                    unless defined $elem && !ref($elem);
            }
        }
    }
    $self->{tags} = defined $self->{tags} ? Storable::dclone($self->{tags}) : [];
    $self->{id}   = $self->_calc_id unless $self->{id};
    return $self;
}

sub from_wire {
    my ($class, $hash) = @_;
    croak "from_wire requires a hashref" unless ref($hash) eq 'HASH';

    for my $field (qw(id pubkey created_at kind tags content sig)) {
        croak "$field is required"
            unless defined $hash->{$field};
    }

    return $class->new(%$hash);
}

sub json_serialize {
    my ($self) = @_;
    return $JSON->encode([
        0,
        $self->pubkey . '',
        $self->created_at + 0,
        $self->kind + 0,
        $self->{tags},
        $self->content . ''
    ]);
}


sub to_hash {
    my ($self) = @_;
    return {
        id         => $self->id,
        pubkey     => $self->pubkey,
        created_at => $self->created_at,
        kind       => $self->kind,
        tags       => Storable::dclone($self->{tags}),
        content    => $self->content,
        sig        => $self->sig,
    };
}

sub is_regular {
    my $k = shift->kind;
    return ($k == 1 || $k == 2 || ($k >= 4 && $k < 45) || ($k >= 1000 && $k < 10000));
}

sub is_replaceable {
    my $k = shift->kind;
    return ($k == 0 || $k == 3 || ($k >= 10000 && $k < 20000));
}

sub is_ephemeral {
    my $k = shift->kind;
    return ($k >= 20000 && $k < 30000);
}

sub is_addressable {
    my $k = shift->kind;
    return ($k >= 30000 && $k < 40000);
}

sub difficulty {
    my ($self) = @_;
    my $id = $self->id;
    my $count = 0;
    for my $i (0 .. length($id) - 1) {
        my $nibble = hex(substr($id, $i, 1));
        if ($nibble == 0) {
            $count += 4;
        } else {
            # count leading zero bits in this nibble (4-bit value)
            my $bits = 0;
            for my $shift (3, 2, 1, 0) {
                last if $nibble & (1 << $shift);
                $bits++;
            }
            $count += $bits;
            last;
        }
    }
    return $count;
}

sub committed_target_difficulty {
    my ($self) = @_;
    for my $tag (@{$self->{tags}}) {
        if ($tag->[0] eq 'nonce' && defined $tag->[2]) {
            return $tag->[2] + 0;
        }
    }
    return undef;
}

sub mine {
    my ($self, $target) = @_;
    croak "target difficulty required" unless defined $target;

    # Build tags: replace existing nonce tag or add one
    my @tags = grep { $_->[0] ne 'nonce' } @{$self->{tags}};

    my $nonce = 0;
    while (1) {
        my $candidate = Net::Nostr::Event->new(
            pubkey     => $self->pubkey,
            kind       => $self->kind,
            content    => $self->content,
            tags       => [@tags, ['nonce', "$nonce", "$target"]],
            created_at => time(),
        );
        if ($candidate->difficulty >= $target) {
            return $candidate;
        }
        $nonce++;
    }
}

sub d_tag {
    my ($self) = @_;
    for my $tag (@{$self->{tags}}) {
        return ($tag->[1] // '') if $tag->[0] eq 'd';
    }
    return '';
}

sub expiration {
    my ($self) = @_;
    for my $tag (@{$self->{tags}}) {
        return $tag->[1] + 0 if $tag->[0] eq 'expiration';
    }
    return undef;
}

sub is_expired {
    my ($self, $now) = @_;
    my $exp = $self->expiration;
    return 0 unless defined $exp;
    $now //= time();
    return $now > $exp;
}

sub _tags { $_[0]->{tags} }

sub is_protected {
    my ($self) = @_;
    for my $tag (@{$self->{tags}}) {
        return 1 if $tag->[0] eq '-' && @$tag == 1;
    }
    return 0;
}

sub content_warning {
    my ($self) = @_;
    for my $tag (@{$self->{tags}}) {
        return ($tag->[1] // '') if $tag->[0] eq 'content-warning';
    }
    return undef;
}

sub has_content_warning {
    my ($self) = @_;
    return defined $self->content_warning;
}

sub content_warning_tag {
    my ($class, $reason) = @_;
    return defined $reason && $reason ne ''
        ? ['content-warning', $reason]
        : ['content-warning'];
}

sub verify_sig {
    my ($self, $key) = @_;
    croak "pubkey does not match event pubkey"
        unless $key->pubkey_hex eq $self->pubkey;
    my $sig_raw = pack 'H*', $self->sig;
    my $verifier = Crypt::PK::ECC::Schnorr->new(\$key->pubkey_der);
    return $verifier->verify_message($self->id, $sig_raw);
}

sub validate {
    my ($self) = @_;
    croak "sig is required for validation"
        unless defined $self->sig && length $self->sig;

    my $expected_id = sha256_hex($self->json_serialize);
    croak "id does not match event hash"
        unless $self->id eq $expected_id;

    my $pubkey_raw = pack 'H*', $self->pubkey;
    my $pk = Crypt::PK::ECC->new;
    $pk->import_key_raw("\x02" . $pubkey_raw, 'secp256k1');
    my $verifier = Crypt::PK::ECC::Schnorr->new(\$pk->export_key_der('public'));
    my $sig_raw = pack 'H*', $self->sig;
    croak "signature is invalid"
        unless $verifier->verify_message($self->id, $sig_raw);

    return 1;
}

sub _calc_id {
    my ($self) = @_;
    my $id = sha256_hex($self->json_serialize);
    return $id;
}

1;

__END__

=head1 NAME

Net::Nostr::Event - Nostr protocol event object

=head1 SYNOPSIS

    use Net::Nostr::Event;
    use Net::Nostr::Key;

    # Typical usage: create via Key (sets pubkey and signs automatically)
    my $key   = Net::Nostr::Key->new;
    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);
    say $event->id;   # 64-char hex sha256
    say $event->sig;  # 128-char hex signature

    # Manual construction (local builder -- defaults created_at, tags, id)
    my $event = Net::Nostr::Event->new(
        pubkey     => $key->pubkey_hex,
        kind       => 1,
        content    => 'hello world',
        tags       => [['t', 'nostr']],
        created_at => 1700000000,
    );

    # Parse from wire (strict -- all 7 fields required, no defaults)
    my $event = Net::Nostr::Event->from_wire(\%hash);

    say $event->json_serialize;  # canonical JSON array for hashing
    my $hash = $event->to_hash;  # { id, pubkey, created_at, kind, tags, content, sig }

=head1 DESCRIPTION

Represents a Nostr event as defined by NIP-01. Handles canonical JSON
serialization, automatic ID computation, kind classification, and
signature verification.

Events are B<immutable after construction>. The body fields (C<id>,
C<pubkey>, C<created_at>, C<kind>, C<tags>, C<content>) are read-only.
The only writable field is C<sig>, which does not participate in the
event ID computation. Tags are deep-copied on input and output so that
callers cannot invalidate an event through retained references. This
prevents a class of bugs where mutating a field silently invalidates the
event ID and any existing signature.

=head1 CONSTRUCTOR

=head2 new

    my $event = Net::Nostr::Event->new(
        pubkey     => $hex_pubkey,
        kind       => 1,
        content    => 'hello',
        tags       => [['p', $pubkey]],
        created_at => time(),
        sig        => $hex_sig,
    );

Strict builder for local event construction. C<pubkey>, C<kind>, and
C<content> are required. C<tags> defaults to C<[]>, C<created_at> defaults
to C<time()>, and C<id> is automatically computed from the canonical
serialization. If C<id> is passed explicitly, it is preserved as-is.

For events parsed from the wire, use L</from_wire> instead, which requires
all seven NIP-01 fields and does not apply any defaults.

Croaks if any required field is missing or if values fail format validation:

=over 4

=item * C<pubkey> must be 64-character lowercase hex

=item * C<kind> must be an integer between 0 and 65535

=item * C<content> must be defined

=item * C<sig>, if provided, must be 128-character lowercase hex

=item * C<id>, if provided, must be 64-character lowercase hex

=item * Unknown arguments are rejected

=back

=head2 from_wire

    my $event = Net::Nostr::Event->from_wire(\%hash);

Strict wire parser. Constructs an event from a hashref received over the
wire (e.g. from JSON-decoded protocol messages). All seven NIP-01 event
fields are required: C<id>, C<pubkey>, C<created_at>, C<kind>, C<tags>,
C<content>, C<sig>. No defaults are applied. Croaks if any field is
missing, undefined, or fails format validation.

This is the entry point used by L<Net::Nostr::Message/parse> for EVENT
and AUTH messages. Use L</new> for local event construction where
defaults (C<created_at>, C<tags>, C<id>) are convenient.

    my $hash = { id => '...', pubkey => '...', created_at => 1000,
                 kind => 1, tags => [], content => 'hi', sig => '...' };
    my $event = Net::Nostr::Event->from_wire($hash);

=head1 ACCESSORS

All body accessors are B<read-only>. Attempting to set them after
construction will croak. C<sig> is the only writable accessor.

=head2 id

    my $id = $event->id;  # '3bf0c63f...' (64-char hex)

Returns the event ID, a SHA-256 hex digest of the canonical serialization.
Read-only.

=head2 pubkey

    my $pubkey = $event->pubkey;

Returns the author's public key as a 64-character hex string. Read-only.

=head2 created_at

    my $ts = $event->created_at;  # Unix timestamp

Returns the event creation timestamp. Read-only.

=head2 kind

    my $kind = $event->kind;  # 1

Returns the event kind (integer). Read-only.

=head2 tags

    my $tags = $event->tags;  # [['p', 'abc...'], ['e', 'def...']]

Returns a deep copy of the tags arrayref. Each tag is an arrayref of
strings. Read-only. All tags must be provided at construction time.

Tags are deep-copied both on input (during construction) and on output
(from this accessor and L</to_hash>), so callers cannot accidentally
mutate the event's internal state through retained references.

=head2 content

    my $content = $event->content;

Returns the event content string. Read-only.

=head2 sig

    my $sig = $event->sig;           # get
    $event->sig($hex_signature);     # set

Gets or sets the Schnorr signature as a 128-character lowercase hex string.
This is the only writable field because the signature does not participate
in event ID computation. Setting C<undef> clears the signature. The setter
croaks if the value is defined but not valid 128-char lowercase hex.

=head2 json_serialize

    my $json = $event->json_serialize;

Returns the canonical JSON serialization used for ID computation:
C<[0, pubkey, created_at, kind, tags, content]>. The output is UTF-8
encoded with no extra whitespace.

=head2 to_hash

    my $hash = $event->to_hash;
    # { id => '...', pubkey => '...', created_at => 1000,
    #   kind => 1, tags => [...], content => '...', sig => '...' }

Returns a hashref with all seven event fields. The C<tags> value is a
deep copy, so mutating it will not affect the event. Useful for JSON
encoding the full event object.

=head1 METHODS

=head2 difficulty

    my $bits = $event->difficulty;  # e.g. 21

Returns the Proof of Work difficulty of the event, defined as the number of
leading zero bits in the event ID (NIP-13). For example, an ID starting with
C<000006d8> has 21 leading zero bits.

    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);
    my $mined = $event->mine(16);
    say $mined->difficulty;  # >= 16

=head2 committed_target_difficulty

    my $target = $event->committed_target_difficulty;  # e.g. 20, or undef

Returns the committed target difficulty from the C<nonce> tag's third entry
(NIP-13), or C<undef> if no nonce tag or no target is present. This allows
clients and relays to reject events where the miner committed to a lower
difficulty than required, even if the actual difficulty happens to be higher.

    my $mined = $event->mine(20);
    say $mined->committed_target_difficulty;  # 20

=head2 mine

    my $mined = $event->mine($target_difficulty);

Returns a new L<Net::Nostr::Event> with a C<nonce> tag that gives the event
at least C<$target_difficulty> leading zero bits in its ID (NIP-13). The
original event is not modified. The nonce tag's third entry records the
committed target difficulty.

The returned event is unsigned -- call C<< $key->sign_event($mined) >> to
sign it after mining.

    my $event = $key->create_event(kind => 1, content => 'hello', tags => []);
    my $mined = $event->mine(20);
    $key->sign_event($mined);
    say $mined->difficulty;  # >= 20

Existing tags are preserved. If the event already has a C<nonce> tag, it is
replaced. The C<created_at> timestamp is updated during mining.

Since the NIP-01 event ID does not commit to the signature, mining can be
delegated to a third party (delegated Proof of Work).

=head2 d_tag

    my $d = $event->d_tag;  # '' if no d tag

Returns the value of the first C<d> tag, or empty string if none exists.
Used for addressable event deduplication (kinds 30000-39999).

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 30023,
        content => '', tags => [['d', 'my-article']],
    );
    say $event->d_tag;  # 'my-article'

=head2 expiration

    my $ts = $event->expiration;  # Unix timestamp, or undef

Returns the value of the C<expiration> tag (NIP-40) as a number, or C<undef>
if the event has no expiration tag.

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => 'temp',
        tags => [['expiration', '1600000000']],
    );
    say $event->expiration;  # 1600000000

=head2 is_expired

    my $bool = $event->is_expired;
    my $bool = $event->is_expired($now);

Returns true if the event has an C<expiration> tag (NIP-40) and the
expiration time has passed. Accepts an optional Unix timestamp to compare
against (defaults to C<time()>). Returns false if there is no expiration
tag.

    if ($event->is_expired) {
        # ignore or discard the event
    }

=head2 content_warning

    my $reason = $event->content_warning;  # string, '' or undef

Returns the value of the C<content-warning> tag (NIP-36), or C<undef> if
the event has no content warning tag. Returns an empty string if the tag
is present but has no reason.

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => 'sensitive',
        tags => [['content-warning', 'spoiler']],
    );
    say $event->content_warning;  # 'spoiler'

=head2 has_content_warning

    my $bool = $event->has_content_warning;

Returns true if the event has a C<content-warning> tag (NIP-36). Clients
can use this to hide content until the user opts in.

    if ($event->has_content_warning) {
        # hide content behind a warning
    }

=head2 content_warning_tag

    my $tag = Net::Nostr::Event->content_warning_tag('spoiler');
    my $tag = Net::Nostr::Event->content_warning_tag();

Class method that creates a C<content-warning> tag arrayref, suitable for
inclusion in an event's tags. The reason is optional.

    my $event = Net::Nostr::Event->new(
        pubkey  => 'a' x 64,
        kind    => 1,
        content => 'spoiler content',
        tags    => [Net::Nostr::Event->content_warning_tag('spoiler')],
    );

=head2 is_regular

    $event->is_regular;  # true for kinds 1, 2, 4-44, 1000-9999

Returns true if the event kind is a regular (non-replaceable, non-ephemeral,
non-addressable) kind.

=head2 is_replaceable

    $event->is_replaceable;  # true for kinds 0, 3, 10000-19999

Returns true if the event kind is replaceable (only latest per pubkey+kind
is kept).

=head2 is_ephemeral

    $event->is_ephemeral;  # true for kinds 20000-29999

Returns true if the event kind is ephemeral (broadcast but never stored).

=head2 is_addressable

    $event->is_addressable;  # true for kinds 30000-39999

Returns true if the event kind is addressable (only latest per
pubkey+kind+d_tag is kept).

=head2 is_protected

    $event->is_protected;  # true if ["-"] tag is present

Returns true if the event contains a C<["-"]> tag (NIP-70). Protected
events can only be published to relays by their author. Relays MUST
reject protected events unless the client has authenticated (NIP-42) as
the event's pubkey.

=head2 validate

    $event->validate;  # croaks on failure, returns 1 on success

Full cryptographic validation: recomputes the event ID from the canonical
serialization, compares it to the stored C<id>, and verifies the Schnorr
signature against the event's own C<pubkey>. Croaks if the event is
unsigned, the ID does not match, or the signature is invalid.

This is the method callers should use to verify events received from
untrusted sources (relays, peers, files).

    my $event = Net::Nostr::Message->parse($json)->event;
    $event->validate;  # croaks if tampered or forged

=head2 verify_sig

    my $valid = $event->verify_sig($key);

Low-level signature check: verifies the Schnorr signature against the
stored C<id> using the given L<Net::Nostr::Key> object. Croaks if the
key's pubkey does not match C<< $event->pubkey >>. Does B<not> recompute
the event ID -- use L</validate> for full verification.

    my $key   = Net::Nostr::Key->new;
    my $event = $key->create_event(kind => 1, content => 'signed', tags => []);
    say $event->verify_sig($key);  # 1

=head1 SEE ALSO

L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md>,
L<NIP-36|https://github.com/nostr-protocol/nips/blob/master/36.md>,
L<NIP-40|https://github.com/nostr-protocol/nips/blob/master/40.md>,
L<Net::Nostr>, L<Net::Nostr::Key>

=cut
