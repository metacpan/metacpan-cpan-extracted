package OAuthomatic::Caller;
# ABSTRACT: actually make OAuth-signed calls


use Moose;

use version;
use feature 'state';
use Const::Fast;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use HTTP::Request;
use HTTP::Headers;
use Net::OAuth;
use OAuthomatic::Error;
use OAuthomatic::Internal::Util qw/fill_httpmsg_text fill_httpmsg_form parse_http_msg_form/;
use namespace::sweep;

const my $OAUTH_REALM => "OAuthomatic";

const my $FORM_CONTENT_TYPE => "application/x-www-form-urlencoded";
const my $DEFAULT_FORM_CONTENT_TYPE => "application/x-www-form-urlencoded; charset=utf-8";
const my $DEFAULT_CONTENT_TYPE => "text/plain; charset=utf-8";

const my $_HAS_BUGGY_PROXY_IN_LWP => (
    version->parse($LWP::UserAgent::VERSION) < version->parse("6.06") );


has 'config' => (
    is => 'ro', isa => 'OAuthomatic::Config', required => 1,
    handles => ['debug']);


has 'server' => (
    is => 'ro', isa => 'OAuthomatic::Server', required => 1,
    handles => [
        'oauth_authorize_page', 'oauth_temporary_url', 'oauth_token_url',
        'protocol_version', 'signature_method'
       ]);

# Object responsible for executing calls.
has 'user_agent' => (
   is => 'ro', isa => 'LWP::UserAgent', default => sub {
       # Workaround for SSL-over-proxy problems. Disables buggy proxy behaviour in
       # LWP (proxy should be handled by Crypt::SSLeay below thanks to env variable).
       # https://rt.cpan.org/Public/Bug/Display.html?id=1894
       # http://www.perlmonks.org/?node_id=994683
       # FIXME: when LWP 6.06 turns popular, drop it and just depend on 6.06
       my $ua;
       if($_HAS_BUGGY_PROXY_IN_LWP && $ENV{https_proxy}) {
           require Net::SSL;
           local $Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
           $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
           $ua->proxy(https => undef);
       } else {
           $ua = LWP::UserAgent->new;
       }
       return $ua;
   });

# Application identity
has 'client_cred' => (
    is => 'rw', isa => 'Maybe[OAuthomatic::Types::ClientCred]', required => 1,
    trigger => sub {
        my ($self, $cred, $old_cred) = @_;
        return if @_ == 2;  # Don't act during object build
        return if OAuthomatic::Types::ClientCred->equal($cred, $old_cred);
        # Changed client_cred means access creds are no longer valid.
        $self->token_cred(undef);
    });

# Current access credentials, for use in normal calls
has 'token_cred' => (
    is => 'rw', isa => 'Maybe[OAuthomatic::Types::TokenCred]', required => 1);


sub create_authorization_url {
    my ($self, $callback_url) = @_;

    # Make temporary credentials
    my $temporary_cred = $self->_create_temporary_cred($callback_url);

    # Calculate authorization url
    my $url  = URI->new($self->oauth_authorize_page);
    $url->query_param(oauth_token => $temporary_cred->token);

    $temporary_cred->authorize_page($url);

    return $temporary_cred;
}

# Create request token
sub _create_temporary_cred {
    my ($self, $callback_url) = @_;

    unless ($self->_using_legacy_oauth10) {
        unless($callback_url) {
            OAuthomatic::Error::Generic->throw(
                ident => "missing required argument",
                extra => "callback_url is required");
        }
    }

    my $response = $self->_execute_oauth_request_ext(
        class => 'RequestToken',  # No token
        callback => $callback_url,
        method => 'POST', url => $self->oauth_temporary_url,
        auth_in_post => 1);

    my $response_params = _parse_form_reply(
        $response, ['oauth_token', 'oauth_token_secret']);

    unless($response_params->{oauth_callback_confirmed}
             || $self->_using_legacy_oauth10) {
        OAuthomatic::Error::Protocol->throw(
            ident => "Bad OAuth reply",
            extra => "Missing oauth_callback_confirmed (is site using OAuth 1.0?)");
    }

    return OAuthomatic::Types::TemporaryCred->new(
        data => $response_params,
        remap => {'oauth_token' => 'token', 'oauth_token_secret' => 'secret'});
}


sub create_token_cred {
    my ($self, $temporary_cred, $verifier_cred) = @_;

    unless ($verifier_cred || $self->_using_legacy_oauth10) {  # FIXME maybe drop support for it?
        OAuthomatic::Error::Generic->throw(
            ident => "Missing parameter",
            extra => "For OAuth 1.0a verifier is required");
    }

    my $response = $self->_execute_oauth_request_ext(
        class => 'AccessToken',
        token => $temporary_cred, verifier => $verifier_cred,
        method => 'POST', url => $self->oauth_token_url,
        auth_in_post => 1);

    my $response_params = _parse_form_reply(
        $response, ['oauth_token', 'oauth_token_secret']);

    my $cred =  OAuthomatic::Types::TokenCred->new(
        data => $response_params,
        remap => {'oauth_token' => 'token', 'oauth_token_secret' => 'secret'});

    $self->token_cred($cred);

    return $cred;
}

###########################################################################
# Call-making
###########################################################################


## no critic (RequireArgUnpacking)
sub build_oauth_request {
    my $self = shift;

    unless($self->token_cred) {
        OAuthomatic::Error::Generic->throw(
            ident => "Unauthorized",
            extra => "Missing token.");
    }

    return $self->_build_oauth_request_ext(
        class => 'ProtectedResource',
        token => $self->token_cred,
        @_);
}
## use critic


## no critic (RequireArgUnpacking)
sub execute_oauth_request {
    my $self = shift;

    unless($self->token_cred) {
        OAuthomatic::Error::Generic->throw(
            ident => "Unauthorized",
            extra => "Missing token.");
    }

    return $self->_execute_oauth_request_ext(
        class => 'ProtectedResource',
        token => $self->token_cred,
        @_);
}
## use critic


sub _build_oauth_request_ext {
    my ($self, %args) = @_;

    foreach my $req_arg (qw(class method url)) {
        unless($args{$req_arg}) {
            OAuthomatic::Error::Generic->throw(
                ident => "Bad parameter",
                extra => "Missing required parameter '$req_arg'");
        }
    }

    my $class = $args{class};
    my $token = $args{token};
    my $verifier = $args{verifier};
    my $callback = $args{callback};
    my $method = $args{method};
    my $url = $args{url};
    my $url_args = $args{url_args};
    my $body_form = $args{body_form};
    my $body = $args{body};
    my $content_type = $args{content_type};
    my $auth_in_post = $args{auth_in_post};

    # Sanity checks

    if($method =~ /^(?:POST|PUT)$/x) {
        $body_form = {} unless ($body || $body_form);
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Can not specify both body and body_form")
            if $body && $body_form;
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Can't use plain body with auth_in_post")
            if $auth_in_post && $body;
    }
    elsif($method =~ /^(?:GET|DELETE)$/x) {
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Can not specify body* for $method request")
            if ($body || $body_form);
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Can't use auth_in_post for $method request")
            if $auth_in_post;
    }
    else {
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Unknown method: $method (expected GET, POST, PUT or DELETE)");
    }

    if($url_args) {
        unless(ref($url_args) eq 'HASH') {
            OAuthomatic::Error::Generic->throw(
                ident => "Bad parameter",
                extra => "url_args should be specified as hash reference, but are given as " . (ref($url_args) || "scalar value $url_args"));
        }
    }

    if($body_form) {
        $content_type ||= $DEFAULT_FORM_CONTENT_TYPE;
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "With body_form, the only allowed content_type is $FORM_CONTENT_TYPE (plus coding), but $content_type was given")
            unless $content_type =~ /^$FORM_CONTENT_TYPE(;.*)?$/;
    } else {
        $content_type ||= $DEFAULT_CONTENT_TYPE;
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Can not specify content_type=$content_type and plain body, use body_form!")
            if $content_type =~ /^$FORM_CONTENT_TYPE(;.*)?$/;
    }

    if($verifier) {
        OAuthomatic::Error::Generic->throw(
            ident => "Bad parameter",
            extra => "Attempt to specify verifier without token")
            unless $token;
        OAuthomatic::Error::Generic->throw(
            ident => "Token mismatch",
            extra => "Obtained verifier is for token " . $verifier->token
              . " while (temporary) token is " . $token->token)
            unless $verifier->token eq $token->token;
    }

    # Calculate final URL

    # FIXME: URI encodes as utf-8 true strings or as Latin-1 binary strings. Consider
    #        using default encoding if non-utf8
    my $uri = URI->new($url);
    # Append additional params, if given
    if($url_args) {
        foreach my $key (keys %$url_args) {
            $uri->query_param($key, $url_args->{$key});
        }
    }

    # Net::OAuth is used to
    #   (a) calculate signature
    # and
    #   (b) render authorization header
    my $oauth_request = Net::OAuth->request($class)->new(
        request_method   => $method,
        request_url      => $uri,
        $self->client_cred->as_hash("consumer"),   # consumer_key, consumer_secret
        ($token
           ? ($token->as_hash())        # token, token_secret
           : ()),
        signature_method => $self->signature_method,
        protocol_version => $self->_net_oauth_version_constant(),   # FIXME: isn't it version?
        # version => $self->protocol_version,  # changes oauth_version but better not, bb fails
        timestamp        => time,
        nonce            => $self->_nonce,
        ($verifier
           ? (verifier => $verifier->verifier)
           : ()),
        ($callback
           ? (callback => $callback)
           : ()),
        ($body_form
           ? (extra_params => $body_form)          # body parts used in signature
           : ()),
       );
    $oauth_request->sign;
    OAuthomatic::Error::Generic->throw(
        ident => "OAuth signature verification failed.")
        unless $oauth_request->verify;

    my $headers = HTTP::Headers->new();
    # FIXME: handle custom headers (Accept?)

    if($auth_in_post) {
        my $oauth_par = $oauth_request->to_hash();
        if($body_form && %$body_form) {
            # Merge OAuth with other post oauth_par
            @{$body_form}{keys %$oauth_par} = values %$oauth_par;
        } else {
            $body_form = $oauth_par;
        }
    } else {
        # This builds "OAuth realm=... oauth_consumer_key=.. ..." text
        my $oauth_header_text = $oauth_request->to_authorization_header($OAUTH_REALM);
        $headers->header('Authorization' => $oauth_header_text);
    }

    my $http_request = HTTP::Request->new($method, $uri, $headers);
    if($body) {
        fill_httpmsg_text($http_request, $body, $content_type);
    } elsif($body_form) {
        fill_httpmsg_form($http_request, $body_form);
    }

    return $http_request;
}


## no critic (RequireArgUnpacking)
sub _execute_oauth_request_ext {
    my $self = shift;
    my $request = $self->_build_oauth_request_ext(@_);

    print "[OAuthomatic] Executing request: ", $request->as_string, "\n" if $self->debug;

    my $response = $self->user_agent->request($request);

    print "[OAuthomatic] Obtained response: ", $response->as_string, "\n" if $self->debug;

    OAuthomatic::Error::HTTPFailure->throw(
        ident => 'OAuth-signed HTTP call failed',
        request => $request, response => $response)
        unless $response->is_success;

    return $response;
}
## use critic

###########################################################################
# Helpers
###########################################################################

sub _net_oauth_version_constant {
    my $self = shift;
    my $ver = $self->protocol_version;
    return Net::OAuth::PROTOCOL_VERSION_1_0A() if $ver eq '1.0a';
    return Net::OAuth::PROTOCOL_VERSION_1_0() if $ver eq '1.0';
    return OAuthomatic::Error::Generic->throw(
        ident => "Invalid parameter",
        extra => "Invalid protocol version: $ver");
}

sub _using_legacy_oauth10 {
    my $self = shift;
    return 1 if $self->protocol_version eq '1.0';
    return 0;
}

# How many requests per second can reasonably happen, as 2 power
const my $_NONCE_UNIQ_BITS => 6;
const my $_NONCE_UNIQ_MAX => (2 ** $_NONCE_UNIQ_BITS);
const my $_NONCE_RANDOM_MAX => (2 ** (31 - $_NONCE_UNIQ_BITS));

sub _nonce {
    # This ensures no collisions in succeessive requests (after all we need no collision within 1s)
    state $counter = 0;
    $counter = ($counter + 1) % $_NONCE_UNIQ_MAX;
    # And this adds general randomness
    return $counter + $_NONCE_UNIQ_MAX * int(rand($_NONCE_RANDOM_MAX));
}

# Checks response: throws exception on error, parses and returns param hash
# Second param, if present, is a list of required parameters
sub _parse_form_reply {
    my ($http_response, $required_params) = @_;

    my $params = parse_http_msg_form($http_response, 1);

    if($required_params) {
        foreach my $par_name (@$required_params) {
            # FIXME: bind http_response
            OAuthomatic::Error::Generic->throw(
                ident => "Invalid reply obtained",
                extra => "Missing required item in parsed reply: $par_name\n"
                  . "Reply items: " . join(", ", keys %$params). "\n")
                unless $params->{$par_name};
        }
    }

    return $params;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Caller - actually make OAuth-signed calls

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

Sign OAuth calls and execute them.

This object is mostly used internally by L<OAuthomatic>, but may be useful
separately if you want to implement initialization scheme by yourself but
prefer it's API and structural exceptions to raw L<Net::OAuth>.

=head1 METHODS

=head2 create_authorization_url($callback_url) => TemporaryCred

Calculates URL which user should visit to authorize app (and
associated temporary token).

=head2 create_token_cred

Acquires access token, preserves them in the object (so future calls
will be authenticated), and return (so it can be saved etc).

=head2 build_oauth_request(method => ..., ...)

Prepare properly signed L<HTTP::Request> but do not execute it, just
return ready-to-be-sent object.

Parameters: identical as in L</execute_oauth_request>

=head2 execute_oauth_request(method => $method, url => $url, url_args => $args,
                             body_form => $body_form, body => $body,
                             content_type => $content_type)

Make a request to C<url> using the given HTTP method and signing
request with OAuth credentials.

=over 4

=item method

One of C<GET>, C<POST>, C<PUT>, C<DELETE>.

=item url

Actual URL to call (C<http://some.site.com/api/...>)

=item url_args (optional)

Additional arguments to escape and add to the URL. This is simply shortcut,
three calls below are equivalent:

    $c->execute_oauth_request(method => "GET",
        url => "http://some.where/api?x=1&y=2&z=a+b");

    $c->execute_oauth_request(method => "GET",
        url => "http://some.where/api",
        url_args => {x => 1, y => 2, z => 'a b'});

    $c->execute_oauth_request(method => "GET",
        url => "http://some.where/api?x=1",
        url_args => {y => 2, z => 'a b'});

=item body_form OR body

Exactly one of those must be specified for POST and PUT (none for GET or DELETE).

Specifying C<body_form> means, that we are creating www-urlencoded
form. Parameters will be included in OAuth signature. Example:

    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body_form => {par1 => 'abc', par2 => 'd f'});

Note that this is not just a shortcut for setting body to already
serialized form.  Case of urlencoded form is treated in a special way
by OAuth (those values impact OAuth signature). To avoid signature
verification errors, OAuthomatic will reject such attempts:

    # WRONG AND WILL FAIL. Use body_form if you post form.
    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body => 'par1=abc&par2=d+f',
        content_type => 'application/x-www-form-urlencoded');

Specifying C<body> means, that we post non-form body (for example
JSON, XML or even binary data). Example:

    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body => "<product><item-no>3434</item-no><price>334.22</price></product>",
        content_type => "application/xml; charset=utf-8");

Value of body can be either binary string (which will be posted as-is), or
perl unicode string (which will be encoded according to the content type, what by
default means utf-8).

Such content is not covered by OAuth signature, so less secure (at
least if it is posted over non-SSL connection).

For longer bodies, references are supported:

    $c->execute_oauth_request(method => "POST",
        url => "http://some.where/api",
        body => \$body_string,
        content_type => "application/xml; charset=utf-8");

=item content_type

Used to set content type of the request. If missing, it is set to
C<text/plain; charset=utf-8> if C<body> param is specified and to
C<application/x-www-form-urlencoded; charset=utf-8> if C<body_form>
param is specified.

Note that module author does not test behaviour on encodings different
than utf-8 (although they may work).

=back

=head2 _execute_oauth_request_ext

Common code for API and OAuth-protocol calls. Uses all parameters
described in L</execute_oauth_request> and two additional:

=over 4

=item class

ProtectedResource, UserAuth, RequestToken etc (XXX from
Net::Oauth::XXXXRequest)

=item token

Actual token to use while signing (skip to use only client token) -
either $self->token_cred, or some temporary_cred, depending on task at
hand.

=back

=head1 ATTRIBUTES

=head2 config

L<OAuthomatic::Config> object used to bundle various configuration params.

=head2 server

L<OAuthomatic::Server> object used to bundle server-related configuration params.

=head1 INTERNAL METHODS

=head2 _build_oauth_request_ext

Common code for API and OAuth-protocol calls. Uses all parameters
described in L</execute_oauth_request> and some additional:

=over 4

=item class

ProtectedResource, UserAuth, RequestToken etc (XXX from Net::Oauth::XXXXRequest)

=item token

Actual token to use while signing (skip to use only client token) - either $self->token_cred,
or some temporary_cred, depending on task at hand.

=item verifier

Verifier to be added to access token creation.

=item callback

Callback url for temporary token creation.

=item auth_in_post

True if authorization tokens are to be merged into POST body, false if
they are to be preserved in Authorize header.

=back

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
