package Net::OAuth::Simple;

use warnings;
use strict;
our $VERSION = "1.7";

use URI;
use LWP;
use CGI;
use HTTP::Request::Common ();
use Carp;
use Net::OAuth;
use Scalar::Util qw(blessed);
use Digest::SHA;
use File::Basename;
require Net::OAuth::Request;
require Net::OAuth::RequestTokenRequest;
require Net::OAuth::AccessTokenRequest;
require Net::OAuth::ProtectedResourceRequest;
require Net::OAuth::XauthAccessTokenRequest;
require Net::OAuth::UserAuthRequest;

BEGIN {
    eval {  require Math::Random::MT };
    unless ($@) {
        Math::Random::MT->import(qw(srand rand));
    }
}

our @required_constructor_params = qw(consumer_key consumer_secret);
our @access_token_params         = qw(access_token access_token_secret);
our @general_token_params        = qw(general_token general_token_secret);

=head1 NAME

Net::OAuth::Simple - a simple wrapper round the OAuth protocol

=head1 SYNOPSIS

First create a sub class of C<Net::OAuth::Simple> that will do you requests
for you.

    package Net::AppThatUsesOAuth;

    use strict;
    use base qw(Net::OAuth::Simple);


    sub new {
        my $class  = shift;
        my %tokens = @_;
        return $class->SUPER::new( tokens => \%tokens,
                                   protocol_version => '1.0a',
                                   urls   => {
                                        authorization_url => ...,
                                        request_token_url => ...,
                                        access_token_url  => ...,
                                   });
    }

    sub view_restricted_resource {
        my $self = shift;
        my $url  = shift;
        return $self->make_restricted_request($url, 'GET');
    }

    sub update_restricted_resource {
        my $self         = shift;
        my $url          = shift;
        my %extra_params = @_;
        return $self->make_restricted_request($url, 'POST', %extra_params);
    }
    1;


Then in your main app you need to do

    # Get the tokens from the command line, a config file or wherever
    my %tokens  = get_tokens();
    my $app     = Net::AppThatUsesOAuth->new(%tokens);

    # Check to see we have a consumer key and secret
    unless ($app->consumer_key && $app->consumer_secret) {
        die "You must go get a consumer key and secret from App\n";
    }

    # If the app is authorized (i.e has an access token and secret)
    # Then look at a restricted resourse
    if ($app->authorized) {
        my $response = $app->view_restricted_resource;
        print $response->content."\n";
        exit;
    }


    # Otherwise the user needs to go get an access token and secret
    print "Go to ".$app->get_authorization_url."\n";
    print "Then hit return after\n";
    <STDIN>;

    my ($access_token, $access_token_secret) = $app->request_access_token;

    # Now save those values


Note the flow will be somewhat different for web apps since the request token
and secret will need to be saved whilst the user visits the authorization url.

For examples go look at the C<Net::FireEagle> module and the C<fireeagle> command
line script that ships with it. Also in the same distribution in the C<examples/>
directory is a sample web app.

=head1 METHODS

=cut

=head2 new [params]

Create a new OAuth enabled app - takes a hash of params.

One of the keys of the hash must be C<tokens>, the value of which
must be a hash ref with the keys:

=over 4

=item consumer_key

=item consumer_secret

=back

Then, when you have your per-use access token and secret you
can supply

=over 4

=item access_token

=item access_secret

=back

Another key of the hash must be C<urls>, the value of which must
be a hash ref with the keys

=over 4

=item authorization_url

=item request_token_url

=item access_token_url

=back

If you pass in a key C<protocol_version> with a value equal to B<1.0a> then
the newest version of the OAuth protocol will be used. A value equal to B<1.0> will
mean the old version will be used. Defaults to B<1.0a>

You can pass in your own User Agent by using the key C<browser>.

If you pass in C<return_undef_on_error> then instead of C<die>-ing on error
methods will return undef instead and the error can be retrieved using the
C<last_error()> method. See the section on B<ERROR HANDLING>.

=cut

sub new {
    my $class  = shift;
    my %params = @_;
    $params{protocol_version} ||= '1.0a';
    my $client = bless \%params, $class;

    # Set up LibWWWPerl for HTTP requests
    $client->{browser} ||= LWP::UserAgent->new;

    # Verify arguments
    $client->_check;

    # Client Object
    return $client;
}

# Validate required constructor params
sub _check {
    my $self = shift;

    foreach my $param ( @required_constructor_params ) {
        unless ( defined $self->{tokens}->{$param} ) {
            return $self->_error("Missing required parameter '$param'");
        }
    }

    return $self->_error("browser must be a LWP::UserAgent")
        unless blessed $self->{browser} && $self->{browser}->isa('LWP::UserAgent');
}

=head2 oauth_1_0a

Whether or not we're using 1.0a version of OAuth (necessary for,
amongst others, FireEagle)

=cut
sub oauth_1_0a {
    my $self = shift;
    return $self->{protocol_version } eq '1.0a';
}

=head2 authorized

Whether the client has the necessary credentials to be authorized.

Note that the credentials may be wrong and so the request may still fail.

=cut

sub authorized {
    my $self = shift;
    foreach my $param ( @access_token_params ) {
        return 0 unless defined $self->{tokens}->{$param} && length $self->{tokens}->{$param};
    }
    return 1;
}

=head2 signature_method [method]

The signature method to use.

Defaults to HMAC-SHA1

=cut
sub signature_method {
    my $self = shift;
    $self->{signature_method} = shift if @_;
    return $self->{signature_method} || 'HMAC-SHA1';
}

=head2 tokens

Get all the tokens.

=cut
sub tokens {
    my $self = shift;
    if (@_) {
        my %tokens = @_;
        $self->{tokens} = \%tokens;
    }
    return %{$self->{tokens}||{}};
}

=head2 consumer_key [consumer key]

Returns the current consumer key.

Can optionally set the consumer key.

=cut

sub consumer_key {
    my $self = shift;
    $self->_token('consumer_key', @_);
}

=head2 consumer_secret [consumer secret]

Returns the current consumer secret.

Can optionally set the consumer secret.

=cut

sub consumer_secret {
    my $self = shift;
    $self->_token('consumer_secret', @_);
}


=head2 access_token [access_token]

Returns the current access token.

Can optionally set a new token.

=cut

sub access_token {
    my $self = shift;
    $self->_token('access_token', @_);
}

=head2 access_token_secret [access_token_secret]

Returns the current access token secret.

Can optionally set a new secret.

=cut

sub access_token_secret {
    my $self = shift;
    return $self->_token('access_token_secret', @_);
}

=head2 general_token [token]

Get or set the general token.

See documentation in C<new()>

=cut

sub general_token {
     my $self = shift;
     $self->_token('general_token', @_);
}

=head2 general_token_secret [secret]

Get or set the general token secret.

See documentation in C<new()>

=cut

sub general_token_secret {
    my $self = shift;
    $self->_token('general_token_secret', @_);
}

=head2 authorized_general_token

Is the app currently authorized for general token requests.

See documentation in C<new()>

=cut

sub authorized_general_token {
     my $self = shift;
     foreach my $param ( @general_token_params ) {
        return 0 unless defined $self->$param();
     }
     return 1;
}


=head2 request_token [request_token]

Returns the current request token.

Can optionally set a new token.

=cut

sub request_token {
    my $self = shift;
    $self->_token('request_token', @_);
}


=head2 request_token_secret [request_token_secret]

Returns the current request token secret.

Can optionally set a new secret.

=cut

sub request_token_secret {
    my $self = shift;
    return $self->_token('request_token_secret', @_);
}

=head2 verifier [verifier]

Returns the current oauth_verifier.

Can optionally set a new verifier.

=cut

sub verifier {
    my $self = shift;
    return $self->_param('verifier', @_);
}

=head2 callback [callback]

Returns the oauth callback.

Can optionally set the oauth callback.

=cut

sub callback {
    my $self = shift;
    $self->_param('callback', @_);
}

=head2 callback_confirmed [callback_confirmed]

Returns the oauth callback confirmed.

Can optionally set the oauth callback confirmed.

=cut

sub callback_confirmed {
    my $self = shift;
    $self->_param('callback_confirmed', @_);
}


sub _token {
    my $self = shift;
    $self->_store('tokens', @_);
}

sub _param {
    my $self = shift;
    $self->_store('params', @_);
}

sub _store {
    my $self = shift;
    my $ns   = shift;
    my $key  = shift;
    $self->{$ns}->{$key} = shift if @_;
    return $self->{$ns}->{$key};
}

=head2 authorization_url

Get the url the user needs to visit to authorize as a URI object.

Note: this is the base url - not the full url with the necessary OAuth params.

=cut
sub authorization_url {
    my $self = shift;
    return $self->_url('authorization_url', @_);
}


=head2 request_token_url

Get the url to obtain a request token as a URI object.

=cut
sub request_token_url {
    my $self = shift;
    return $self->_url('request_token_url', @_);
}

=head2 access_token_url

Get the url to obtain an access token as a URI object.

=cut
sub access_token_url {
    my $self = shift;
    return $self->_url('access_token_url', @_);
}

sub _url {
    my $self = shift;
    my $key  = shift;
    $self->{urls}->{$key} = shift if @_;
    my $url  = $self->{urls}->{$key} || return;;
    return URI->new($url);
}

# generate a random number
sub _nonce {
    return int( rand( 2**32 ) );
}

=head2 request_access_token [param[s]]

Request the access token and access token secret for this user.

The user must have authorized this app at the url given by
C<get_authorization_url> first.

Returns the access token and access token secret but also sets
them internally so that after calling this method you can
immediately call a restricted method.

If you pass in a hash of params then they will added as parameters to the URL.

=cut

sub request_access_token {
    my $self   = shift;
    my %params = @_;
    my $url    = $self->access_token_url;

    $params{token}        = $self->request_token        unless defined $params{token};
    $params{token_secret} = $self->request_token_secret unless defined $params{token_secret};

    if ($self->oauth_1_0a) {
        $params{verifier} = $self->verifier                             unless defined $params{verifier};
        return $self->_error("You must pass a verified parameter when using OAuth v1.0a") unless defined $params{verifier};

    }


    my $access_token_response = $self->_make_request(
        'Net::OAuth::AccessTokenRequest',
        $url, 'POST',
        %params,
    );

    return $self->_decode_tokens($url, $access_token_response);
}

sub _decode_tokens {
    my $self                  = shift;
    my $url                   = shift;
    my $access_token_response = shift;

    # Cast response into CGI query for EZ parameter decoding
    my $access_token_response_query =
      new CGI( $access_token_response->content );

    # Split out token and secret parameters from the access token response
    $self->access_token($access_token_response_query->param('oauth_token'));
    $self->access_token_secret($access_token_response_query->param('oauth_token_secret'));

    delete $self->{tokens}->{$_} for qw(request_token request_token_secret verifier);

    return $self->_error("$url did not reply with an access token")
      unless ( $self->access_token && $self->access_token_secret );

    return ( $self->access_token, $self->access_token_secret );

}

=head2 xauth_request_access_token [param[s]]

The same as C<request_access_token> but for xAuth.

For more information on xAuth see

    http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-oauth-access_token-for-xAuth

You must pass in the parameters

    x_auth_username
    x_auth_password
    x_auth_mode

You must have HTTPS enabled for LWP::UserAgent.

See C<examples/twitter_xauth> for a sample implementation.

=cut
sub xauth_request_access_token {
    my $self = shift;
    my %params = @_;
    my $url = $self->access_token_url;
    $url =~ s !^http:!https:!; # force https

    my %xauth_params = map { $_ => $params{$_} }
        grep {/^x_auth_/}
        @{Net::OAuth::XauthAccessTokenRequest->required_message_params};

    my $access_token_response = $self->_make_request(
        'Net::OAuth::XauthAccessTokenRequest',
        $url, 'POST',
        %xauth_params,
    );

    return $self->_decode_tokens($url, $access_token_response);
}

=head2 request_request_token [param[s]]

Request the request token and request token secret for this user.

This is called automatically by C<get_authorization_url> if necessary.

If you pass in a hash of params then they will added as parameters to the URL.

=cut


sub request_request_token {
    my $self   = shift;
    my %params = @_;
    my $url    = $self->request_token_url;

    if ($self->oauth_1_0a) {
        $params{callback} = $self->callback                             unless defined $params{callback};
        return $self->_error("You must pass a callback parameter when using OAuth v1.0a") unless defined $params{callback};
    }

    my $request_token_response = $self->_make_request(
        'Net::OAuth::RequestTokenRequest',
        $url, 'GET',
        %params);

    return $self->_error("GET for $url failed: ".$request_token_response->status_line)
      unless ( $request_token_response->is_success );

    # Cast response into CGI query for EZ parameter decoding
    my $request_token_response_query =
      new CGI( $request_token_response->content );

    # Split out token and secret parameters from the request token response
    $self->request_token($request_token_response_query->param('oauth_token'));
    $self->request_token_secret($request_token_response_query->param('oauth_token_secret'));
    $self->callback_confirmed($request_token_response_query->param('oauth_callback_confirmed'));

    # Hack to deal with bug in older versions of oauth-php (See https://code.google.com/p/oauth-php/issues/detail?id=60)
    $self->callback_confirmed($request_token_response_query->param('oauth_callback_accepted'))
      unless $self->callback_confirmed;

    return $self->_error("Response does not confirm to OAuth1.0a. oauth_callback_confirmed not received")
     if $self->oauth_1_0a && !$self->callback_confirmed;

}

=head2 get_authorization_url [param[s]]

Get the URL to authorize a user as a URI object.

If you pass in a hash of params then they will added as parameters to the URL.

=cut

sub get_authorization_url {
    my $self   = shift;
    my %params = @_;
    my $url  = $self->authorization_url;
    if (!defined $self->request_token) {
        $self->request_request_token(%params);
    }
    #$params{oauth_token}     = $self->request_token;
    $url->query_form(%params);
    my $req = $self->_build_request('Net::OAuth::UserAuthRequest', $url, "GET");
    return $req->normalized_request_url;
}

=head2 make_restricted_request <url> <HTTP method> [extra[s]]

Make a request to C<url> using the given HTTP method.

Any extra parameters can be passed in as a hash.

=cut
sub make_restricted_request {
    my $self     = shift;

    return $self->_error("This restricted request is not authorized") unless $self->authorized;

    return $self->_restricted_request( $self->access_token, $self->access_token_secret, @_ );
}

=head2 make_general_request <url> <HTTP method> [extra[s]]

Make a request to C<url> using the given HTTP method using
the general purpose tokens.

Any extra parameters can be passed in as a hash.

=cut
sub make_general_request {
    my $self  = shift;

    return $self->_error("This general request is not authorized") unless $self->authorized_general_token;

    return $self->_restricted_request( $self->general_token, $self->general_token_secret, @_ );
}

sub _restricted_request {
    my $self     = shift;
    my $token    = shift;
    my $secret   = shift;
    my $url      = shift;
    my $method   = shift;
    my %extras   = @_;
    my $response = $self->_make_request(
        'Net::OAuth::ProtectedResourceRequest',
        $url, $method,
        token            => $token,
        token_secret     => $secret,
        extra_params     => \%extras
    );
    return $response;
}

sub _make_request {
    my $self    = shift;
    my $class   = shift;
    my $url     = shift;
    my $method  = uc(shift);
    my @extra   = @_;

    my $request  = $self->_build_request($class, $url, $method, @extra);
    my $response = $self->{browser}->request($request);
    return $self->_error("$method on ".$request->normalized_request_url." failed: ".$response->status_line." - ".$response->content)
      unless ( $response->is_success );

    return $response;
}

use Data::Dumper;
sub _build_request {
    my $self    = shift;
    my $class   = shift;
    my $url     = shift;
    my $method  = uc(shift);
    my @extra   = @_;

    my $uri   = URI->new($url);
    my %query = $uri->query_form;
    $uri->query_form({});


    my $content;
    my $filename;
    if ('PUT' eq $method) {
      # Get the content (goes in the body), and hash the content for inclusion in the message
      my %params = @extra;
      $filename = delete $params{extra_params}->{filename};

      return $self->_error('Missing required parameter $filename') unless $filename;

      # Slurp the file from above
      my $content = "";
      $self->_read_file( $filename, sub { $content .= shift } ) ;
      ($filename) = fileparse($filename);


      # Net::OAuth doesn't seem to handle body hash, so do it ourselves

      # Per http://oauth.googlecode.com/svn/spec/ext/body_hash/1.0/oauth-bodyhash.html#parameter
      # If the OAuth signature method is HMAC-SHA1 or RSA-SHA1, SHA1 MUST be used as the body hash algorithm
      # No discussion of other signature methods, but the draft spec for OAuth2 predictably says that SHA256
      # should be used for HMAC-SHA256

      if ($self->signature_method eq 'HMAC-SHA1' || $self->signature_method eq 'RSA-SHA1') {
        $params{body_hash} = Digest::SHA::sha1_hex($content);
      } elsif ($self->signature_method eq 'HMAC-SHA256') {
        $params{body_hash} = Digest::SHA::sha256_hex($content);
      } else {
        return $self->_error("Unknown signature method: ".$self->signature_method);
      }

      @extra = %params;
    }



    my $request = $class->new(
        consumer_key     => $self->consumer_key,
        consumer_secret  => $self->consumer_secret,
        request_url      => $uri,
        request_method   => $method,
        signature_method => $self->signature_method,
        protocol_version => $self->oauth_1_0a ? Net::OAuth::PROTOCOL_VERSION_1_0A : Net::OAuth::PROTOCOL_VERSION_1_0,
        timestamp        => time,
        nonce            => $self->_nonce,
        extra_params     => \%query,
        @extra,
    );
    $request->add_optional_message_params('body_hash') if 'PUT' eq $method;
    $request->sign;
    return $self->_error("Couldn't verify request! Check OAuth parameters.")
      unless $request->verify;

    my $req_url = ('GET' eq $method || 'DELETE' eq $method) ? $request->to_url() : $url;

    my $req = HTTP::Request->new( $method => $req_url);

    if ('PUT' eq $method) {
      $req->header('Authorization' => $request->to_authorization_header(""));
      $req->header('Content-disposition' => qq!attachment; filename="$filename"!);
      $req->content($content);
    }

    if ('POST' eq $method) {
      # "@extra" params are the ones that don't start with oath_ in the hash
      # User passed them, they must want us to actually send them, huh?
      $request->add_optional_message_params($_) for grep { ! /^oauth_/ } keys %{$request->to_hash};
      $req->content_type('application/x-www-form-urlencoded');
      $req->content($request->to_post_body);
    }

    return $req;
}


sub _error {
    my $self = shift;
    my $mess = shift;
    if ($self->{return_undef_on_error}) {
        $self->{_last_error} = $mess;
    } else {
        croak $mess;
    }
    return undef;
}

=head2 last_error

Get the last error message.

Only works if C<return_undef_on_error> was passed in to the constructor.

See the section on B<ERROR HANDLING>.

=cut
sub last_error {
    my $self = shift;
    return $self->{_last_error};
}

=head2 load_tokens <file>

A convenience method for loading tokens from a config file.

Returns a hash with the token names suitable for passing to
C<new()>.

Returns an empty hash if the file doesn't exist.

=cut
sub load_tokens {
    my $class  = shift;
    my $file   = shift;
    my %tokens = ();
    return %tokens unless -f $file;

    $class->_read_file($file, sub {
        $_ = shift;
        chomp;
        next if /^#/;
        next if /^\s*$/;
        next unless /=/;
        s/(^\s*|\s*$)//g;
        my ($key, $val) = split /\s*=\s*/, $_, 2;
        $tokens{$key} = $val;
    });
    return %tokens;
}

=head2 save_tokens <file> [token[s]]

A convenience method to save a hash of tokens out to the given file.

=cut
sub save_tokens {
    my $class  = shift;
    my $file   = shift;
    my %tokens = @_;

    my $max    = 0;
    foreach my $key (keys %tokens) {
        $max   = length($key) if length($key)>$max;
    }

    open(my $fh, ">$file") || die "Couldn't open $file for writing: $!\n";
    foreach my $key (sort keys %tokens) {
        my $pad = " "x($max-length($key));
        print $fh "$key ${pad}= ".$tokens{$key}."\n";
    }
    close($fh);
}

sub _read_file {
    my $self = shift;
    my $file = shift;
    my $sub  = shift;

    open(my $fh, $file) || die "Couldn't open $file: $!\n";
    while (<$fh>) {
        $sub->($_) if $sub;
    }
    close($fh);
}

=head1 ERROR HANDLING

Originally this module would die upon encountering an error (inheriting behaviour
from the original Yahoo! code).

This is still the default behaviour however if you now pass

    return_undef_on_error => 1

into the constructor then all methods will return undef on error instead.

The error message is accessible via the C<last_error()> method.

=head1 GOOGLE'S SCOPE PARAMETER

Google's OAuth API requires the non-standard C<scope> parameter to be set
in C<request_token_url>, and you also explicitly need to pass an C<oauth_callback>
to C<get_authorization_url()> method, so that you can direct the user to your site
if you're authenticating users in Web Application mode. Otherwise Google will let
user grant acesss as a desktop app mode and doesn't redirect users back.

Here's an example class that uses Google's Portable Contacts API via OAuth:

    package Net::AppUsingGoogleOAuth;
    use strict;
    use base qw(Net::OAuth::Simple);

    sub new {
        my $class  = shift;
        my %tokens = @_;
        return $class->SUPER::new(
            tokens => \%tokens,
            urls   => {
                request_token_url => "https://www.google.com/accounts/OAuthGetRequestToken?scope=http://www-opensocial.googleusercontent.com/api/people",
                authorization_url => "https://www.google.com/accounts/OAuthAuthorizeToken",
                access_token_url  => "https://www.google.com/accounts/OAuthGetAccessToken",
            },
        );
    }

    package main;
    my $oauth = Net::AppUsingGoogleOAuth->new(%tokens);

    # Web application
    $app->redirect( $oauth->get_authorization_url( callback => "http://you.example.com/oauth/callback") );

    # Desktop application
    print "Open the URL and come back once you're authenticated!\n",
        $oauth->get_authorization_url;

See L<http://code.google.com/apis/accounts/docs/OAuth.html> and other
services API documentation for the possible list of I<scope> parameter value.

=head1 RANDOMNESS

If C<Math::Random::MT> is installed then any nonces generated will use a
Mersenne Twiser instead of Perl's built in randomness function.

=head1 EXAMPLES

There are example Twitter and Twitter xAuth 'desktop' apps and a FireEagle OAuth 1.0a web app
in the examples directory of the distribution.

=head1 BUGS

Non known

=head1 DEVELOPERS

The latest code for this module can be found at

    https://svn.unixbeard.net/simon/Net-OAuth-Simple

=head1 AUTHOR

Simon Wistow, C<<simon@thegestalt.org>>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-oauth-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OAuth-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OAuth::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OAuth-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OAuth-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OAuth-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OAuth-Simple/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Simon Wistow, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::OAuth::Simple
