package Mojo::Transmission;
use Mojo::Base -base;

use Exporter 'import';
use Mojo::JSON;
use Mojo::UserAgent;
use Mojo::Util qw(dumper url_escape);

use constant DEBUG          => $ENV{TRANSMISSION_DEBUG} || 0;
use constant RETURN_PROMISE => sub { };

our $VERSION = '0.03';
our @EXPORT_OK = qw(tr_status);

has default_trackers => sub { [split /,/, ($ENV{TRANSMISSION_DEFAULT_TRACKERS} || '')] };
has ua               => sub { Mojo::UserAgent->new; };
has url =>
  sub { Mojo::URL->new($ENV{TRANSMISSION_RPC_URL} || 'http://localhost:9091/transmission/rpc'); };

sub add {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $args) = @_;
  my $url = $args->{url} || '';

  if ($args->{xt}) {
    $url = sprintf 'magnet:?xt=%s&dn=%s', map { $_ // '' } @$args{qw(xt dn)};
    $url .= sprintf '&tr=%s', url_escape $_ for @{$args->{tr} || $self->default_trackers};
  }

  unless ($url) {
    $url = sprintf 'magnet:?xt=urn:btih:%s', $args->{hash} // '';
    $url .= sprintf '&dn=%s', url_escape($args->{dn} // '');
    $url .= sprintf '&tr=%s', url_escape $_ for @{$args->{tr} || $self->default_trackers};
  }

  $self->_post('torrent-add', {filename => "$url"}, $cb);
}

sub add_p { shift->add(shift, RETURN_PROMISE) }

sub session {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;

  return $self->_post('session-get', $_[0], $cb) if ref $_[0] eq 'ARRAY';
  return $self->_post('session-set', $_[0], $cb) if ref $_[0] eq 'HASH';
  return $self->tap($cb, {error => 'Invalid input.'}) if $cb;
  die 'Invalid input.';
}

sub session_p { shift->session(shift, RETURN_PROMISE) }

sub stats {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  return shift->_post('session-stats', {}, $cb);
}

sub stats_p { shift->_post('session-stats', {}, RETURN_PROMISE) }

sub torrent {
  my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
  my ($self, $args, $id) = @_;

  if (defined $id) {
    $id = ref $id ? $id : [$id];
  }

  if (ref $args eq 'ARRAY') {
    $args = {fields => $args};
    $args->{ids} = $id if defined $id;
    return $self->_post('torrent-get', $args, $cb);
  }
  elsif (ref $args eq 'HASH') {
    $args->{ids} = $id if defined $id;
    return $self->_post('torrent-set', $args, $cb);
  }
  elsif ($args eq 'purge') {
    return $self->_post('torrent-remove', {ids => $id, 'delete-local-data' => Mojo::JSON->true},
      $cb);
  }
  else {
    return $self->_post("torrent-$args", {ids => $id}, $cb);
  }
}

sub torrent_p { shift->torrent(@_, RETURN_PROMISE) }

sub _done {
  my ($self, $cb, $res) = @_;
  $self->$cb($res) unless $cb eq RETURN_PROMISE;
  return $res;
}

sub _post {
  my ($self, $method, $req, $cb) = @_;
  $req = {arguments => $req, method => $method};

  # Non-Blocking
  if ($cb) {
    warn '[TRANSMISSION] <<< ', dumper($req), "\n" if DEBUG;
    my $p = $self->ua->post_p($self->url, $self->_headers, json => $req)->then(sub {
      my $tx = shift;
      warn '[TRANSMISSION] >>> ', dumper($tx->res->json || $tx->res->error), "\n" if DEBUG;
      return $self->_done($cb, _res($tx)) unless ($tx->res->code // 0) == 409;
      $self->{session_id} = $tx->res->headers->header('X-Transmission-Session-Id');
      return $self->ua->post_p($self->url, $self->_headers, json => $req);
    })->then(sub {
      return $_[0] if ref $_[0] eq 'HASH';    # _done() is already called
      my $tx = shift;
      warn '[TRANSMISSION] >>> ', dumper($tx->res->json || $tx->res->error), "\n" if DEBUG;
      return $self->_done($cb, _res($tx));
    });

    return $cb eq RETURN_PROMISE ? $p : $self;
  }

  # Blocking
  else {
    warn '[TRANSMISSION] <<< ', dumper($req), "\n" if DEBUG;
    my $tx = $self->ua->post($self->url, $self->_headers, json => $req);
    warn '[TRANSMISSION] >>> ', dumper($tx->res->json || $tx->res->error), "\n" if DEBUG;
    return _res($tx) unless ($tx->res->code // 0) == 409;
    $self->{session_id} = $tx->res->headers->header('X-Transmission-Session-Id');
    $tx = $self->ua->post($self->url, $self->_headers, json => $req);
    warn '[TRANSMISSION] >>> ', dumper($tx->res->json || $tx->res->error), "\n" if DEBUG;
    return _res($tx);
  }
}

sub _headers {
  my $self = shift;
  return {'X-Transmission-Session-Id' => $self->{session_id} || ''};
}

sub _res {
  my $res = $_[0]->res->json || {error => $_[0]->res->error};
  $res->{error} ||= $res->{result};
  return $res if !$res->{result} or $res->{result} ne 'success';
  return $res->{arguments};
}

my @TR_STATUS = qw(stopped check_wait check download_wait download seed_wait seed);
sub tr_status { defined $_[0] && $_[0] >= 0 && $_[0] <= @TR_STATUS ? $TR_STATUS[$_[0]] : '' }

1;

=encoding utf8

=head1 NAME

Mojo::Transmission - Client for talking with Transmission BitTorrent daemon

=head1 DESCRIPTION

L<Mojo::Transmission> is a very lightweight client for exchanging data with
the Transmission BitTorrent daemon using RPC.

The documentation in this module might seem sparse, but that is because the API
is completely transparent regarding the data-structure received from the
L<Transmission API|https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt>.

=head1 SYNOPSIS

  my $transmission = Mojo::Transmission->new;
  $transmission->add(url => "http://releases.ubuntu.com/17.10/ubuntu-17.10.1-desktop-amd64.iso.torrent");

  my $torrents = $transmission->torrent([]);
  $transmission->torrent(remove => $torrents[0]->{id}) if @$torrents;

=head1 ATTRIBUTES

=head2 default_trackers

  $array_ref    = $transmission->default_trackers;
  $transmission = $transmission->default_trackers([$url, ...]);

Holds a list of default trackers that can be used by L</add>.

=head2 ua

  $ua           = $transmission->ua;
  $transmission = $transmission->ua(Mojo::UserAgent->new);

Holds a L<Mojo::UserAgent> used to issue requests to backend.

=head2 url

  $url          = $transmission->url;
  $transmission = $transmission->url(Mojo::URL->new);

L<Mojo::URL> object holding the URL to the transmission daemon.
Default to the C<TRANSMISSION_RPC_URL> environment variable or
"http://localhost:9091/transmission/rpc".

=head1 METHODS

=head2 add

  # Generic call
  $res          = $transmission->add(\%args);
  $transmission = $transmission->add(\%args, sub { my ($transmission, $res) = @_ });

  # magnet:?xt=${xt}&dn=${dn}&tr=${tr}
  $transmission->add({xt => "...", dn => "...", tr => [...]});

  # magnet:?xt=urn:btih:${hash}&dn=${dn}&tr=${tr}
  $transmission->add({hash => "...", dn => "...", tr => [...]});

  # Custom URL or file
  $transmission->add({url => "...", tr => [...]});

This method can be used to add a torrent. C<tr> defaults to L</default_trackers>.

See also L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt#L356>.

=head2 add_p

  $promise = $transmission->add_p(\%args);

Same as L</add>, but returns a promise.

=head2 session

  # session-get
  $transmission = $transmission->session([], sub { my ($transmission, $res) = @_; });
  $res          = $transmission->session([]);

  # session-set
  $transmission = $transmission->session(\%attrs, sub { my ($transmission, $res) = @_; });
  $res          = $transmission->session(\%attrs);

Used to get or set Transmission session arguments.

See also L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt#L444>.

=head2 session_p

  $promise = $transmission->session_p([]);
  $promise = $transmission->session_p(\%args);

Same as L</session>, but returns a promise.

=head2 stats

  # session-stats
  $transmission = $transmission->stats(sub { my ($transmission, $res) = @_; });
  $res          = $transmission->stats;

Used to retrieve Transmission statistics.

=head2 stats_p

  $promise = $transmission->stats_p;

Same as L</stats>, but returns a promise.

See also L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt#L531>.

=head2 torrent

  # torrent-get
  $transmission = $transmission->torrent(\@attrs, $id, sub { my ($transmission, $res) = @_; });
  $res          = $transmission->torrent(\@attrs, $id);

  # torrent-set
  $transmission = $transmission->torrent(\%attrs, $id, sub { my ($transmission, $res) = @_; });
  $res          = $transmission->torrent(\%attrs, $id);

  # torrent-$action
  $transmission = $transmission->torrent(remove  => $id, sub { my ($transmission, $res) = @_; });
  $transmission = $transmission->torrent(start   => $id, sub { my ($transmission, $res) = @_; });
  $transmission = $transmission->torrent(stop    => $id, sub { my ($transmission, $res) = @_; });
  $res          = $transmission->torrent($action => $id);

  # torrent-remove + delete-local-data
  $transmission = $transmission->torrent(purge => $id, sub { my ($transmission, $res) = @_; });

Used to get or set torrent related attributes or execute an action on a torrent.

C<$id> can either be a scalar or an array-ref, referring to which torrents to
use.

See also:

=over 4

=item * Get torrent attributes

L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt#L127>.

=item * Set torrent attributes

L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt#L90>

=item * Torrent actions

L<https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt#L71>.

=back

=head2 torrent_p

  $promise = $transmission->torrent_p(\@attrs, ...);
  $promise = $transmission->torrent_p(\%attrs, ...);
  $promise = $transmission->torrent_p($action => ...);

Same as L</torrent>, but returns a promise.

=head1 FUNCTIONS

=head2 tr_status

  use Mojo::Transmission "tr_status";
  $str = tr_status $int;

Returns a description for the C<$int> status:

  0 = stopped
  1 = check_wait
  2 = check
  3 = download_wait
  4 = download
  5 = seed_wait
  6 = seed

Returns empty string on invalid input.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
