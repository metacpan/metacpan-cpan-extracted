package Podman::Client;

use Mojo::Base -base;

our $VERSION     = '20220210.0';
our $API_VERSION = '3.0.0';

use English qw( -no_match_vars );
use Mojo::Asset::File;
use Mojo::Asset::Memory;
use Mojo::JSON qw(encode_json);
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(url_escape);

use Podman::Exception;

has 'connection_url' => sub {
  return $ENV{PODMAN_CONNECTION_URL}
    || ($UID != 0 ? "http+unix:///run/user/$UID/podman/podman.sock" : 'http+unix:///run/podman/podman.sock');
};

for my $name (qw(delete get post)) {
  Mojo::Util::monkey_patch(__PACKAGE__, $name, sub { return shift->_request(uc $name, @_); });
}

sub _base_url {
  my $self = shift;

  my $base_url = Mojo::URL->new($self->_connection_url->scheme eq 'http+unix' ? 'http://d/' : $self->connection_url);

  my $tx;
  my $url = $base_url->path('_ping');
  for (0 .. 3) {
    $tx = $self->_ua->get($url);
    last if $tx->res->is_success;
    sleep 1;
  }
  Podman::Exception->throw(900) unless $tx->res->is_success;

  $tx = $self->_ua->get($base_url->path('version'));
  my $version = $tx->res->json->{Components}->[0]->{Details}->{APIVersion};

  say {*STDERR} "Potential insufficient supported Podman service API version." if $version ne $API_VERSION;

  return $base_url->path('v' . $version . '/libpod/');
}

sub _connection_url { return Mojo::URL->new(shift->connection_url); }

sub _request {
  my ($self, $method, $path, %opts) = @_;

  my $url = $self->_base_url->path($path);
  $url->query($opts{parameters}) if $opts{parameters};

  my $tx = $self->_ua->build_tx($method => $url, $opts{headers});
  if ($opts{data}) {
    my $asset
      = ref $opts{data} eq 'Mojo::File'
      ? Mojo::Asset::File->new(path => $opts{data})
      : Mojo::Asset::Memory->new->add_chunk(encode_json($opts{data}));
    $tx->req->content->asset($asset);
  }
  $tx = $self->_ua->start($tx);

  Podman::Exception->throw($tx->res->code) unless $tx->res->is_success;

  return $tx->res;
}

sub _ua {
  my $self = shift;

  my $ua = Mojo::UserAgent->new(insecure => 1);
  $ua->transactor->name("Podman/$VERSION");
  if ($self->_connection_url->scheme eq 'http+unix') {
    $ua->proxy->http($self->_connection_url->scheme . '://' . url_escape($self->_connection_url->path));
  }

  return $ua;
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::Client - Podman service client.

=head1 SYNOPSIS

    # Send service requests
    my $client = Podman::Client->new;
    my $res = $client->delete('images/docker.io/library/hello-world');
    my $res = $client->get('version');
    my $res = $client->post('containers/prune');

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Client
        isa Mojo::UserAgent

L<Podman::Client> is a HTTP client (user agent) with the needed support to connect to and query the Podman service.

=head1 ATTRIBUTES

=head2 connection_url

    $client->connection_url('https://127.0.0.1:1234');

URL to connect to Podman service, defaults to user UNIX domain socket in rootless mode e.g.
C<http+unix://run/user/1000/podman/podman.sock> otherwise C<http+unix:///run/podman/podman.sock>. Customize via the
value of C<PODMAN_CONNECTION_URL> environment variable.

=head1 METHODS

L<Podman::Client> provides the valid HTTP requests to query the Podman service. All methods take a relative
endpoint path, optional header parameters and path parameters. if the response has a HTTP code unequal C<2xx> a
L<Podman::Exception> is raised.

=head2 delete

    my $res = $client->delete('images/docker.io/library/hello-world');

Perform C<DELETE> request and return resulting content.

=head2 get

    my $res = $client->get('version');

Perform C<GET> request and return resulting content.

=head2 post

    my $res = $client->post(
        'build',
        data       => $archive_file, # Mojo::File object
        parameters => {
            'file' => 'Dockerfile',
            't'    => 'localhost/goodbye',
        },
        headers => {
            'Content-Type' => 'application/x-tar'
        },
    );

Perform C<POST> request and return resulting content, takes additional optional request data.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
