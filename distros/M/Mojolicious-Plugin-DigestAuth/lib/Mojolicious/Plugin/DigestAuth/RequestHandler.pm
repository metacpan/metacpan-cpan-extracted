package Mojolicious::Plugin::DigestAuth::RequestHandler;

use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'weaken';

use Mojo::Util qw{quote b64_encode b64_decode};
use Mojolicious::Plugin::DigestAuth::Util qw{checksum parse_header};

my $QOP_AUTH = 'auth';
my $QOP_AUTH_INT = 'auth-int';
my %VALID_QOPS = ($QOP_AUTH => 1); #, $QOP_AUTH_INT => 1);

my $ALGORITHM_MD5 = 'MD5';
my $ALGORITHM_MD5_SESS = 'MD5-sess';
my %VALID_ALGORITHMS = ($ALGORITHM_MD5 => 1, $ALGORITHM_MD5_SESS => 1);

sub new
{
    my ($class, $config) = @_;
    my $header = {
        qop       => $config->{qop},
        realm     => $config->{realm}     || '',
        domain    => $config->{domain}    || '/',
        algorithm => $config->{algorithm} || $ALGORITHM_MD5,
    };

    # No qop = ''
    $header->{qop} = $QOP_AUTH unless defined $header->{qop}; # "$QOP_AUTH,$QOP_AUTH_INT"
    $header->{opaque} = checksum($header->{domain}, $config->{secret});

    my $self = {
        qops           => {},
        opaque         => $header->{opaque},
        secret         => $config->{secret},
        expires        => $config->{expires},
        algorithm      => $header->{algorithm},
        password_db    => $config->{password_db},
        default_header => $header,
        support_broken_browsers => $config->{support_broken_browsers}
    };

    $self->{support_broken_browsers} = 1 unless defined $self->{support_broken_browsers};

    for my $qop (split /\s*,\s*/, $header->{qop}) {
        croak "unsupported qop: $qop" unless $VALID_QOPS{$qop};
        $self->{qops}->{$qop} = 1;
    }

    croak "unsupported algorithm: $self->{algorithm}" unless $VALID_ALGORITHMS{$self->{algorithm}};
    croak "algorithm $ALGORITHM_MD5_SESS requires a qop" if $self->{algorithm} eq $ALGORITHM_MD5_SESS and ! %{$self->{qops}};

    bless $self, $class;
}

sub _request
{
    (shift)->_controller->req;
}

sub _response
{
    (shift)->_controller->res;
}

sub _controller
{
    (shift)->{controller};
}

sub _nonce_expired
{
    my ($self, $nonce) = @_;
    my $t;

    $t = ($self->_parse_nonce($nonce))[0];
    $t && (time() - int($t)) > $self->{expires};
}

sub _parse_nonce
{
    my ($self, $nonce) = @_;
    split ' ', b64_decode($nonce), 2;
}

sub _valid_nonce
{
    my ($self, $nonce) = @_;
    my ($t, $sig) = $self->_parse_nonce($nonce);

    $t && $sig && $sig eq checksum($t, $self->{secret});
}

sub _create_nonce
{
    my $self  = shift;
    my $t     = time();
    my $nonce = b64_encode(sprintf('%s %s', $t, checksum($t, $self->{secret})));
    chomp $nonce;
    $nonce;
}

sub authenticate
{
    my $self = shift;

    $self->{controller} = shift;
    weaken $self->{controller};

    $self->{response_header} = { %{$self->{default_header}} };

    my $auth = $self->_auth_header;
    if($auth) {
        my $header = parse_header($auth);
        if(!$self->_valid_header($header)) {
            $self->_bad_request;
            return;
        }

        if($self->_authorized($header)) {
            return 1 unless $self->_nonce_expired($header->{nonce});
            $self->{response_header}->{stale} = 'true';
        }
    }

    $self->_unauthorized;
    return;
}

# TODO: $self->_request->headers->proxy_authorization
sub _auth_header
{
  my $self = shift;
  $self->_request->headers->authorization or
  $self->_request->env->{'X_HTTP_AUTHORIZATION'} # Mojo does s/-/_/g
}

sub _unauthorized
{
    my $self = shift;
    my $header = $self->_build_auth_header;

    $self->_response->headers->www_authenticate($header);
    $self->_response->headers->content_type('text/plain');
    $self->_response->code(401);
    $self->_controller->render(text => 'HTTP 401: Unauthorized');
}

sub _bad_request
{
    my $self = shift;
    $self->_response->code(400);
    $self->_response->headers->content_type('text/plain');
    $self->_controller->render(text => 'HTTP 400: Bad Request');
}

sub _valid_header
{
    my ($self, $header) = @_;

    $self->_header_complete($header) &&
    $self->_url_matches($header->{uri}) &&
    $self->_valid_qop($header->{qop}, $header->{nc}) &&
    $self->_valid_opaque($header->{opaque}) &&
    $self->{algorithm} eq $header->{algorithm};
}

sub _url_matches
{
    my $self = shift;

    my $auth_url = shift;
    return unless $auth_url;
    $auth_url = _normalize_url($auth_url);

    my $req_url = $self->_url;

    if($self->_support_broken_browser) {
      # IE 5/6 do not append the querystring on GET requests
      my $i = index($req_url, '?');
      if($self->_request->method eq 'GET' && $i != -1 && index($auth_url, '?') == -1) {
          $auth_url .= '?' . substr($req_url, $i+1);
      }
    }

    $auth_url eq $req_url;
}

#
# We try to avoid using the URL provided by Mojo because:
#
# * Depending on the app's config it will not contain the URL requested by the client
#   it will contain PATH_INFO + QUERY_STRING i.e. /mojo.pl/users/sshaw?x=y will be /users/sshaw?x=y
#
# * Mojo::URL has/had several bugs and has undergone several changes that have broken backwards
#   compatibility.
#
sub _url
{
  my $self = shift;
  my $env = $self->_request->env;
  my $url;

  if($env->{REQUEST_URI}) {
    $url = $env->{REQUEST_URI};
  }
  elsif($env->{SCRIPT_NAME}) {
    $url = $env->{SCRIPT_NAME};
    $url .= $env->{PATH_INFO} if $env->{PATH_INFO};
    $url .= "?$env->{QUERY_STRING}" if $env->{QUERY_STRING};
  }
  elsif($self->_request->url) {
    $url = $self->_request->url->to_string;
  }
  else {
    $url = '/';
  }

  _normalize_url($url);
}

# We want the URL to be relative to '/'
sub _normalize_url
{
  my $s = shift;
  $s =~ s|^https?://[^/?#]*||i;
  $s =~ s|/{2,}|/|g;

  my $url = Mojo::URL->new($s);
  my @parts = @{$url->path->parts};
  my @normalized;

  for my $part (@parts) {
    if($part eq '..' && @normalized) {
      pop @normalized;
      next;
    }

    push @normalized, $part;
  }

  $url->path->parts(\@normalized);
  $url->path->leading_slash(0);
  $url->to_string;
}

# TODO (maybe): IE 6 sends a new nonce every time when using MD5-sess
sub _support_broken_browser
{
    my $self = shift;
    $self->{support_broken_browsers} && $self->_request->headers->user_agent =~ m|\bMSIE\s+[56]\.|;
}

sub _valid_qop
{
  my ($self, $qop, $nc) = @_;
  my $valid;

  #
  # Either there's no QOP from the client and we require one, or the client does not
  # send a qop because they dont support what we want (e.g., auth-int).
  #
  # And, if there's a qop, then there must be a nonce count.
  #
  if(defined $qop) {
    $valid = $self->{qops}->{$qop} && $nc;
  }
  else {
    $valid = !%{$self->{qops}} && !defined $nc;
  }

  $valid;
}

sub _valid_opaque
{
  my ($self, $opaque) = @_;

  # IE 5 & 6 only sends opaque with the initial reply but we'll just ignore it regardless
  $self->_support_broken_browser || $opaque && $opaque eq $self->{opaque};
}

sub _header_complete
{
    my ($self, $header) = @_;

    $header &&
    $header->{realm} &&
    $header->{nonce} &&
    $header->{response} &&
    $header->{algorithm} &&
    exists $header->{username};
}

sub _build_auth_header
{
    my $self   = shift;
    my $header = $self->{response_header};

    if($header->{stale} || !$header->{nonce}) {
        $header->{nonce} = $self->_create_nonce;
    }

    my %no_quote;
    @no_quote{qw{algorithm stale}} = ();

    my @auth;
    while(my ($k, $v) = each %$header) {
      next unless $v;
      $v = quote($v) unless exists $no_quote{$k};
      push @auth, "$k=$v";
    }

    'Digest ' . join(', ', @auth);
}

sub _authorized
{
    my ($self, $header) = @_;
    return unless $self->_valid_nonce($header->{nonce});

    my $a1 = $self->_compute_a1($header);
    return unless $a1;

    my @fields = ($a1, $header->{nonce});
    if($header->{qop}) {
        push @fields, $header->{nc},
                      $header->{cnonce},
                      $header->{qop},
                      $self->_compute_a2($header);
    }
    else {
        push @fields, $self->_compute_a2($header);
    }

    checksum(@fields) eq $header->{response};
}

sub _compute_a1
{
    my ($self, $header) = @_;
    my $hash = $self->{password_db}->get($header->{realm}, $header->{username});

    if($hash && $header->{algorithm} && $header->{algorithm} eq $ALGORITHM_MD5_SESS) {
        $hash = checksum($hash, $header->{nonce}, $header->{cnonce});
    }

    $hash;
}

sub _compute_a2
{
    my ($self, $header) = @_;
    my @fields = ($self->_request->method, $header->{uri});

# Not yet...
#     if(defined $header->{qop} && $header->{qop} eq $QOP_AUTH_INT) {
#         # TODO: has body been decoded?
#       push @fields, checksum($self->_request->content->headers->to_string . "\015\012\015\012" . $self->_request->body);
#     }

    checksum(@fields);
}

1;
