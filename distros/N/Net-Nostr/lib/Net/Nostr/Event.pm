package Net::Nostr::Event;

use strictures 2;

use Carp qw(croak);
use JSON;
use Digest::SHA qw(sha256_hex);
use Crypt::PK::ECC::Schnorr;

use Class::Tiny qw(
    id
    pubkey
    created_at
    kind
    tags
    content
    sig
);

sub new { # pubkey, kind, content, and sig are required
    my $class = shift;
    my $self = bless { @_ }, $class;
    croak "kind must be an integer between 0 and 65535"
        if defined $self->kind && ($self->kind < 0 || $self->kind > 65535);
    $self->created_at(time())  unless defined $self->created_at;
    $self->tags([])            unless $self->tags;
    $self->id($self->_calc_id) unless $self->id;
    return $self;
}

sub json_serialize {
    my ($self) = @_;
    my $json_serialized = JSON->new->utf8->encode([ # see how Perl is converted to JSON - https://metacpan.org/pod/JSON#PERL-%3E-JSON
        0,
        $self->pubkey . '',
        $self->created_at + 0,
        $self->kind + 0,
        $self->tags,
        $self->content . ''
    ]);
    return $json_serialized;
}

sub add_pubkey_ref {
    my ($self, $pubkey) = @_;
    $self->tags([@{$self->tags}, ['p', $pubkey]]);
}

sub add_event_ref {
    my ($self, $event_id) = @_;
    $self->tags([@{$self->tags}, ['e', $event_id]]);
}

sub to_hash {
    my ($self) = @_;
    return {
        id         => $self->id,
        pubkey     => $self->pubkey,
        created_at => $self->created_at,
        kind       => $self->kind,
        tags       => $self->tags,
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

sub d_tag {
    my ($self) = @_;
    for my $tag (@{$self->tags}) {
        return ($tag->[1] // '') if $tag->[0] eq 'd';
    }
    return '';
}

sub verify_sig {
    my ($self, $key) = @_;
    my $sig_raw = pack 'H*', $self->sig;
    my $verifier = Crypt::PK::ECC::Schnorr->new(\$key->pubkey_der);
    return $verifier->verify_message($self->id, $sig_raw);
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

    # Manual construction (e.g. when parsing from the wire)
    my $event = Net::Nostr::Event->new(
        pubkey     => $key->pubkey_hex,
        kind       => 1,
        content    => 'hello world',
        tags       => [['t', 'nostr']],
        created_at => 1700000000,
    );

    say $event->json_serialize;  # canonical JSON array for hashing
    my $hash = $event->to_hash;  # { id, pubkey, created_at, kind, tags, content, sig }

=head1 DESCRIPTION

Represents a Nostr event as defined by NIP-01. Handles canonical JSON
serialization, automatic ID computation, tag management, kind classification,
and signature verification.

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

Creates a new event. C<pubkey>, C<kind>, and C<content> are required.
C<tags> defaults to C<[]>, C<created_at> defaults to C<time()>, and C<id>
is automatically computed from the canonical serialization. If C<id> is
passed explicitly (e.g. when parsing from the wire), it is preserved as-is.
Croaks if C<kind> is outside the valid range (0-65535).

=head1 METHODS

=head2 id

    my $id = $event->id;  # '3bf0c63f...' (64-char hex)

Returns the event ID, a SHA-256 hex digest of the canonical serialization.

=head2 pubkey

    my $pubkey = $event->pubkey;

Returns the author's public key as a 64-character hex string.

=head2 created_at

    my $ts = $event->created_at;  # Unix timestamp

Returns the event creation timestamp.

=head2 kind

    my $kind = $event->kind;  # 1

Returns the event kind (integer).

=head2 tags

    my $tags = $event->tags;  # [['p', 'abc...'], ['e', 'def...']]

Returns the tags arrayref. Each tag is an arrayref of strings.

=head2 content

    my $content = $event->content;

Returns the event content string.

=head2 sig

    my $sig = $event->sig;           # get
    $event->sig($hex_signature);     # set

Gets or sets the Schnorr signature as a 128-character hex string.

=head2 json_serialize

    my $json = $event->json_serialize;

Returns the canonical JSON serialization used for ID computation:
C<[0, pubkey, created_at, kind, tags, content]>. The output is UTF-8
encoded with no extra whitespace.

=head2 to_hash

    my $hash = $event->to_hash;
    # { id => '...', pubkey => '...', created_at => 1000,
    #   kind => 1, tags => [...], content => '...', sig => '...' }

Returns a hashref with all seven event fields. Useful for JSON encoding
the full event object.

=head2 add_pubkey_ref

    $event->add_pubkey_ref('deadbeef' x 8);
    # tags now includes ['p', 'deadbeef...']

Appends a C<p> tag referencing the given pubkey hex string.

=head2 add_event_ref

    $event->add_event_ref('abcd1234' x 8);
    # tags now includes ['e', 'abcd1234...']

Appends an C<e> tag referencing the given event ID hex string.

=head2 d_tag

    my $d = $event->d_tag;  # '' if no d tag

Returns the value of the first C<d> tag, or empty string if none exists.
Used for addressable event deduplication (kinds 30000-39999).

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 30023,
        content => '', tags => [['d', 'my-article']],
    );
    say $event->d_tag;  # 'my-article'

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

=head2 verify_sig

    my $valid = $event->verify_sig($key);

Verifies the event's Schnorr signature against the given
L<Net::Nostr::Key> object. Returns true if the signature is valid.

    my $key   = Net::Nostr::Key->new;
    my $event = $key->create_event(kind => 1, content => 'signed', tags => []);
    say $event->verify_sig($key);  # 1

=head1 SEE ALSO

L<Net::Nostr>, L<Net::Nostr::Key>

=cut
