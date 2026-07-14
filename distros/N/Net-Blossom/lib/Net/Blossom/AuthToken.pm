package Net::Blossom::AuthToken;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(key action content expiration server servers), {
    hashes     => sub { [] },
    created_at => sub { time() - 1 },
};
use JSON ();
use MIME::Base64 qw(encode_base64);
use Net::Nostr::Event;
use Scalar::Util qw(blessed);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my %ACTION = map { $_ => 1 } qw(get upload list delete media);
my $JSON = JSON->new->utf8->canonical;

sub BUILDARGS {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(key action content expiration server servers hashes created_at);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    return \%args;
}

sub BUILD {
    my ($self) = @_;

    croak "key is required" unless defined $self->key;
    croak "key must provide pubkey_hex and sign_event"
        unless blessed($self->key) && $self->key->can('pubkey_hex') && $self->key->can('sign_event');
    croak "action is required" unless defined $self->action;
    croak "action must be one of get, upload, list, delete, media"
        unless $ACTION{$self->action};
    croak "content is required" unless defined $self->content && length $self->content;
    croak "expiration is required" unless defined $self->expiration;
    croak "expiration must be a non-negative integer"
        unless $self->expiration =~ /\A\d+\z/;
    croak "expiration must be in the future"
        unless $self->expiration > time;

    my @servers;
    push @servers, $self->server if defined $self->server;
    if (defined $self->servers) {
        croak "servers must be an array reference" unless ref($self->servers) eq 'ARRAY';
        push @servers, @{$self->servers};
    }
    for my $server (@servers) {
        croak "server must be a lowercase domain name"
            unless defined $server && !ref($server) && _valid_server_domain($server);
    }
    $self->servers(\@servers);

    $self->hashes([]) unless defined $self->hashes;
    croak "hashes must be an array reference" unless ref($self->hashes) eq 'ARRAY';
    for my $hash (@{$self->hashes}) {
        croak "hash must be 64-char lowercase hex"
            unless defined $hash && $hash =~ $HEX64;
    }
    croak $self->action . " authorization requires at least one hash"
        if $self->action =~ /\A(?:upload|delete|media)\z/ && !@{$self->hashes};

    $self->created_at(time() - 1) unless defined $self->created_at;
    croak "created_at must be a non-negative integer"
        unless $self->created_at =~ /\A\d+\z/;

    return;
}

sub to_event {
    my ($self) = @_;
    my @tags = (
        ['t', $self->action],
        ['expiration', '' . $self->expiration],
    );
    push @tags, map { ['server', $_] } @{$self->servers};
    push @tags, map { ['x', $_] } @{$self->hashes};

    my $event = Net::Nostr::Event->new(
        pubkey     => $self->key->pubkey_hex,
        kind       => 24242,
        created_at => $self->created_at,
        tags       => \@tags,
        content    => $self->content,
    );
    $self->key->sign_event($event);
    return $event;
}

sub authorization_header {
    my ($self) = @_;
    my $json = $JSON->encode($self->to_event->to_hash);
    my $b64 = encode_base64($json, '');
    $b64 =~ tr{+/}{-_};
    $b64 =~ s/=+\z//;
    return "Nostr $b64";
}

sub _valid_server_domain {
    my ($server) = @_;
    return length($server) <= 253
        && $server =~ /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)*\z/;
}

1;

=pod

=head1 NAME

Net::Blossom::AuthToken - BUD-11 Blossom authorization token builder

=head1 SYNOPSIS

    use Net::Blossom::AuthToken;

    my $token = Net::Blossom::AuthToken->new(
        key        => $key,
        action     => 'upload',
        content    => 'Upload Blob',
        expiration => time + 300,
        hashes     => [$sha256],
    );

    my $header = $token->authorization_header;

=head1 DESCRIPTION

C<Net::Blossom::AuthToken> builds BUD-11 Nostr authorization events and encodes
them as Blossom C<Authorization> header values.

The C<key> argument must be an object that provides C<pubkey_hex> and
C<sign_event>. C<pubkey_hex> must return the Nostr public key as lowercase
64-character hex. C<sign_event> receives the C<Net::Nostr::Event> object,
signs it, and must leave the event with a valid signature.

=head1 CONSTRUCTOR

=head2 new

    my $token = Net::Blossom::AuthToken->new(%args);

Required arguments:

=over 4

=item * C<key>

A signing object that provides C<pubkey_hex> and C<sign_event>.

=item * C<action>

One of C<get>, C<upload>, C<list>, C<delete>, or C<media>.

=item * C<content>

The event content string.

=item * C<expiration>

Unix timestamp. It must be a non-negative integer and must be in the future.

=back

Optional arguments:

=over 4

=item * C<server>

A lowercase DNS-style domain name for one server scope. This is a domain only,
not a URL. Empty labels and leading or trailing label hyphens are rejected.

=item * C<servers>

Array reference of lowercase DNS-style domain names for server scope.

=item * C<hashes>

Array reference of lowercase 64-character SHA-256 hashes. C<upload>,
C<delete>, and C<media> authorizations require at least one hash.

=item * C<created_at>

Unix timestamp for the Nostr event. Defaults to the previous Unix second.

=back

Unknown arguments or invalid values croak.

=head1 ACCESSORS

=head2 key

Returns the signing object passed to C<new>.

=head2 action

Returns the BUD-11 action.

=head2 content

Returns the event content.

=head2 expiration

Returns the expiration timestamp.

=head2 server

Returns the original C<server> argument, when one was passed.

=head2 servers

Returns the normalized array reference of server domain names.

=head2 hashes

Returns the array reference of hash scopes.

=head2 created_at

Returns the event creation timestamp.

=head1 METHODS

=head2 to_event

    my $event = $token->to_event;

Builds, signs, and returns a C<Net::Nostr::Event> for kind C<24242>.

=head2 authorization_header

    my $header = $token->authorization_header;

Returns the C<Nostr ...> C<Authorization> header value. The payload is canonical
JSON encoded as unpadded base64url.

=head1 SEE ALSO

L<Net::Blossom::Client>, L<Net::Nostr::Event>

=head1 INTERNAL METHODS

=head2 BUILDARGS

Normalizes constructor arguments for Class::Tiny.

=head2 BUILD

Validates the constructed object for Class::Tiny.

=cut
