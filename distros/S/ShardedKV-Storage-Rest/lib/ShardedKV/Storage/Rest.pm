package ShardedKV::Storage::Rest;

use strict;
use Moose;
use Hijk;
use URI;
use Socket;

our $VERSION = '0.8';

with 'ShardedKV::Storage';

has 'url' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has 'basepath' => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => sub { my $self = shift;
                     my $uri = URI->new($self->url);
                     return $uri->path },
);

has 'connect_timeout' => (
    is => 'ro',
    isa => 'Num',
    required => 0,
    default => 2, # seconds
);

has 'read_timeout' => (
    is => 'ro',
    isa => 'Num',
    required => 0,
    default => 1, # seconds
);

sub _send_http_request {
    my ($self, $type, $key, $body) = @_;

    my $uri = URI->new($self->url . "/" . $key);

    my $response;

    eval {
        $response = Hijk::request({
            socket_cache => {}, # don't cache connections
            method => $type,
            port => $uri->port,
            path => $uri->path,
            host => $uri->host,
            read_timeout => $self->read_timeout,
            connect_timeout => $self->connect_timeout,
            $body ? (
                head => [ "Content-Type" => "application/octet-stream" ],
                body => $body)
            : (),
        });
        1;
    } or do {
        warn $@;
        return;
    };
    return $response;
}

sub get {
    my ($self, $key) = @_;

    my $response = $self->_send_http_request('GET', $key);
    my $code = $response->{status};
    return unless defined $code;

    if ($code >= 200 && $code < 300) {
        return $response->{body};
    }

    return undef;
}

sub set {
    my ($self, $key, $value_ref) = @_;

    return unless $value_ref;

    my $response = $self->_send_http_request('PUT', $key, $value_ref);
    my $code = $response->{status};
    return unless defined $code;

    if ($code >= 200 && $code < 300) {
        return 1;
    }
    return 0;
}

sub delete {
    my ($self, $key) = @_;

    my $response = $self->_send_http_request('DELETE', $key);
    my $code = $response->{status};
     return unless defined $code;

    if ($code >= 200 && $code < 300) {
        return 1;
    }
    return 0;
}

sub reset_connection {
    # noop -- hijk doesn't cache connections
}

no Moose;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ShardedKV::Storage::Rest - rest backend for ShardedKV

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Storage::Rest;
  ... create ShardedKV...
  my $storage = ShardedKV::Storage::Rest->new(
    url => 'http://localhost:679',
  );
  ... put storage into ShardedKV...
  
  # values are scalar references to strings
  $skv->set("foo", 'bar');
  my $value_ref = $skv->get("foo");


=head1 DESCRIPTION

A C<ShardedKV> storage backend that uses a remote http/rest storage.

Implements the C<ShardedKV::Storage> role.

=head1 PUBLIC ATTRIBUTES

=over 4

=head2 url

A 'http://hostname:port[/basepath]' url string pointing at the http/rest server for this shard.
Required.

=head2 basepath

The base path part of the url provided at initialization time
Read Only

=back

=head1 SEE ALSO

L<ShardedKV>
L<ShardedKV::Storage>

=head1 AUTHORS

=over 4

=item Andrea Guzzo <xant@cpan.org>

=back

=cut
