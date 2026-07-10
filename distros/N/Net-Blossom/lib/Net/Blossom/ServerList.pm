package Net::Blossom::ServerList;

use strictures 2;

use Net::Blossom::_ConstructorArgs ();

use Carp qw(croak);
use Class::Tiny qw(_blossom);
use Net::Nostr::Blossom;

sub new {
    my $class = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    my %known = map { $_ => 1 } qw(servers);
    my @unknown = grep { !exists $known{$_} } keys %args;
    croak "unknown argument(s): " . join(', ', sort @unknown) if @unknown;

    croak "servers is required" unless exists $args{servers};
    croak "servers must be an array reference" unless ref($args{servers}) eq 'ARRAY';
    croak "server list requires at least one server" unless @{$args{servers}};

    my $blossom = Net::Nostr::Blossom->new(servers => $args{servers});
    return bless { _blossom => $blossom }, $class;
}

sub from_event {
    my ($class, $event) = @_;
    my $blossom = Net::Nostr::Blossom->from_event($event);
    return bless { _blossom => $blossom }, $class;
}

sub servers {
    my ($self) = @_;
    my $servers = $self->_blossom->servers;
    return $servers;
}

sub primary_server {
    my ($self) = @_;
    return $self->_blossom->primary_server;
}

sub to_tags {
    my ($self) = @_;
    return $self->_blossom->server_tags;
}

sub to_event {
    my $self = shift;
    my %args = Net::Blossom::_ConstructorArgs::normalize(@_);
    return $self->_blossom->to_event(%args);
}

sub extract_sha256 {
    my $class = shift;
    my ($sha256) = $class->extract_blob_reference(@_);
    return $sha256;
}

sub extract_blob_reference {
    my ($class, $url) = @_;
    my ($sha256, $extension) = Net::Nostr::Blossom->extract_hash($url);
    return unless defined $sha256;
    return ($sha256, $extension);
}

sub blob_urls_for {
    my ($self, $url) = @_;
    return [$self->_blossom->fallback_urls($url)];
}

1;

=pod

=head1 NAME

Net::Blossom::ServerList - BUD-03 Blossom server-list value object

=head1 SYNOPSIS

    use Net::Blossom::ServerList;

    my $list = Net::Blossom::ServerList->new(
        servers => [
            'https://cdn.example.com',
            'https://backup.example.com',
        ],
    );

    my $servers = $list->servers;

=head1 DESCRIPTION

C<Net::Blossom::ServerList> represents a user's BUD-03 list of Blossom servers.
Server order is preserved. The first server is treated as primary by helper
methods. This class is a Blossom-facing wrapper around
C<Net::Nostr::Blossom>.

=head1 CONSTRUCTORS

=head2 new

    my $list = Net::Blossom::ServerList->new(servers => \@servers);

Creates a server list from an array reference of HTTP or HTTPS base URLs. At
least one server is required. Unknown arguments or invalid server URLs croak.
Server URL validation is provided by C<Net::Nostr::Blossom>.

=head2 from_event

    my $list = Net::Blossom::ServerList->from_event($event);

Builds a server list from a kind C<10063> C<Net::Nostr::Event>. C<server> tags
are read in order. Plain hash references are not accepted; parse wire data with
C<Net::Nostr::Event> first.

=head1 METHODS

=head2 servers

    my $servers = $list->servers;

Returns a copy array reference of server base URLs. Mutating the returned array
reference does not mutate the object.

=head2 primary_server

    my $server = $list->primary_server;

Returns the first listed server.

=head2 to_tags

    my $tags = $list->to_tags;

Returns a Nostr tag array reference containing one C<server> tag per server.

=head2 to_event

    my $event = $list->to_event(%event_args);

Returns a C<Net::Nostr::Event> for kind C<10063>. Arguments are passed through
to C<Net::Nostr::Event-E<gt>new>; C<kind>, C<content>, and C<tags> are supplied
by the server list.

=head2 extract_sha256

    my $sha256 = Net::Blossom::ServerList->extract_sha256($url);

Extracts and returns the last 64-character hex SHA-256 value from C<$url>,
normalized to lowercase. Returns C<undef> when no hash is found.

=head2 extract_blob_reference

    my ($sha256, $extension) =
        Net::Blossom::ServerList->extract_blob_reference($url);

Extracts the last SHA-256 hash and an optional alphanumeric extension. Returns
an empty list when no hash is found.

=head2 blob_urls_for

    my $urls = $list->blob_urls_for($url);

Builds fallback blob URLs for every server in the list using the hash and
optional extension extracted from C<$url>. Returns an array reference. Returns an
empty array reference when C<$url> does not contain a hash.

=cut
