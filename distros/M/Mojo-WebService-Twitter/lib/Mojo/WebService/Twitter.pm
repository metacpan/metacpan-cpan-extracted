package Mojo::WebService::Twitter;
use Mojo::Base -base;

use Carp 'croak';
use Scalar::Util 'blessed';
use Mojo::Collection;
use Mojo::UserAgent;
use Mojo::Util qw(b64_encode url_escape);
use Mojo::WebService::Twitter::Error 'twitter_tx_error';
use Mojo::WebService::Twitter::Tweet;
use Mojo::WebService::Twitter::User;
use Mojo::WebService::Twitter::Util;
use WWW::OAuth;

our $VERSION = '1.000';

has ['api_key','api_secret'];
has 'ua' => sub { Mojo::UserAgent->new };

sub authentication {
	my $self = shift;
	return $self->{authentication} // croak 'No authentication set' unless @_;
	my $auth = shift;
	if (ref $auth eq 'CODE') {
		$self->{authentication} = $auth;
	} elsif (ref $auth eq 'HASH') {
		if (defined $auth->{access_token}) {
			$self->{authentication} = $self->_oauth2($auth->{access_token});
		} elsif (defined $auth->{oauth_token} and defined $auth->{oauth_token_secret}) {
			$self->{authentication} = $self->_oauth($auth->{oauth_token}, $auth->{oauth_token_secret});
		} else {
			croak 'Unrecognized authentication hashref (no oauth_token or access_token)';
		}
	} elsif ($auth eq 'oauth') {
		$self->{authentication} = $self->_oauth(@_);
	} elsif ($auth eq 'oauth2') {
		$self->{authentication} = $self->_oauth2(@_);
	} else {
		croak "Unknown authentication $auth";
	}
	return $self;
}

sub request_oauth {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_request_oauth(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			my $res = $self->_from_request_oauth($tx) // return $self->$cb('OAuth callback was not confirmed');
			$self->$cb(undef, $res);
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return $self->_from_request_oauth($tx) // die "OAuth callback was not confirmed\n";
	}
}

sub request_oauth_p {
	my $self = shift;
	my $tx = $self->_build_request_oauth(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return $self->_from_request_oauth($tx) // die "OAuth callback was not confirmed\n";
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_request_oauth {
	my ($self, $url) = @_;
	$url //= 'oob';
	my $tx = $self->ua->build_tx(POST => _oauth_url('request_token'));
	$self->_oauth->($tx->req, { oauth_callback => $url });
	return $tx;
}

sub _from_request_oauth {
	my ($self, $tx) = @_;
	my $params = Mojo::Parameters->new($tx->res->text)->to_hash;
	return undef unless $params->{oauth_callback_confirmed} eq 'true'
		and defined $params->{oauth_token} and defined $params->{oauth_token_secret};
	$self->{request_token_secrets}{$params->{oauth_token}} = $params->{oauth_token_secret};
	return $params;
}

sub verify_oauth {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_verify_oauth(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			my $res = $self->_from_verify_oauth($tx) // return $self->$cb('No OAuth token returned');
			$self->$cb(undef, $res);
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return $self->_from_verify_oauth($tx) // die "No OAuth token returned\n";
	}
}

sub verify_oauth_p {
	my $self = shift;
	my $tx = $self->_build_verify_oauth(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return $self->_from_verify_oauth($tx) // die "No OAuth token returned\n";
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_verify_oauth {
	my ($self, $verifier, $request_token, $request_token_secret) = @_;
	$request_token_secret //= delete $self->{request_token_secrets}{$request_token} // croak "Unknown request token";
	my $tx = $self->ua->build_tx(POST => _oauth_url('access_token'));
	$self->_oauth($request_token, $request_token_secret)->($tx->req, { oauth_verifier => $verifier });
	return $tx;
}

sub _from_verify_oauth {
	my ($self, $tx) = @_;
	my $params = Mojo::Parameters->new($tx->res->text)->to_hash;
	return undef unless defined $params->{'oauth_token'} and defined $params->{'oauth_token_secret'};
	return $params;
}

sub request_oauth2 {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_request_oauth2(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			my $res = $self->_from_request_oauth2($tx) // return $self->$cb('No bearer token returned');
			$self->$cb(undef, $res);
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return $self->_from_request_oauth2($tx) // die "No bearer token returned\n";
	}
}

sub request_oauth2_p {
	my $self = shift;
	my $tx = $self->_build_request_oauth2(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return $self->_from_request_oauth2($tx) // die "No bearer token returned\n";
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_request_oauth2 {
	my ($self) = @_;
	my $tx = $self->ua->build_tx(POST => _oauth2_url('token'), form => { grant_type => 'client_credentials' });
	$self->_oauth2_request->($tx->req);
	return $tx;
}

sub _from_request_oauth2 {
	my ($self, $tx) = @_;
	my $params = $tx->res->json // {};
	return undef unless defined $params->{access_token};
	return $params;
}

sub get_tweet {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_get_tweet(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			$self->$cb(undef, _tweet_object($tx->res->json));
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return _tweet_object($tx->res->json);
	}
}

sub get_tweet_p {
	my $self = shift;
	my $tx = $self->_build_get_tweet(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return _tweet_object($tx->res->json);
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_get_tweet {
	my ($self, $id) = @_;
	croak 'Tweet ID is required for get_tweet' unless defined $id;
	croak 'Invalid tweet ID to retrieve' unless $id =~ m/\A[0-9]+\z/;
	my $tx = $self->ua->build_tx(GET => _api_url('statuses/show.json')->query(id => $id, tweet_mode => 'extended'));
	$self->authentication->($tx->req);
	return $tx;
}

sub get_user {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_get_user(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			$self->$cb(undef, _user_object($tx->res->json));
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return _user_object($tx->res->json);
	}
}

sub get_user_p {
	my $self = shift;
	my $tx = $self->_build_get_user(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return _user_object($tx->res->json);
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_get_user {
	my ($self, %params) = @_;
	my %query;
	$query{user_id} = $params{user_id} if defined $params{user_id};
	$query{screen_name} = $params{screen_name} if defined $params{screen_name};
	croak 'user_id or screen_name is required for get_user' unless %query;
	$query{tweet_mode} = 'extended';
	my $tx = $self->ua->build_tx(GET => _api_url('users/show.json')->query(%query));
	$self->authentication->($tx->req);
	return $tx;
}

sub post_tweet {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_post_tweet(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			$self->$cb(undef, _tweet_object($tx->res->json));
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return _tweet_object($tx->res->json);
	}
}

sub post_tweet_p {
	my $self = shift;
	my $tx = $self->_build_post_tweet(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return _tweet_object($tx->res->json);
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_post_tweet {
	my ($self, $status, %params) = @_;
	croak 'Status text is required to post a tweet' unless defined $status;
	my %form;
	$form{status} = $status;
	$form{$_} = $params{$_} for grep { defined $params{$_} }
		qw(in_reply_to_status_id lat long place_id);
	$form{$_} = $params{$_} ? 'true' : 'false' for grep { defined $params{$_} }
		qw(display_coordinates);
	$form{tweet_mode} = 'extended';
	my $tx = $self->ua->build_tx(POST => _api_url('statuses/update.json'), form => \%form);
	$self->authentication->($tx->req);
	return $tx;
}

sub retweet {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_retweet(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			$self->$cb(undef, _tweet_object($tx->res->json));
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return _tweet_object($tx->res->json);
	}
}

sub retweet_p {
	my $self = shift;
	my $tx = $self->_build_retweet(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return _tweet_object($tx->res->json);
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_retweet {
	my ($self, $id) = @_;
	croak 'Tweet ID is required for retweet' unless defined $id;
	$id = $id->id if blessed $id and $id->isa('Mojo::WebService::Twitter::Tweet');
	croak 'Invalid tweet ID to retweet' unless $id =~ m/\A[0-9]+\z/;
	my $tx = $self->ua->build_tx(POST => _api_url("statuses/retweet/$id.json")->query(tweet_mode => 'extended'));
	$self->authentication->($tx->req);
	return $tx;
}

sub search_tweets {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_search_tweets(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			$self->$cb(undef, Mojo::Collection->new(map { _tweet_object($_) } @{$tx->res->json->{statuses} // []}));
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return Mojo::Collection->new(map { _tweet_object($_) } @{$tx->res->json->{statuses} // []});
	}
}

sub search_tweets_p {
	my $self = shift;
	my $tx = $self->_build_search_tweets(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return Mojo::Collection->new(map { _tweet_object($_) } @{$tx->res->json->{statuses} // []});
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_search_tweets {
	my ($self, $q, %params) = @_;
	croak 'Search query is required for search_tweets' unless defined $q;
	my %query;
	$query{q} = $q;
	my $geocode = $params{geocode};
	if (ref $geocode) {
		my ($lat, $long, $rad);
		($lat, $long, $rad) = @$geocode if ref $geocode eq 'ARRAY';
		($lat, $long, $rad) = @{$geocode}{'latitude','longitude','radius'} if ref $geocode eq 'HASH';
		$geocode = "$lat,$long,$rad" if defined $lat and defined $long and defined $rad;
	}
	$query{geocode} = $geocode if defined $geocode;
	$query{$_} = $params{$_} for grep { defined $params{$_} } qw(lang result_type count until since_id max_id);
	$query{tweet_mode} = 'extended';
	my $tx = $self->ua->build_tx(GET => _api_url('search/tweets.json')->query(%query));
	$self->authentication->($tx->req);
	return $tx;
}

sub verify_credentials {
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
	my $self = shift;
	my $tx = $self->_build_verify_credentials(@_);
	if ($cb) {
		$self->ua->start($tx, sub {
			my ($ua, $tx) = @_;
			return $self->$cb(twitter_tx_error($tx)) if $tx->error;
			$self->$cb(undef, Mojo::WebService::Twitter::User->new(twitter => $self)->from_source($tx->res->json));
		});
	} else {
		$tx = $self->ua->start($tx);
		die twitter_tx_error($tx) if $tx->error;
		return Mojo::WebService::Twitter::User->new(twitter => $self)->from_source($tx->res->json);
	}
}

sub verify_credentials_p {
	my $self = shift;
	my $tx = $self->_build_verify_credentials(@_);
	return $self->ua->start_p($tx)->then(sub {
		my ($tx) = @_;
		die twitter_tx_error($tx) if $tx->error;
		return Mojo::WebService::Twitter::User->new(twitter => $self)->from_source($tx->res->json);
	}, sub { die Mojo::WebService::Twitter::Error->new(connection_error => $_[0]) });
}

sub _build_verify_credentials {
	my ($self) = @_;
	my $tx = $self->ua->build_tx(GET => _api_url('account/verify_credentials.json')->query(tweet_mode => 'extended'));
	$self->authentication->($tx->req);
	return $tx;
}

sub _api_url { Mojo::WebService::Twitter::Util::_api_url(@_) }
sub _oauth_url { Mojo::WebService::Twitter::Util::_oauth_url(@_) }
sub _oauth2_url { Mojo::WebService::Twitter::Util::_oauth2_url(@_) }

sub _oauth {
	my $self = shift;
	my ($api_key, $api_secret) = ($self->api_key, $self->api_secret);
	croak 'Twitter API key and secret are required' unless defined $api_key and defined $api_secret;
	my ($token, $token_secret) = @_;
	my $oauth = WWW::OAuth->new(
		client_id => $api_key,
		client_secret => $api_secret,
		token => $token,
		token_secret => $token_secret,
	);
	return sub { $oauth->authenticate(@_) };
}

sub _oauth2_request {
	my $self = shift;
	my ($api_key, $api_secret) = ($self->api_key, $self->api_secret);
	croak 'Twitter API key and secret are required' unless defined $api_key and defined $api_secret;
	my $token = b64_encode(url_escape($api_key) . ':' . url_escape($api_secret), '');
	return sub { shift->headers->authorization("Basic $token") };
}

sub _oauth2 {
	my $self = shift;
	my $token = shift // croak 'Access token is required for OAuth2 authentication';
	return sub { shift->headers->authorization("Bearer $token") };
}

sub _tweet_object { Mojo::WebService::Twitter::Tweet->new->from_source(shift) }

sub _user_object { Mojo::WebService::Twitter::User->new->from_source(shift) }

1;

=head1 NAME

Mojo::WebService::Twitter - Simple Twitter API client

=head1 SYNOPSIS

 my $twitter = Mojo::WebService::Twitter->new(api_key => $api_key, api_secret => $api_secret);
 
 # Request and store access token
 $twitter->authentication($twitter->request_oauth2);
 
 # Blocking API request
 my $user = $twitter->get_user(screen_name => $name);
 say $user->screen_name . ' was created on ' . $user->created_at->ymd;
 
 # Non-blocking API request
 $twitter->get_tweet($tweet_id, sub {
   my ($twitter, $err, $tweet) = @_;
   print $err ? "Error: $err" : 'Tweet: ' . $tweet->text . "\n";
 });
 Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
 
 # Non-blocking API request using promises
 $twitter->get_tweet_p($tweet_id)->then(sub {
   my ($tweet) = @_;
   print 'Tweet: ' . $tweet->text . "\n";
 })->catch(sub {
   my ($err) = @_;
   print "Error: $err";
 })->wait;
 
 # Some requests require authentication on behalf of a user
 $twitter->authentication(oauth => $token, $secret);
 my $authorizing_user = $twitter->verify_credentials;
 
 my $new_tweet = $twitter->post_tweet('Something new and exciting!');

=head1 DESCRIPTION

L<Mojo::WebService::Twitter> is a L<Mojo::UserAgent> based
L<Twitter|https://twitter.com> API client that can perform requests
synchronously or asynchronously. An API key and secret for a
L<Twitter Application|https://apps.twitter.com> are required.

API requests are authenticated by the L</"authentication"> coderef, which can
either use an OAuth 2.0 access token to authenticate requests on behalf of the
application itself, or OAuth 1.0 credentials (access token and secret) to
authenticate requests on behalf of a specific user. The L<twitter_oauth_creds>
script can be used to obtain Twitter OAuth credentials for a user from the
command-line. A web application may wish to implement its own OAuth
authorization flow, passing a callback URL back to the application in
L</"request_oauth">, then calling L</"verify_oauth"> with the passed verifier
code to retrieve the credentials. See the
L<Twitter documentation|https://dev.twitter.com/web/sign-in/implementing> for
more details.

All methods which query the Twitter API can be called with an optional trailing
callback argument to run a non-blocking API query. Alternatively, the C<_p>
variant will run a non-blocking API query and return a L<Mojo::Promise>, which
can simplify complex sequences of non-blocking queries. On connection, HTTP, or
API error, blocking API queries will throw a L<Mojo::WebService::Twitter::Error>
exception. Non-blocking API queries will pass this exception object to the
callback or reject the promise, and otherwise pass the results to the callback
or resolve the promise.

Note that this distribution implements only a subset of the Twitter API.
Additional features may be added as requested. See L<Twitter::API> for a more
fully-featured lightweight and modern twitter client library.

=head1 ATTRIBUTES

L<Mojo::WebService::Twitter> implements the following attributes.

=head2 api_key

 my $api_key = $twitter->api_key;
 $twitter    = $twitter->api_key($api_key);

API key for your L<Twitter Application|https://apps.twitter.com>.

=head2 api_secret

 my $api_secret = $twitter->api_secret;
 $twitter       = $twitter->api_secret($api_secret);

API secret for your L<Twitter Application|https://apps.twitter.com>.

=head2 ua

 my $ua      = $webservice->ua;
 $webservice = $webservice->ua(Mojo::UserAgent->new);

HTTP user agent object to use for synchronous and asynchronous requests,
defaults to a L<Mojo::UserAgent> object.

=head1 METHODS

L<Mojo::WebService::Twitter> inherits all methods from L<Mojo::Base>, and
implements the following new ones.

=head2 authentication

 my $code = $twitter->authentication;
 $twitter = $twitter->authentication($code);
 $twitter = $twitter->authentication({oauth_token => $access_token, oauth_token_secret => $access_token_secret});
 $twitter = $twitter->authentication(oauth => $access_token, $access_token_secret);
 $twitter = $twitter->authentication({access_token => $access_token});
 $twitter = $twitter->authentication(oauth2 => $access_token);

Get or set coderef used to authenticate API requests. Passing C<oauth> with
optional token and secret, or a hashref containing C<oauth_token> and
C<oauth_token_secret>, will set a coderef which uses a L<WWW::OAuth> to
authenticate requests. Passing C<oauth2> with required token or a hashref
containing C<access_token> will set a coderef which authenticates using the
passed access token. The coderef will receive the L<Mojo::Message::Request>
object as the first parameter, and an optional hashref of C<oauth_> parameters.

=head2 request_oauth

=head2 request_oauth_p

 my $res = $twitter->request_oauth;
 my $res = $twitter->request_oauth($callback_url);
 $twitter->request_oauth(sub {
   my ($twitter, $error, $res) = @_;
 });
 my $p = $twitter->request_oauth_p;

Send an OAuth 1.0 authorization request and return a hashref containing
C<oauth_token> and C<oauth_token_secret> (request token and secret). An
optional OAuth callback URL may be passed; by default, C<oob> is passed to use
PIN-based authorization. The user should be directed to the authorization URL
which can be retrieved by passing the request token to
L<Mojo::WebService::Twitter::Util/"twitter_authorize_url">. After
authorization, the user will either be redirected to the callback URL with the
query parameter C<oauth_verifier>, or receive a PIN to return to the
application. Either the verifier string or PIN should be passed to
L</"verify_oauth"> to retrieve an access token and secret.

=head2 verify_oauth

=head2 verify_oauth_p

 my $res = $twitter->verify_oauth($verifier, $request_token, $request_token_secret);
 $twitter->verify_oauth($verifier, $request_token, $request_token_secret, sub {
   my ($twitter, $error, $res) = @_;
 });
 my $p = $twitter->verify_oauth_p($verifier, $request_token, $request_token_secret);

Verify an OAuth 1.0 authorization request with the verifier string or PIN from
the authorizing user, and the previously obtained request token and secret. The
secret is cached by L</"request_oauth"> and may be omitted. Returns a hashref
containing C<oauth_token> and C<oauth_token_secret> (access token and secret)
which may be passed directly to L</"authentication"> to authenticate requests
on behalf of the user.

=head2 request_oauth2

=head2 request_oauth2_p

 my $res = $twitter->request_oauth2;
 $twitter->request_oauth2(sub {
   my ($twitter, $error, $res) = @_;
 });
 my $p = $twitter->request_oauth2_p;

Request OAuth 2 credentials and return a hashref containing an C<access_token>
that can be passed directly to L</"authentication"> to authenticate requests on
behalf of the application itself.

=head2 get_tweet

=head2 get_tweet_p

 my $tweet = $twitter->get_tweet($tweet_id);
 $twitter->get_tweet($tweet_id, sub {
   my ($twitter, $err, $tweet) = @_;
 });
 $twitter->get_tweet_p($tweet_id);

Retrieve a L<Mojo::WebService::Twitter::Tweet> by tweet ID.

=head2 get_user

=head2 get_user_p

 my $user = $twitter->get_user(user_id => $user_id);
 my $user = $twitter->get_user(screen_name => $screen_name);
 $twitter->get_user(screen_name => $screen_name, sub {
   my ($twitter, $err, $user) = @_;
 });
 my $p = $twitter->get_user_p(user_id => $user_id);

Retrieve a L<Mojo::WebService::Twitter::User> by user ID or screen name.

=head2 post_tweet

=head2 post_tweet_p

 my $tweet = $twitter->post_tweet($text, %options);
 $twitter->post_tweet($text, %options, sub {
 	my ($twitter, $err, $tweet) = @_;
 });
 my $p = $twitter->post_tweet_p($text, %options);

Post a status update (tweet) and retrieve the resulting
L<Mojo::WebService::Twitter::Tweet>. Requires OAuth 1.0 authentication. Accepts
the following options:

=over

=item in_reply_to_status_id

 in_reply_to_status_id => '12345'

Indicates the tweet is in reply to an existing tweet ID. IDs should be
specified as a string to avoid issues with large integers. This parameter will
be ignored by the Twitter API unless the author of the referenced tweet is
mentioned within the status text as C<@username>.

=item lat

 lat => '37.781157'

The latitude of the location to attach to the tweet. This parameter will be
ignored by the Twitter API unless it is within the range C<-90.0> to C<90.0>,
and a corresponding C<long> is specified. It is recommended to specify values
as strings to avoid issues with floating-point representations.

=item long

 long => '-122.398720'

The longitude of the location to attach to the tweet. This parameter will be
ignored by the Twitter API unless it is within the range C<-180.0> to C<180.0>,
and a corresponding C<lat> is specified. It is recommended to specify values as
strings to avoid issues with floating-point representations.

=item place_id

 place_id => 'df51dec6f4ee2b2c'

A Twitter L<place ID|https://dev.twitter.com/overview/api/places> to attach to
the tweet.

=item display_coordinates

 display_coordinates => 1

If true, tweet will display the exact coordinates the tweet was sent from.

=back

=head2 retweet

=head2 retweet_p

 my $tweet = $twitter->retweet($tweet_id);
 $twitter->retweet($tweet_id, sub {
   my ($twitter, $err, $tweet) = @_;
 });
 my $p = $twitter->retweet_p($tweet_id);

Retweet the tweet ID or L<Mojo::WebService::Twitter::Tweet> object. Returns a
L<Mojo::WebService::Twitter::Tweet> representing the original tweet. Requires
OAuth 1.0 authentication.

=head2 search_tweets

=head2 search_tweets_p

 my $tweets = $twitter->search_tweets($query);
 my $tweets = $twitter->search_tweets($query, %options);
 $twitter->search_tweets($query, %options, sub {
   my ($twitter, $err, $tweets) = @_;
 });
 my $p = $twitter->search_tweets_p($query, %options);

Search Twitter and return a L<Mojo::Collection> of L<Mojo::WebService::Twitter::Tweet>
objects. Accepts the following options:

=over

=item geocode

 geocode => '37.781157,-122.398720,1mi'
 geocode => ['37.781157','-122.398720','1mi']
 geocode => {latitude => '37.781157', longitude => '-122.398720', radius => '1mi'}

Restricts tweets to the given radius of the given latitude/longitude. Radius
must be specified as C<mi> (miles) or C<km> (kilometers). It is recommended to
specify values as strings to avoid issues with floating-point representations.

=item lang

 lang => 'eu'

Restricts tweets to the given L<ISO 639-1|http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>
language code.

=item result_type

 result_type => 'recent'

Specifies what type of search results to receive. Valid values are C<recent>,
C<popular>, and C<mixed> (default).

=item count

 count => 5

Limits the search results per page. Maximum C<100>, default C<15>.

=item until

 until => '2015-07-19'

Restricts tweets to those created before the given date, in the format
C<YYYY-MM-DD>.

=item since_id

 since_id => '12345'

Restricts results to those more recent than the given tweet ID. IDs should be
specified as a string to avoid issues with large integers. See
L<here|https://dev.twitter.com/rest/public/timelines> for more information on
filtering results with C<since_id> and C<max_id>.

=item max_id

 max_id => '54321'

Restricts results to those older than (or equal to) the given tweet ID. IDs
should be specified as a string to avoid issues with large integers. See
L<here|https://dev.twitter.com/rest/public/timelines> for more information on
filtering results with C<since_id> and C<max_id>.

=back

=head2 verify_credentials

=head2 verify_credentials_p

 my $user = $twitter->verify_credentials;
 $twitter->verify_credentials(sub {
   my ($twitter, $error, $user) = @_;
 });
 my $p = $twitter->verify_credentials_p;

Verify the authorizing user's credentials and return a representative
L<Mojo::WebService::Twitter::User> object. Requires OAuth 1.0 authentication.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Twitter::API>, L<WWW::OAuth>
