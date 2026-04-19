package Net::Async::WebSearch::Provider::Reddit::OAuth;
our $VERSION = '0.002';
# ABSTRACT: Reddit search provider using the OAuth2 endpoint
use strict;
use warnings;
use parent 'Net::Async::WebSearch::Provider::Reddit';

use Carp qw( croak );
use Future;
use JSON::MaybeXS qw( decode_json );
use URI;
use HTTP::Request::Common qw( GET POST );
use MIME::Base64 qw( encode_base64 );

sub _init {
  my ( $self ) = @_;
  croak "Reddit::OAuth requires 'client_id'"     unless $self->{client_id};
  croak "Reddit::OAuth requires 'client_secret'" unless defined $self->{client_secret};

  $self->{grant_type}    ||= 'client_credentials';  # client_credentials | password | installed | authorization_code
  $self->{token_url}     ||= 'https://www.reddit.com/api/v1/access_token';
  $self->{authorize_url} ||= 'https://www.reddit.com/api/v1/authorize';
  $self->{endpoint}      ||= 'https://oauth.reddit.com';
  $self->{name}          ||= 'reddit-oauth';
  $self->{link_base}     ||= 'https://www.reddit.com';
  $self->{token_margin}  ||= 60;   # refresh this many seconds before expiry

  if ( $self->{grant_type} eq 'password' ) {
    croak "grant_type=password needs 'username' and 'password'"
      unless defined $self->{username} && defined $self->{password};
  }
  elsif ( $self->{grant_type} eq 'installed' ) {
    $self->{device_id} ||= 'DO_NOT_TRACK_THIS_DEVICE';
  }
  elsif ( $self->{grant_type} eq 'authorization_code' ) {
    # For authorization_code, either the caller seeds us with
    # a refresh_token (persisted from a prior session) or with
    # an access_token + refresh_token pair, or they must drive
    # authorize_url → complete_authorization themselves before
    # the first search.
  }

  $self->SUPER::_init;
  # Parent sets link_base to www.reddit.com, which is what we want.
  # But parent also sets endpoint to www.reddit.com — overwrite back.
  $self->{endpoint} = 'https://oauth.reddit.com' unless $self->{_endpoint_explicit};

  # Pre-seed token/refresh if the caller provided them (persisted state).
  if ( defined $self->{access_token} ) {
    $self->{_access_token}     = $self->{access_token};
    $self->{_token_expires_at} = $self->{token_expires_at}
      // ( time + ( $self->{expires_in} // 3600 ) );
  }
  if ( defined $self->{refresh_token} ) {
    $self->{_refresh_token} = $self->{refresh_token};
  }
}

sub new {
  my ( $class, %args ) = @_;
  my $explicit_ep = exists $args{endpoint};
  my $self = $class->SUPER::new(%args);
  $self->{_endpoint_explicit} = $explicit_ep;
  $self->{endpoint} = 'https://oauth.reddit.com' unless $explicit_ep;
  return $self;
}

sub client_id          { $_[0]->{client_id} }
sub client_secret      { $_[0]->{client_secret} }
sub grant_type         { $_[0]->{grant_type} }
sub token_url          { $_[0]->{token_url} }
sub authorize_endpoint { $_[0]->{authorize_url} }

sub access_token       { $_[0]->{_access_token} }
sub refresh_token      { $_[0]->{_refresh_token} }
sub token_expires_at   { $_[0]->{_token_expires_at} }

# MCP / host helper: snapshot the persistable bits of the auth state
# so a host application can stash them in its session store and feed
# them back to a later `new()` call.
sub token_state {
  my ( $self ) = @_;
  return {
    ( defined $self->{_access_token}
        ? ( access_token      => $self->{_access_token},
            token_expires_at  => $self->{_token_expires_at} )
        : () ),
    ( defined $self->{_refresh_token}
        ? ( refresh_token => $self->{_refresh_token} )
        : () ),
  };
}

sub _basic_auth_header {
  my ( $self ) = @_;
  my $raw = $self->client_id . ':' . $self->client_secret;
  my $b64 = encode_base64($raw, '');
  return "Basic $b64";
}

#----------------------------------------------------------------------
# Host-facing authorization-code helpers
#----------------------------------------------------------------------

# Build the URL the human should visit to authorize the app.
# Returns a plain URL string (not a Future) — no network round-trip.
sub authorize_url {
  my ( $self, %args ) = @_;
  croak "authorize_url needs 'redirect_uri'" unless defined $args{redirect_uri};
  my $scope = $args{scope};
  if ( ref $scope eq 'ARRAY' ) { $scope = join ' ', @$scope }
  $scope //= 'read';
  my $uri = URI->new( $self->authorize_endpoint );
  $uri->query_form(
    client_id     => $self->client_id,
    response_type => 'code',
    state         => $args{state} // _random_state(),
    redirect_uri  => $args{redirect_uri},
    duration      => $args{duration} // 'permanent',
    scope         => $scope,
  );
  return $uri->as_string;
}

# Exchange an authorization_code → access_token + refresh_token.
# Caller supplies the code pasted back from the redirect, plus the
# same redirect_uri that was used in authorize_url.
sub complete_authorization {
  my ( $self, %args ) = @_;
  my $http = $args{http} || $self->{_http_for_auth};
  croak "complete_authorization needs 'http' (Net::Async::HTTP) "
       ."unless the provider has been added to a loop first"
    unless $http;
  croak "complete_authorization needs 'code'"         unless defined $args{code};
  croak "complete_authorization needs 'redirect_uri'" unless defined $args{redirect_uri};

  return $self->_post_token($http, [
    grant_type   => 'authorization_code',
    code         => $args{code},
    redirect_uri => $args{redirect_uri},
  ]);
}

sub _random_state {
  my @chars = ( 'a'..'z', 'A'..'Z', 0..9 );
  join '', map { $chars[ int rand @chars ] } 1 .. 24;
}

#----------------------------------------------------------------------
# Token fetch / refresh dance
#----------------------------------------------------------------------

sub _post_token {
  my ( $self, $http, $body_ref ) = @_;
  my $req = POST( $self->token_url, $body_ref );
  $req->header( 'Authorization' => $self->_basic_auth_header );
  $req->header( 'User-Agent'    => $self->user_agent_string );
  $req->header( 'Accept'        => 'application/json' );

  return $http->do_request( request => $req )->then(sub {
    my ( $resp ) = @_;
    unless ( $resp->is_success ) {
      return Future->fail(
        $self->name.": token HTTP ".$resp->status_line, 'websearch', $self->name,
      );
    }
    my $data = eval { decode_json( $resp->decoded_content ) };
    if ( my $e = $@ ) {
      return Future->fail( $self->name.": token invalid JSON: $e", 'websearch', $self->name );
    }
    if ( !$data->{access_token} ) {
      my $err = $data->{error} // 'unknown';
      return Future->fail( $self->name.": token error: $err", 'websearch', $self->name );
    }
    $self->{_access_token}     = $data->{access_token};
    $self->{_token_expires_at} = time + ( $data->{expires_in} // 3600 );
    # Reddit only returns refresh_token on duration=permanent auth_code
    # flows. Some refresh responses include a fresh refresh_token too —
    # prefer that; otherwise keep the one we used.
    if ( defined $data->{refresh_token} ) {
      $self->{_refresh_token} = $data->{refresh_token};
    }
    if ( my $cb = $self->{on_token_refresh} ) {
      $cb->( $self, $data );
    }
    return Future->done( $self->{_access_token} );
  });
}

sub _get_token {
  my ( $self, $http ) = @_;

  # Valid cached token?
  if ( $self->{_access_token}
       && $self->{_token_expires_at}
       && time + $self->{token_margin} < $self->{_token_expires_at} ) {
    return Future->done( $self->{_access_token} );
  }

  # A refresh_token beats every other grant — it's cheap and user-context
  # is already established.
  if ( $self->{_refresh_token} ) {
    return $self->_post_token($http, [
      grant_type    => 'refresh_token',
      refresh_token => $self->{_refresh_token},
    ]);
  }

  # For authorization_code flows without a refresh_token, we can't
  # auto-fetch — the caller must drive the authorize → complete
  # dance first.
  if ( $self->grant_type eq 'authorization_code' ) {
    return Future->fail(
      $self->name.": no access_token and no refresh_token — "
        ."call authorize_url / complete_authorization first",
      'websearch', $self->name,
    );
  }

  my @body = ( grant_type => $self->grant_type );
  if ( $self->grant_type eq 'password' ) {
    push @body, username => $self->{username}, password => $self->{password};
  }
  elsif ( $self->grant_type eq 'installed' ) {
    @body = (
      grant_type => 'https://oauth.reddit.com/grants/installed_client',
      device_id  => $self->{device_id},
    );
  }

  return $self->_post_token($http, \@body);
}

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  return $self->_get_token($http)->then(sub {
    my ( $token ) = @_;

    my $sub = defined $opts->{subreddit} ? $opts->{subreddit} : $self->subreddit;
    my $path = defined $sub && length $sub ? "/r/$sub/search" : "/search";

    my $uri = URI->new( $self->endpoint . $path );
    my %q = (
      q     => $query,
      limit => $limit,
      sort  => $opts->{sort} // $self->sort,
      t     => $opts->{time} // $self->time,
      raw_json => 1,
    );
    $q{restrict_sr}     = 1   if defined $sub && length $sub;
    $q{include_over_18} = $opts->{include_nsfw} ? 'on' : 'off';
    $uri->query_form(%q);

    my $req = GET( $uri->as_string );
    $req->header( 'Authorization' => "Bearer $token" );
    $req->header( 'User-Agent'    => $self->user_agent_string );
    $req->header( 'Accept'        => 'application/json' );

    $http->do_request( request => $req )->then(sub {
      my ( $resp ) = @_;
      unless ( $resp->is_success ) {
        return Future->fail(
          $self->name.": HTTP ".$resp->status_line, 'websearch', $self->name,
        );
      }
      my $data = eval { decode_json( $resp->decoded_content ) };
      if ( my $e = $@ ) {
        return Future->fail( $self->name.": invalid JSON: $e", 'websearch', $self->name );
      }
      return Future->done( $self->_parse_listing($data, $limit) );
    });
  });
}

sub user_agent_string {
  my ( $self ) = @_;
  return $self->{user_agent} if defined $self->{user_agent};
  return $self->SUPER::user_agent_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch::Provider::Reddit::OAuth - Reddit search provider using the OAuth2 endpoint

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # App-only OAuth (read-only, no user account involved) — simplest path:
  my $r = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => $ENV{REDDIT_CLIENT_ID},
    client_secret => $ENV{REDDIT_CLIENT_SECRET},
    user_agent    => 'my-search-bot/1.0 by /u/myredditname',
  );

  # Authorization-code flow — drive the consent dance from a host app
  # (MCP server, web app, CLI…) where a human can visit a URL.
  my $r = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => ...,
    client_secret => ...,
    grant_type    => 'authorization_code',
    user_agent    => 'my-app/1.0',
    on_token_refresh => sub {
      my ( $provider, $raw ) = @_;
      # persist $provider->token_state to your session store
    },
  );
  $loop->add($ws_with_r);

  # 1. Send the human off to authorize:
  my $url = $r->authorize_url(
    redirect_uri => 'https://my.app/oauth/reddit/callback',
    scope        => [qw( read identity )],
    duration     => 'permanent',   # get a refresh_token
    state        => 'abc-123',     # CSRF guard you verify on callback
  );

  # 2. Human clicks Approve, callback receives ?code=...&state=...
  #    Exchange it:
  my $tokens = $r->complete_authorization(
    http         => $ws->http,
    code         => $code_from_callback,
    redirect_uri => 'https://my.app/oauth/reddit/callback',
  )->get;

  # 3. Later sessions: re-hydrate from a stored refresh_token.
  my $r = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => ..., client_secret => ...,
    grant_type    => 'authorization_code',
    refresh_token => $stored_refresh_token,
  );

  # Script app tied to a specific account (slightly higher rate limits):
  my $r = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => ...,
    client_secret => ...,
    grant_type    => 'password',
    username      => 'myaccount',
    password      => 'hunter2',
    user_agent    => 'my-search-bot/1.0 by /u/myaccount',
  );

  # Installed-app grant (no server-side secret — still set client_secret to ''):
  my $r = Net::Async::WebSearch::Provider::Reddit::OAuth->new(
    client_id     => ...,
    client_secret => '',
    grant_type    => 'installed',
    device_id     => 'a-random-20-to-30-char-string',
    user_agent    => 'my-search-bot/1.0',
  );

=head1 DESCRIPTION

Drop-in replacement for L<Net::Async::WebSearch::Provider::Reddit> that hits
the C<oauth.reddit.com> endpoint with a bearer token. Higher rate limits,
proper ToS compliance, same result shape.

=head2 client_id

Required. The app's public client id.

=head2 client_secret

Required (but may be the empty string for installed apps).

=head2 grant_type

C<client_credentials> (default, app-only), C<password> (script apps),
C<installed> (device-id apps), or C<authorization_code> (user consent flow,
typically driven by a host app — MCP server, web app, CLI — via
L</authorize_url> and L</complete_authorization>).

=head2 username

=head2 password

Reddit account credentials. Only used when C<grant_type=password>.

=head2 device_id

20-30 character identifier for C<grant_type=installed>. Should be stable
per device but opaque. Defaults to C<DO_NOT_TRACK_THIS_DEVICE> (a Reddit
convention that opts out of fingerprinting).

=head2 user_agent

Override the User-Agent string. Strongly recommended — see L</SETUP>.

=head2 token_url

Override the token endpoint. Default C<https://www.reddit.com/api/v1/access_token>.

=head2 token_margin

Seconds before token expiry to refresh preemptively. Default 60.

=head2 endpoint

Override the search endpoint. Default C<https://oauth.reddit.com>.

All attributes inherited from L<Net::Async::WebSearch::Provider::Reddit>
(C<subreddit>, C<sort>, C<time>) apply as well.

=head2 access_token

=head2 refresh_token

=head2 token_expires_at

Optional — pre-seed the auth state on C<new()> (e.g. rehydrating a session
from a host app's persistent store). When a C<refresh_token> is present, the
provider will use it to get fresh access tokens automatically instead of
re-doing C<client_credentials>.

=head2 on_token_refresh

Coderef called as C<< $cb->($provider, $raw_response_hash) >> every time a
new access token is minted (initial fetch or refresh). Use it to persist
C<< $provider->token_state >> to your session store so a later process can
re-hydrate without re-prompting the user.

=head2 authorize_url(%args)

Builds — I<without> a network round-trip — the Reddit URL the human should
visit to grant your app access. Returns a plain URL string.

Required: C<redirect_uri>. Optional: C<scope> (arrayref or space-separated
string, default C<'read'>), C<state> (auto-generated if omitted — B<strongly
recommended> to supply your own for CSRF defence), C<duration>
(C<permanent> (default) to receive a refresh_token, C<temporary> for a
one-hour token only).

This is the primitive a host app (MCP server, web app) uses to kick off the
consent dance. The host shows the URL to the user — via a tool result, a
browser redirect, or whatever — and waits for the C<?code=...> to come back
on the callback URL.

=head2 complete_authorization(%args)

Exchanges an authorization code for an access/refresh token pair. Required:
C<http> (a L<Net::Async::HTTP> — typically C<< $ws->http >>), C<code> (the
value from the redirect), and C<redirect_uri> (must match the one used in
L</authorize_url>). Returns a Future of the access token; also populates
C<< $self->access_token >>, C<< $self->refresh_token >>, and
C<< $self->token_expires_at >>, and fires C<on_token_refresh> if set.

=head2 token_state

Snapshots the currently-held auth state as a hashref:

  { access_token, refresh_token, token_expires_at }

Feed this hash back to a future C<new()> call (or drop its keys in as
C<access_token => ..., refresh_token => ..., token_expires_at => ...>) to
continue the same authenticated session. Intended for host-app session
persistence — this library does not persist anything on its own.

=head2 search

Same contract as the parent provider — plus a transparent token fetch/refresh
round-trip before the first search (and again when the cached token is about
to expire). For C<authorization_code> grants without a seeded refresh_token,
the caller must drive L</authorize_url> / L</complete_authorization> first;
otherwise the first search will fail.

=head1 SETUP

Reddit apps are created at L<https://www.reddit.com/prefs/apps>. The flow:

=over 4

=item 1.

Log in to Reddit with the account that should own the app. For app-only /
installed grants this can be any account; for C<grant_type=password> it must
be the account whose credentials you're going to use.

=item 2.

Scroll to the bottom of L<https://www.reddit.com/prefs/apps> and click
B<"create app"> (or B<"create another app">).

=item 3.

Pick the app type:

=over 4

=item * B<script> — when you plan to use C<grant_type=password> or the default
C<client_credentials>. This is the right choice for personal/CLI tools and
backend services where I<you> own the account. Gets the "full" rate limit.

=item * B<web app> — for server-side web apps using the authorization-code
flow (not covered by this provider; use it only with C<client_credentials>
here).

=item * B<installed app> — for mobile/desktop clients without a server-held
secret. Use with C<grant_type=installed> and supply a per-device C<device_id>.

=back

=item 4.

Fill in C<name>, C<description>, and C<about url> (anything reasonable).
For C<redirect uri> use C<http://localhost:8000> (not used by this provider
but the form demands a value).

=item 5.

Submit. Reddit shows you two strings:

=over 4

=item * The C<client_id>: the short string shown right under the app name
(looks like C<AbCdEfGhIjKlMn>).

=item * The C<secret>: next to the label "secret". Copy it now — it won't be
shown again in full.

=back

For B<installed> apps there is no secret — pass C<client_secret =E<gt> ''>.

=item 6.

B<Choose a real User-Agent.> Reddit's API wiki explicitly asks for the form
C<< <platform>:<app-id>:<version> (by /u/<your-reddit-name>) >>, e.g.
C<my-search-bot/1.0 by /u/myaccount>. Generic UAs (Python-requests, curl,
LWP::UserAgent) get throttled into oblivion. Pass it via C<user_agent =E<gt> ...>
on C<new>.

=item 7.

B<Respect the rate limits.> Authenticated OAuth clients get ~100 QPM
(queries per minute) per OAuth-ID. Script apps pin to the account,
app-only / installed pin to the client_id.

=back

After setup, the provider handles the token dance for you: it POSTs to
C<https://www.reddit.com/api/v1/access_token>, caches the bearer token
until C<token_margin> seconds before expiry, and attaches it to every
search request against C<https://oauth.reddit.com>.

=head1 SEE ALSO

L<Net::Async::WebSearch::Provider::Reddit>,
L<https://www.reddit.com/prefs/apps>,
L<https://github.com/reddit-archive/reddit/wiki/OAuth2>,
L<https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-websearch/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
