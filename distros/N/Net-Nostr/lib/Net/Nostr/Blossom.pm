package Net::Nostr::Blossom;

use strictures 2;

use Carp qw(croak);
use Digest::SHA qw(sha256_hex);
use Net::Nostr::Event;

use Class::Tiny qw(_servers);

sub new {
    my $class = shift;
    my %args = @_;
    croak "unknown argument(s): " . join(', ', sort keys %args) if %args;
    my $self = bless {}, $class;
    $self->_servers([]);
    return $self;
}

sub from_event {
    my ($class, $event) = @_;
    croak "event must be kind 10063" unless $event->kind == 10063;
    my $self = $class->new;
    for my $tag (@{$event->tags}) {
        next unless $tag->[0] eq 'server';
        push @{$self->_servers}, $tag->[1];
    }
    return $self;
}

sub add {
    my ($self, $url) = @_;
    croak "url required" unless defined $url;
    # deduplicate
    for my $existing (@{$self->_servers}) {
        return $self if $existing eq $url;
    }
    push @{$self->_servers}, $url;
    return $self;
}

sub remove {
    my ($self, $url) = @_;
    $self->_servers([grep { $_ ne $url } @{$self->_servers}]);
    return $self;
}

sub contains {
    my ($self, $url) = @_;
    for my $s (@{$self->_servers}) {
        return 1 if $s eq $url;
    }
    return 0;
}

sub count {
    my ($self) = @_;
    return scalar @{$self->_servers};
}

sub servers {
    my ($self) = @_;
    return @{$self->_servers};
}

sub to_tags {
    my ($self) = @_;
    return [map { ['server', $_] } @{$self->_servers}];
}

sub to_event {
    my ($self, %args) = @_;
    return Net::Nostr::Event->new(
        %args,
        kind    => 10063,
        content => '',
        tags    => $self->to_tags,
    );
}

sub extract_hash {
    my ($class, $url) = @_;
    if ($url =~ /([0-9a-fA-F]{64})(?:\.([a-zA-Z0-9]+))?(?:\?.*)?$/) {
        return ($1, $2);
    }
    return (undef, undef);
}

sub resolve_urls {
    my ($class, $url, $servers) = @_;
    my ($hash, $ext) = $class->extract_hash($url);
    return () unless defined $hash;

    my $path = defined $ext ? "$hash.$ext" : $hash;
    my @urls;
    for my $server (@$servers) {
        my $base = $server;
        $base =~ s{/+$}{};
        push @urls, "$base/$path";
    }
    return @urls;
}

sub verify_sha256 {
    my ($class, $data, $expected) = @_;
    return sha256_hex($data) eq lc($expected);
}

1;

__END__

=head1 NAME

Net::Nostr::Blossom - NIP-B7 Blossom media server lists

=head1 SYNOPSIS

    use Net::Nostr::Blossom;

    # Build a Blossom server list
    my $bl = Net::Nostr::Blossom->new;
    $bl->add('https://blossom.self.hosted');
    $bl->add('https://cdn.blossom.cloud');

    # Convert to a kind 10063 event for publishing
    my $event = $bl->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);
    $client->publish($event);

    # Parse from a received kind 10063 event
    my $bl = Net::Nostr::Blossom->from_event($event);
    for my $url ($bl->servers) {
        say $url;
    }

    # Extract SHA-256 hash from a Blossom URL
    my $url = "https://old-server.com/${\('a' x 64)}.png";
    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash($url);
    # $hash = 'aaa...aaa' (64 hex chars), $ext = 'png'

    # Generate alternative URLs from other Blossom servers
    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://dead-server.com/${\('a' x 64)}.png",
        ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );

    # Verify downloaded content matches expected SHA-256
    use Digest::SHA qw(sha256_hex);
    my $data = 'file contents';
    my $expected_hash = sha256_hex($data);
    Net::Nostr::Blossom->verify_sha256($data, $expected_hash);  # true

=head1 DESCRIPTION

Implements NIP-B7 Blossom media integration. Blossom is a set of standards
for dealing with servers that store files addressable by their SHA-256 hashes.

Nostr clients SHOULD fetch C<kind:10063> lists of Blossom servers for each
user. When a URL in an event ends with a 64-character hex string (with or
without a file extension) and is no longer available, clients SHOULD look up
the user's C<kind:10063> server list and try the same hash on alternative
servers.

When downloading files, clients SHOULD verify that the SHA-256 hash of the
content matches the 64-character hex string in the URL.

=head1 CONSTRUCTOR

=head2 new

    my $bl = Net::Nostr::Blossom->new;

Creates an empty Blossom server list. Croaks on unknown arguments.

=head2 from_event

    my $bl = Net::Nostr::Blossom->from_event($event);

Parses a kind 10063 event into a Blossom server list. Extracts all
C<server> tags and ignores other tag types. Croaks if the event is not
kind 10063.

    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 10063, content => '',
        tags => [['server', 'https://blossom.example.com']],
    );
    my $bl = Net::Nostr::Blossom->from_event($event);
    say $bl->count;  # 1

=head1 METHODS

=head2 add

    $bl->add($url);

Adds a Blossom server URL. If the URL already exists, it is not duplicated.
Returns C<$self> for chaining.

    $bl->add('https://server1.com')
       ->add('https://server2.com');

=head2 remove

    $bl->remove($url);

Removes the server with the given URL. No-op if not present.
Returns C<$self> for chaining.

=head2 contains

    my $bool = $bl->contains($url);

Returns true if the given server URL is in the list.

    $bl->add('https://blossom.example.com');
    say $bl->contains('https://blossom.example.com');  # 1
    say $bl->contains('https://other.com');             # 0

=head2 count

    my $n = $bl->count;

Returns the number of servers in the list.

=head2 servers

    my @urls = $bl->servers;

Returns the list of server URLs in the order they were added.

=head2 to_tags

    my $tags = $bl->to_tags;
    # [['server', 'https://blossom.self.hosted'], ['server', 'https://cdn.blossom.cloud']]

Returns the server list as an arrayref of tag arrays.

=head2 to_event

    my $event = $bl->to_event(pubkey => $pubkey_hex);
    my $event = $bl->to_event(pubkey => $pubkey_hex, created_at => time());

Creates a kind 10063 L<Net::Nostr::Event> from the server list. All extra
arguments are passed through to C<< Net::Nostr::Event->new >>. The C<kind>,
C<content>, and C<tags> fields are set automatically.

=head2 extract_hash

    my ($hash, $ext) = Net::Nostr::Blossom->extract_hash($url);

Extracts a 64-character hex string (SHA-256 hash) from a URL. Returns the
hash and optional file extension, or C<(undef, undef)> if the URL does not
contain a recognizable Blossom hash.

    my ($h, $ext) = Net::Nostr::Blossom->extract_hash(
        'https://server.com/abc123...def.png'
    );
    # $h   = 'abc123...def'  (64 hex chars)
    # $ext = 'png'

=head2 resolve_urls

    my @urls = Net::Nostr::Blossom->resolve_urls($url, \@servers);

Given a URL containing a SHA-256 hash and a list of Blossom server URLs,
generates alternative URLs by combining each server with the hash (and
optional file extension). Returns an empty list if the URL does not contain
a recognizable hash.

    my @urls = Net::Nostr::Blossom->resolve_urls(
        "https://unavailable.com/${\ ('b' x 64)}.jpg",
        ['https://blossom.self.hosted', 'https://cdn.blossom.cloud'],
    );
    # ('https://blossom.self.hosted/bbb...bbb.jpg',
    #  'https://cdn.blossom.cloud/bbb...bbb.jpg')

=head2 verify_sha256

    my $ok = Net::Nostr::Blossom->verify_sha256($data, $expected_hash);

Verifies that the SHA-256 hash of C<$data> matches C<$expected_hash>.
Returns true on match, false otherwise. Clients SHOULD call this after
downloading files from Blossom servers.

    my $data = 'file contents';
    my $hash = Digest::SHA::sha256_hex($data);
    Net::Nostr::Blossom->verify_sha256($data, $hash);   # true
    Net::Nostr::Blossom->verify_sha256('tampered', $hash);  # false

=head1 SEE ALSO

L<NIP-B7|https://github.com/nostr-protocol/nips/blob/master/B7.md>,
L<Net::Nostr>, L<Net::Nostr::Event>

=cut
