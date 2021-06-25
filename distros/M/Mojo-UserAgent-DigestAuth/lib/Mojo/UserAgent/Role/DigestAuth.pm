package Mojo::UserAgent::Role::DigestAuth;
use Mojo::Base -role;

use Mojo::Util qw(md5_sum);
use constant DEBUG => $ENV{MOJO_USERAGENT_DIGEST_AUTH_DEBUG} || 0;

my $NC = 0;

around start => sub {
  my ($next, $self, $tx, $cb) = @_;

  my %auth;
  @auth{qw(username password)} = split ':', $tx->req->url->userinfo || '';

  if (my $client_nonce = $tx->req->headers->header('D-Client-Nonce')) {
    $auth{client_nonce} = $client_nonce;
    $tx->req->headers->remove('D-Client-Nonce');
  }

  $tx->req->url($tx->req->url->clone)->url->userinfo(undef);
  warn "[DigestAuth] url=@{[$tx->req->url]}\n" if DEBUG;

  # Blocking
  unless ($cb) {
    my $next_tx = $self->_digest_auth_build_next_tx($self->$next($tx), \%auth);
    return $next_tx eq $tx ? $tx : $self->$next($next_tx);
  }

  # Non-blocking
  return $self->$next(
    $tx => sub {
      my ($self, $tx) = @_;
      my $next_tx = $self->_digest_auth_build_next_tx($tx, \%auth);
      return $next_tx eq $tx ? $self->$cb($tx) : $self->$next($next_tx, $cb);
    }
  );
};

sub _digest_auth_build_next_tx {
  my ($self, $tx, $auth) = @_;
  my $code = $tx->res->code || '';
  warn "[DigestAuth] code=$code\n" if DEBUG;

  # Return unless we got a digest auth response
  return $tx
    unless 3 == grep { defined $_ } @$auth{qw(username password)}, $tx->res->headers->header('WWW-Authenticate');

  # Build a new transaction
  warn "[DigestAuth] Digest authorization...\n" if DEBUG;
  my $next_tx = Mojo::Transaction::HTTP->new(req => $tx->req->clone);
  $next_tx->req->headers->authorization(sprintf 'Digest %s', join ', ', $self->_digest_auth_kv($tx, $auth));
  $next_tx->req->headers->accept('*/*');
  $next_tx->req->body($tx->req->body);
  return $next_tx;
}

sub _digest_auth_clean_tx {
  my ($self, $tx) = @_;
  return $tx;
}

sub _digest_auth_kv {
  my ($self, $tx, $args) = @_;
  my %auth_param = $tx->res->headers->header('WWW-Authenticate') =~ /(\w+)="?([^",]+)"?/g;
  my $nc = sprintf '%08X', ++$NC;
  my ($ha1, $ha2, $response);

  $auth_param{client_nonce} = $args->{client_nonce} // _generate_nonce(time);
  $auth_param{nonce} //= '__UNDEF__';
  $auth_param{realm} //= '';

  $ha1 = _generate_ha1(\%auth_param, @$args{qw( username password )});
  $ha2 = _generate_ha2(\%auth_param, $tx->req);

  if ($auth_param{qop} and $auth_param{qop} =~ /^auth/) {
    $response = md5_sum join ':', $ha1, $auth_param{nonce}, $nc, $auth_param{client_nonce}, $auth_param{qop}, $ha2;
    warn "RESPONSE: MD5($ha1:$auth_param{nonce}:$nc:$auth_param{client_nonce}:$auth_param{qop}:$ha2) = $response\n"
      if DEBUG;
  }
  else {
    $response = md5_sum join ':', $ha1, $auth_param{nonce}, $ha2;
    warn "RESPONSE: MD5($ha1:$auth_param{nonce}:$ha2) = $response\n" if DEBUG;
  }

  return (
    qq(username="$args->{username}"),                              qq(realm="$auth_param{realm}"),
    qq(nonce="$auth_param{nonce}"),                                qq(uri="@{[$tx->req->url->path]}"),
    $auth_param{qop} ? ("qop=$auth_param{qop}") : (),              "nc=$nc",
    qq(cnonce="$auth_param{client_nonce}"),                        qq(response="$response"),
    $auth_param{opaque} ? (qq(opaque="$auth_param{opaque}")) : (), qq(algorithm="MD5"),
  );
}

sub _generate_nonce {
  my $time  = shift;
  my $nonce = Mojo::Util::b64_encode(join ' ', $time, Mojo::Util::hmac_sha1_sum($time), '');
  chomp $nonce;
  $nonce =~ s!=+$!!;
  return $nonce;
}

sub _generate_ha1 {
  my ($auth_param, $username, $password) = @_;
  my $res;

  if (!$auth_param->{algorithm} or $auth_param->{algorithm} eq 'MD5') {
    $res = md5_sum join ':', $username, $auth_param->{realm}, $password;
    warn "HA1: MD5($username:$auth_param->{realm}:$password) = $res\n" if DEBUG;
  }
  else {
    $res = md5_sum md5_sum(join ':', $username, $auth_param->{realm}, $password), $auth_param->{nonce},
      $auth_param->{client_nonce};
    warn
      "HA1: MD5(MD5($username:$auth_param->{realm}:$password), $auth_param->{nonce}, $auth_param->{client_nonce}) = $res\n"
      if DEBUG;
  }

  return $res;
}

sub _generate_ha2 {
  my ($auth_param, $req) = @_;
  my $method = uc $req->method;
  my $res;

  if (!$auth_param->{qop} or $auth_param->{qop} eq 'auth') {
    $res = md5_sum join ':', $method, $req->url->path;
    warn "HA2: MD5($method:@{[$req->url->path]}) = $res\n" if DEBUG;
  }
  else {
    $res = md5_sum join ':', $method, $req->url->path, md5_sum('entityBody');    #  TODO: entityBody
    warn "HA2: MD5(TODO) = $res\n" if DEBUG;
  }

  return $res;
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::DigestAuth - Allow Mojo::UserAgent to execute digest auth requests

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::DigestAuth> is a L<Mojo::UserAgent> role that can
handle 401 digest auth responses from the server.

See L<http://en.wikipedia.org/wiki/Digest_access_authentication>.

=head1 SYNOPSIS

  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->with_roles('+DigestAuth')->new;

  # blocking
  $tx = $ua->get($url);

  # non-blocking
  $ua = $ua->start($ua->build_tx($method, $url, $headers, $cb));
  $ua = $ua->post($method, $url, $cb);

  # promise based
  $p = $ua->post_p($method, $url)->then(sub { ... });

A custom client nonce can be specified by using a special "D-Client-Nonce"
header. This is a hack to work around servers which does not understand the
nonce generated by this module.

Note that this feature is EXPERIMENTAL and might be removed once I figure
out why the random nonce L<does not work|https://github.com/jhthorsen/mojo-useragent-digestauth/issues/1>
for all servers.

  $tx = $ua->get('http://example.com', { 'D-Client-Nonce' => '0e163838ccd62299' });

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2021, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

