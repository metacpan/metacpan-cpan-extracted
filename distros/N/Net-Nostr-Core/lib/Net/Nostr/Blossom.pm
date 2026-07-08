package Net::Nostr::Blossom;

use strictures 2;

use Net::Nostr::_ConstructorArgs ();

use Carp qw(croak);
use Digest::SHA qw(sha256_hex);
use Net::Nostr::Event;
use Scalar::Util qw(blessed);
use URI ();

use Class::Tiny qw(_servers);

my $SERVER_LIST_KIND = 10063;
my $HEX64 = qr/\A[0-9a-fA-F]{64}\z/;

sub new {
    my $class = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);

    my $servers = delete $args{servers};
    croak "unknown argument(s): " . join(', ', sort keys %args) if %args;

    if (!defined $servers) {
        $servers = [];
    } else {
        croak "servers must be an arrayref"
            unless ref($servers) eq 'ARRAY';
    }

    my @servers = map { _validate_server_url($_) } @$servers;
    my $self = bless {}, $class;
    $self->_servers(\@servers);
    return $self;
}

sub from_event {
    my ($class, $event) = @_;

    croak "event is required"
        unless defined $event;
    croak "event must be a Net::Nostr::Event object"
        unless blessed($event) && $event->isa('Net::Nostr::Event');

    my $kind = $event->kind;
    croak "event must be kind 10063"
        unless defined $kind && !ref($kind) && $kind =~ /\A\d+\z/ && $kind == $SERVER_LIST_KIND;

    my $tags = $event->_tags;
    croak "tags must be an arrayref"
        unless ref($tags) eq 'ARRAY';

    my @servers;
    for my $tag (@$tags) {
        croak "each tag must be an arrayref"
            unless ref($tag) eq 'ARRAY';
        for my $elem (@$tag) {
            croak "tag elements must be defined strings"
                unless defined $elem && !ref($elem);
        }

        next unless @$tag && $tag->[0] eq 'server';

        croak "server tag requires a URL"
            unless defined $tag->[1] && length $tag->[1];
        push @servers, _validate_server_url($tag->[1]);
    }

    croak "kind 10063 event requires at least one server tag"
        unless @servers;

    return $class->new(servers => \@servers);
}

sub servers {
    my ($self) = @_;
    return wantarray ? @{$self->_servers} : [@{$self->_servers}];
}

sub primary_server {
    my ($self) = @_;
    return $self->_servers->[0];
}

sub server_tags {
    my ($self) = @_;
    return [map { ['server', $_] } @{$self->_servers}];
}

sub to_event {
    my $self = shift;
    my %args = Net::Nostr::_ConstructorArgs::normalize(@_);

    croak "kind 10063 event requires at least one server tag"
        unless @{$self->_servers};

    return Net::Nostr::Event->new(
        %args,
        kind    => $SERVER_LIST_KIND,
        content => '',
        tags    => $self->server_tags,
    );
}

sub extract_hash {
    my ($class, $input) = @_;
    return (undef, undef)
        unless defined $input && !ref($input);

    my ($hash, $ext);
    while ($input =~ /(?<![0-9a-fA-F])([0-9a-fA-F]{64})(?![0-9a-fA-F])(?:\.([A-Za-z0-9]+)(?=\z|[?#]))?/g) {
        ($hash, $ext) = (lc($1), $2);
    }

    return defined $hash ? ($hash, $ext) : (undef, undef);
}

sub fallback_urls {
    my ($self, $url) = @_;
    croak "fallback_urls must be called on a Net::Nostr::Blossom object"
        unless blessed($self) && $self->isa(__PACKAGE__);

    my ($hash, $ext) = __PACKAGE__->extract_hash($url);
    return () unless defined $hash;

    my $path = defined $ext ? "$hash.$ext" : $hash;
    return map {
        my $base = $_;
        $base =~ s{/+\z}{};
        "$base/$path";
    } @{$self->_servers};
}

sub verify_sha256 {
    my ($class, $data, $expected) = @_;
    croak "expected hash must be 64-char hex"
        unless defined $expected && !ref($expected) && $expected =~ $HEX64;

    return sha256_hex($data) eq lc($expected);
}

sub _validate_server_url {
    my ($url) = @_;

    croak "server url is required"
        unless defined $url && !ref($url);
    croak "server url must not contain control or space characters"
        if $url =~ /[[:cntrl:]\s]/;

    my $uri = URI->new($url);
    my $scheme = $uri->scheme;
    croak "server url must use http or https"
        unless defined $scheme && (lc($scheme) eq 'http' || lc($scheme) eq 'https');

    my $authority = $uri->authority;
    croak "server url must include an authority/host"
        unless defined $authority && length $authority;

    croak "server url must not include userinfo"
        if defined($uri->userinfo) || $authority =~ /@/;
    croak "server url must not include a query"
        if defined $uri->query;
    croak "server url must not include a fragment"
        if defined $uri->fragment;

    my $host = $uri->host;
    croak "server url must include an authority/host"
        unless defined $host && length $host;

    _validate_authority_port($authority);
    return $url;
}

sub _validate_authority_port {
    my ($authority) = @_;

    my $port;
    if ($authority =~ /\A\[[^\]]+\](?::([^:]*))?\z/) {
        $port = $1;
    } elsif ($authority =~ /\A[^:]*:(.*)\z/) {
        $port = $1;
    } else {
        croak "server url must bracket IPv6 host"
            if $authority =~ /:/;
        return;
    }

    return unless defined $port;
    croak "server url port must be between 1 and 65535"
        unless $port =~ /\A\d+\z/ && $port >= 1 && $port <= 65535;
}

1;

__END__

=head1 NAME

Net::Nostr::Blossom - strict Nostr/Blossom server-list integration helpers

=head1 SYNOPSIS

    use Net::Nostr::Blossom;

    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud',
        ],
    );

    say $bl->primary_server;  # https://blossom.self.hosted

    my $event = $bl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);
    $client->publish($event);

    my $parsed = Net::Nostr::Blossom->from_event($event);
    for my $url ($parsed->servers) {
        say $url;
    }

    my $hash = 'a' x 64;
    my ($found_hash, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://old-server.com/$hash.png"
    );

    my @fallback = $bl->fallback_urls("https://dead-server.com/$hash.png");

    use Digest::SHA qw(sha256_hex);
    my $data = 'file contents';
    my $expected_hash = sha256_hex($data);
    Net::Nostr::Blossom->verify_sha256($data, $expected_hash);  # true

=head1 DESCRIPTION

C<Net::Nostr::Blossom> implements the Nostr-facing pieces of NIP-B7 and
BUD-03: C<kind:10063> Blossom server-list events, ordered C<server> tags,
hash extraction from Blossom-like URLs, fallback URL generation, and SHA-256
content verification.

This module does not implement Blossom HTTP client behavior, server behavior,
uploads, authorization, payments, blob discovery, or other BUD APIs.

Server lists are ordered. The first server is the primary server. Duplicate
servers are preserved because BUD-03 gives ordering semantic value and does
not specify deduplication; this helper serializes the list exactly as provided
after validation.

=head1 CONSTRUCTORS

=head2 new

Accepts named arguments as either a flat list or a single hash reference.

    my $bl = Net::Nostr::Blossom->new;

    my $bl = Net::Nostr::Blossom->new(
        servers => [
            'https://blossom.self.hosted',
            'https://cdn.blossom.cloud',
        ],
    );

Creates a Blossom server list. C<servers>, when provided, must be an arrayref.
Each server URL is strictly validated. The constructor copies the list, so
later caller mutations do not change the object.

Server URLs must be HTTP or HTTPS base URLs. They must include an authority
and host, must not include userinfo, query, fragment, control characters, or
space characters, and any explicit port must be between 1 and 65535. Paths are
allowed. Bracketed IPv6 authorities are supported where L<URI> supports them.

=head2 from_event

    my $bl = Net::Nostr::Blossom->from_event($event);

Parses a C<kind:10063> L<Net::Nostr::Event> into a server list. This parser
accepts only C<Net::Nostr::Event> objects, not plain hashrefs. Hashrefs should
be parsed by L<Net::Nostr::Event> first so event validation has a single owner.

C<from_event> rejects missing events, non-event values, wrong or malformed
kinds, malformed tag lists, C<server> tags without URL values, invalid server
URLs, and events with no C<server> tags. Non-C<server> tags are ignored.

    my $event = Net::Nostr::Event->new(
        pubkey  => 'a' x 64,
        kind    => 10063,
        content => '',
        tags    => [['server', 'https://blossom.example.com']],
    );
    my $bl = Net::Nostr::Blossom->from_event($event);
    say $bl->primary_server;

=head1 METHODS

=head2 servers

    my @urls = $bl->servers;
    my $urls = $bl->servers;

Returns the server URLs in order. In list context it returns a list. In scalar
context it returns a new arrayref. Mutating the returned arrayref does not
mutate the object.

=head2 primary_server

    my $url = $bl->primary_server;

Returns the first server URL, or C<undef> for an empty list.

=head2 server_tags

    my $tags = $bl->server_tags;

Returns a new arrayref of ordered C<server> tag arrays suitable for a
C<kind:10063> event.

    # [
    #   ['server', 'https://blossom.self.hosted'],
    #   ['server', 'https://cdn.blossom.cloud'],
    # ]

=head2 to_event

    my $event = $bl->to_event(pubkey => $pubkey_hex);
    my $event = $bl->to_event(pubkey => $pubkey_hex, created_at => time());

Creates a C<kind:10063> L<Net::Nostr::Event> with empty content and ordered
C<server> tags. Extra arguments are passed through to
C<< Net::Nostr::Event->new >>, but C<kind>, C<content>, and C<tags> are always
set from the server list. Croaks if the list is empty because BUD-03 requires
at least one C<server> tag.

=head2 extract_hash

    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash($url);

Extracts the last bounded 64-character hexadecimal string from the input and
returns it lowercased with an optional alphanumeric extension. The extension
is captured only when it appears immediately after the hash as C<.ext> and is
followed by the end of the input, a query, or a fragment. Longer hex runs are
not matched.

Returns C<(undef, undef)> when no hash exists.

    my $hash = 'a' x 64;
    my ($h, $ext) = Net::Nostr::Blossom->extract_hash(
        "https://server.com/$hash.pdf?download=1"
    );
    # $h   = 'aaaa...'  (64 lowercase hex chars)
    # $ext = 'pdf'

=head2 fallback_urls

    my @urls = $bl->fallback_urls($original_url);

Extracts the hash and optional extension from C<$original_url> and generates
fallback URLs using this object's ordered servers:

    <server without trailing slash>/<hash>[.<ext>]

Returns an empty list when C<$original_url> does not contain a bounded
64-character hex hash.

    my $bl = Net::Nostr::Blossom->new(
        servers => ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );
    my @urls = $bl->fallback_urls(
        "https://unavailable.com/${\ ('b' x 64)}.jpg"
    );

=head2 verify_sha256

    my $ok = Net::Nostr::Blossom->verify_sha256($data, $expected_hash);

Computes the SHA-256 hash of C<$data> and compares it to C<$expected_hash>.
The expected hash must be a 64-character hexadecimal string; malformed
expected hashes croak. Valid but non-matching hashes return false.

    my $data = 'file contents';
    my $hash = Digest::SHA::sha256_hex($data);
    Net::Nostr::Blossom->verify_sha256($data, $hash);      # true
    Net::Nostr::Blossom->verify_sha256('tampered', $hash); # false

=head1 SEE ALSO

L<NIP-B7|https://github.com/nostr-protocol/nips/blob/master/B7.md>,
L<BUD-03|https://github.com/hzrd149/blossom/blob/master/buds/03.md>,
L<Net::Nostr::Event>

=cut
