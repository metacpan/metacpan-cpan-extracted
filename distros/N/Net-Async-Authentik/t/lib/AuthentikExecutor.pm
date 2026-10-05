package AuthentikExecutor;

# Drives authentik's flow executor over HTTP, the way a browser would, so the
# live suite can log a user in and see what the token says about the second
# factor. Not part of the public API of WWW::Authentik: the shape of a
# challenge is authentik's own and changes between versions. The steps are in
# the design spec, section 8.3.
#
#   my $browser = AuthentikExecutor->new( base_url => $url );
#   $browser->login( username => 'alice', password => $pw );
#   my $secret = $browser->enroll_totp;
#   my $code   = $browser->authorization_code( client_id => $id, redirect_uri => $uri );

use strict;
use warnings;
use Carp qw( croak );
use Digest::SHA qw( hmac_sha1 );
use HTTP::Request;
use JSON::MaybeXS;
use LWP::UserAgent;
use URI;

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub new {
  my ( $class, %arg ) = @_;
  croak 'AuthentikExecutor needs a base_url' unless defined $arg{base_url};
  my $self = bless {
    base_url  => $arg{base_url} =~ s{/+\z}{}r,
    challenge => undef,
    ua        => $arg{ua} || LWP::UserAgent->new(
      timeout      => 30,
      agent        => 'WWW-Authentik-live-test/0.001',
      max_redirect => 0,
      # authentik hangs on every second request that announces TE; see
      # WWW::Authentik::default_ua
      send_te      => 0,
      cookie_jar   => {}
    )
  }, $class;
  return $self;
}

sub ua        { $_[0]{ua} }
sub base_url  { $_[0]{base_url} }
sub challenge { $_[0]{challenge} }
sub component { $_[0]{challenge} ? $_[0]{challenge}{component} : undef }

sub _csrf {
  my ( $self ) = @_;
  my $csrf;
  $self->{ua}->cookie_jar->scan( sub { $csrf = $_[2] if $_[1] eq 'authentik_csrf' } );
  return $csrf;
}

sub _executor_url {
  my ( $self, $flow, $query ) = @_;
  my $uri = URI->new( $self->{base_url}.'/api/v3/flows/executor/'.$flow.'/' );
  $uri->query_form( query => $query // '' );
  return $uri->as_string;
}

# one step of a flow. A 302 means "next stage": the executor sends the caller
# back to its own address, so the answer is fetched again.
sub _step {
  my ( $self, $flow, $query, $method, $answer ) = @_;
  my $url = $self->_executor_url( $flow, $query );
  for my $try ( 1 .. 6 ) {
    my $request = HTTP::Request->new( $method => $url );
    $request->header( Accept => 'application/json' );
    if ( $answer ) {
      $request->header( 'Content-Type' => 'application/json' );
      $request->header( 'X-authentik-CSRF' => $self->_csrf ) if defined $self->_csrf;
      $request->content( $JSON->encode($answer) );
    }
    my $response = $self->{ua}->request($request);
    if ( $response->code == 302 ) { $method = 'GET'; $answer = undef; next }
    croak 'the flow executor answered '.$response->status_line.' for '.$flow
      unless $response->is_success;
    my $data = eval { $JSON->decode( $response->content ) };
    croak 'the flow executor answered no JSON for '.$flow unless ref $data eq 'HASH';
    $self->{challenge} = $data;
    return $data;
  }
  croak 'the flow executor kept redirecting for '.$flow;
}

sub start  { my ( $self, $flow, $query ) = @_; $self->_step( $flow, $query, 'GET' ) }
sub submit { my ( $self, $flow, $answer, $query ) = @_; $self->_step( $flow, $query, 'POST', $answer ) }

# RFC 6238: HMAC-SHA1, six digits, a 30 second step, over a Base32 secret
sub totp {
  my ( $self, $secret ) = @_;
  my $key  = _base32($secret);
  my $step = int( time / 30 );
  my $mac  = hmac_sha1( pack( 'NN', int( $step / 4294967296 ), $step % 4294967296 ), $key );
  my $off  = ord( substr $mac, -1 ) & 0x0f;
  return sprintf '%06d', ( unpack( 'N', substr $mac, $off, 4 ) & 0x7fffffff ) % 1_000_000;
}

# authentik will not take the same TOTP code twice
sub wait_for_next_totp_window {
  my ( $self ) = @_;
  my $step = int( time / 30 );
  sleep 1 while int( time / 30 ) == $step;
  return 1;
}

sub _base32 {
  my ( $encoded ) = @_;
  my %value = map { ( split //, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567' )[$_] => $_ } 0 .. 31;
  my $bits = '';
  for my $char ( split //, uc( $encoded =~ s/=+\z//r ) ) {
    croak 'not Base32: '.$char unless exists $value{$char};
    $bits .= sprintf '%05b', $value{$char};
  }
  $bits = substr $bits, 0, length($bits) - length($bits) % 8;
  return pack 'B*', $bits;
}

sub login {
  my ( $self, %arg ) = @_;
  croak 'login needs a username and a password' unless defined $arg{username} && defined $arg{password};
  my $flow = $arg{flow} // 'default-authentication-flow';
  $self->start($flow);
  $self->submit( $flow, { component => 'ak-stage-identification', uid_field => $arg{username} } );
  $self->submit( $flow, { component => 'ak-stage-password', password => $arg{password} } );
  if ( ( $self->component // '' ) eq 'ak-stage-authenticator-validate' ) {
    croak 'the login asks for a second factor and no totp_secret was given' unless defined $arg{totp_secret};
    my $device = $self->{challenge}{device_challenges}[0]
      or croak 'the validation stage offered no device';
    my $answer = sub {
      $self->submit( $flow, {
        component          => 'ak-stage-authenticator-validate',
        code               => $self->totp( $arg{totp_secret} ),
        selected_challenge => { %$device, challenge => $device->{challenge} // {} }
      } );
    };
    $answer->();
    # authentik refuses a code that has already been used, so a login right
    # after the enrolment, or a second login in the same 30 second window,
    # is rejected with "Invalid Token". Waiting for the next window is what a
    # person does, and the only thing that helps.
    if ( ( $self->component // '' ) eq 'ak-stage-authenticator-validate' && $self->{challenge}{response_errors} ) {
      $self->wait_for_next_totp_window;
      $answer->();
    }
  }
  # with not_configured_action: deny a user without a second factor ends here
  croak 'the login was denied: '.( $self->{challenge}{error_message} // 'no reason given' )
    if ( $self->component // '' ) eq 'ak-stage-access-denied';
  croak 'the login did not finish, it stopped at '.( $self->component // 'nothing' )
    unless ( $self->component // '' ) eq 'xak-flow-redirect';
  return 1;
}

# the TOTP setup flow, which is the only way in: POST /authenticators/admin/totp/
# answers 500 in authentik 2026.8.3
sub enroll_totp {
  my ( $self, %arg ) = @_;
  my $flow = $arg{flow} // 'default-authenticator-totp-setup';
  my $challenge = $self->start($flow);
  croak 'the TOTP setup flow offered '.( $challenge->{component} // 'nothing' ).' instead of the setup stage'
    unless ( $challenge->{component} // '' ) eq 'ak-stage-authenticator-totp';
  my ( $secret ) = ( $challenge->{config_url} // '' ) =~ /[?&]secret=([^&]+)/;
  croak 'the TOTP setup stage sent no secret' unless defined $secret;
  $self->submit( $flow, { component => 'ak-stage-authenticator-totp', code => $self->totp($secret) } );
  croak 'the TOTP setup did not finish, it stopped at '.( $self->component // 'nothing' )
    unless ( $self->component // '' ) eq 'xak-flow-redirect';
  return $secret;
}

# what a browser gets back from the authorize endpoint once there is a session
sub authorization_code {
  my ( $self, %arg ) = @_;
  croak 'authorization_code needs a client_id and a redirect_uri'
    unless defined $arg{client_id} && defined $arg{redirect_uri};
  my $uri = URI->new( $self->{base_url}.'/application/o/authorize/' );
  $uri->query_form(
    response_type => 'code',
    map { $_ => $arg{$_} } grep { defined $arg{$_} } qw( client_id redirect_uri scope state nonce max_age acr_values )
  );
  my $response = $self->{ua}->get( $uri->as_string );
  my $location = $response->header('Location')
    or croak 'the authorize endpoint answered '.$response->status_line.' instead of a redirect';
  my %query = URI->new($location)->query_form;
  croak 'the authorize endpoint redirected to the login at '.$location unless defined $query{code};
  return $query{code};
}

sub whoami {
  my ( $self ) = @_;
  my $request = HTTP::Request->new( GET => $self->{base_url}.'/api/v3/core/users/me/' );
  $request->header( Accept => 'application/json' );
  my $response = $self->{ua}->request($request);
  return unless $response->is_success;
  my $data = eval { $JSON->decode( $response->content ) };
  return ref $data eq 'HASH' ? $data->{user} : undef;
}

1;
