package Net::OAuth2::Moosey::Client;
use Moose;

=head1 NAME

Net::OAuth2::Moosey::Client - OAuth 2.0 client for perl

=head1 VERSION

0.02

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

This is a perl implementation of the OAuth 2.0 protocol.

It is based on (forked from), and very similar in functionality to Keith Grennan's L<Net::OAuth2> module.

The major differences to the original L<Net::OAuth2> module are:

=over 2 

=item * Converted to use Moose

=item * Named parameters for all methods

=item * More documentation

=item * No demo code for a web application

=back

=head1 SYNOPSIS

  use Net::OAuth2::Moosey::Client;
  my %client_params = (
      site_url_base           => 'https://accounts.google.com/o/oauth2/auth',
      access_token_url_base   => 'https://accounts.google.com/o/oauth2/token',
      authorize_url_base      => 'https://accounts.google.com/o/oauth2/auth',
      scope                   => 'https://www.google.com/fusiontables/api/query',        
      client_id               => '123456789.apps.googleusercontent.com',
      client_secret           => 'atecSNTE23sthbjcasrCuw4i',
  );

  my $client = Net::OAuth2::Moosey::Client->new( %client_params );

  # Get a fresh access token
  $client->get_fresh_access_token();

  # Send a request
  my @post_args =  ( 'https://www.google.com/fusiontables/api/query',
    HTTP::Headers->new( Content_Type => 'application/x-www-form-urlencoded' ),
    sprintf( 'sql=%s', url_encode( 'SHOW TABLES' ) ) );
  my $response = $self->auth_client->post( @post_args );


=cut

use Carp;
use LWP::UserAgent;
use URI;
use JSON;
use HTTP::Request;
use HTTP::Request::Common;
use Net::OAuth2::Moosey::AccessToken;
use MooseX::Types::URI qw(Uri FileUri DataUri);
use MooseX::Log::Log4perl;
use YAML;

=head1 METHODS

=head2 new

=head3 ATTRIBUTES

=over 2

=item * client_id <Str>

ID for your application as given to you by your service provider.

=item * client_secret <Str>

Secret for your application as given to you by your service provider.

=item * scope <Uri>

Scope for which your are applying for access to.

e.g. https://www.google.com/fusiontables/api/query

=item * site_url_base <Uri>

Base url for OAuth.

e.g. https://accounts.google.com/o/oauth2/auth

=item * access_token_url_base <Uri>

Access token url.

e.g. https://accounts.google.com/o/oauth2/token

=item * authorize_url_base <Uri>

Authorize url.

e.g. https://accounts.google.com/o/oauth2/auth

=item * access_token_path <Str>

=item * authorize_path <Str>

The ..._path parameters are an alternative to their ..._url_base counterparts.
If used, the authorize_url will be built from the site_url_base and the _path.

=item * refresh_token <Str>

If known, the refresh token can be defined here
If not, it will be determined during a request.

=item * access_token <Str>

If known the access token can be defined here.
If not, it will be determined during a request.

=item * access_code <Str>

If known, the access code can be defined here.
It is only necessary if you have not yet got an access/refresh token.
If you are running in interactive mode (and access/refresh tokens are not defined),
you will be given a URL to open in a browser and copy the resulting code to the command line.

=item * token_store <Str>

Path to a file to store your tokens.
This can be the same file for multiple services - it is a simple YAML file with one entry per
client_id which stores your refresh and access tokens.

=item * redirect_uri <Str>

Only needs to be defined if using the 'webserver' profile.  The page to which the service provider
should redirect to after authorization.
For instances using the 'application' profile, the default 'urn:ietf:wg:oauth:2.0:oob' is used.

=item * access_token_method <Str>

GET or POST?

Default: POST

=item * bearer_token_scheme <Str>

Should be one of: auth-header, uri-query, form-body
   
Default: auth-header

=item * profile <Str>

Are you using this module as a webserver (users browser is forwarded to the authorization urls, and they
in turn redirect back to your redirect_uri), or as an application (interactively, no browser interaction
for authorization possible)?

Should be one of: application, webserver

Default: application

=item * interactive <Bool>

Are you running your program interactively (i.e. if necessary, do you want to have a prompt for, and paste
the authorization code from your browser on the command line?).

Options: 0, 1

Default: 1

=item * keep_alive <Int>

Should the LWP::UserAgent instance used have a connection cache, and how many connections should it cache?
Turning off keep_alive can make interaction with your service provider very slow, especially if it is
over an encrypted connection (which it should be).

Default: 1 (try 2 if your service provider requires frequent authorization token refreshing)

=item * user_agent <LWP::UserAgent>

It is not necessary to pass a UserAgent, but maybe you have a custom crafted instance which you want to reuse...

=item * access_token_object <Net::OAuth2::Moosey::AccessToken>

The access token object which manages always having a fresh token ready for you.

=back

=cut

has 'client_id'             => ( is => 'ro', isa => 'Str',                                           );
has 'client_secret'         => ( is => 'ro', isa => 'Str',                                           );
has 'scope'                 => ( is => 'ro', isa => Uri,     coerce => 1,                            );
has 'site_url_base'         => ( is => 'ro', isa => Uri,     coerce => 1,                            );
has 'access_token_url_base' => ( is => 'ro', isa => Uri,     coerce => 1,                            );
has 'authorize_url_base'    => ( is => 'ro', isa => Uri,     coerce => 1,                            );

has 'access_token_path'     => ( is => 'ro', isa => 'Str',                                           );
has 'authorize_path'	    => ( is => 'ro', isa => 'Str',                                           );
has 'refresh_token'         => ( is => 'ro', isa => 'Str',                                           );
has 'access_token'          => ( is => 'ro', isa => 'Str',                                           );
has 'access_code'           => ( is => 'rw', isa => 'Str',                                           );
has 'token_store'           => ( is => 'ro', isa => 'Str',                                           );

# TODO: RCL 2011-11-03 Test if is URI if profile eq 'webserver'
has 'redirect_uri'	    => ( is => 'ro', isa => 'Str', required => 1, 
                                 default => 'urn:ietf:wg:oauth:2.0:oob'                              );

has 'access_token_method'   => ( is => 'ro', isa => 'Str',  required => 1, default => 'POST'         );
has 'bearer_token_scheme'   => ( is => 'ro', isa => 'Str',  required => 1, default => 'auth-header'  );
has 'profile'               => ( is => 'ro', isa => 'Str',  required => 1, default => 'application'  );
has 'interactive'           => ( is => 'ro', isa => 'Bool', required => 1, default => 1              );
has 'keep_alive'            => ( is => 'ro', isa => 'Int',  required => 1, default => 1              );

has 'user_agent'            => ( 
    is          => 'ro', 
    isa         => 'LWP::UserAgent',
    writer      => '_set_user_agent',
    predicate   => '_has_user_agent',
    );

has 'access_token_object'   => ( is => 'rw',
    isa         => 'Net::OAuth2::Moosey::AccessToken',
    builder     => '_build_access_token_object',
    lazy        => 1,
    );


# Create a LWP::UserAgent if necessary
around 'user_agent' => sub {
    my $orig = shift;
    my $self = shift;
    unless( $self->_has_user_agent ){
        $self->_set_user_agent( LWP::UserAgent->new( 'keep_alive' => $self->keep_alive ) );
    }
    return $self->$orig;
};


# Because a valid combination of parameters is not possible to define with 'has',
# doing a more complex param check before new
before 'new' => sub{
    my $class = shift;
    my %params = @_;
    
    my $found_valid = 0;
    my @valid = ( 
        [ qw/client_id client_secret site_url_base/ ],
        [ qw/access_token no_refresh_token_ok/ ],
        [ qw/refresh_token site_url_base/ ],
        );
    FOUND_VALID:
    foreach( @valid ){
        my @test = @{ $_ };
        if( scalar( grep{ $params{$_} } @test ) == scalar( @test ) ){
            $found_valid = 1;
            last FOUND_VALID;
        }
    }
    if( not $found_valid ){
        die( "Not initialised with a valid combination of parameters...\n" . Dump( \%params ) );
    }
};

sub _build_access_token_object {
    my $self = shift;
    
    # Try to load an access token from the store first
    my $access_token = undef;
    my %token_params = ( client => $self );
    foreach( qw/client_id client_secret access_token access_code
        access_token_url refresh_token token_store user_agent/ ){
        $token_params{$_} = $self->$_ if $self->$_;
    }
    $access_token = Net::OAuth2::Moosey::AccessToken->new( %token_params );
    $access_token->sync_with_store;
    if( not $access_token->refresh_token ){
        my $profile = $self->profile;        

        # Interactive applications need to supply a code
        if( not $self->access_code ){
            if( $self->profile ne 'application' ){
                croak( "access_code required but not available" );
            }
            printf "Please authorize your application with this URL\n%s\n",
                $self->authorize_url();
            if( not $self->interactive ){
                #TODO: RCL 2011-11-02 Better handling for non-interactive. Maybe return the URL?
                exit;
            }
            print "Code: ";
            my $code = <STDIN>;
            chomp( $code );
            $self->access_code( $code );
        }

        my $request;
        if( $self->access_token_method eq 'POST' ){
            $request = POST( $self->access_token_url(), { $self->_access_token_params() } );
        } else {
            $request = HTTP::Request->new(
                $self->access_token_method => $self->access_token_url( $self->_access_token_params() ),
                );
        };
        
        my $response = $self->user_agent->request($request);
        if( not $response->is_success ){
            croak( "Fetch of access token failed: " . $response->status_line . ": " . $response->decoded_content );
        }
        
        my $res_params = _parse_json($response->decoded_content);
        $res_params = _parse_query_string($response->decoded_content) unless defined $res_params;
        if( not defined $res_params ){
            croak( "Unable to parse access token response '".substr($response->decoded_content, 0, 64)."'" );
        }
        
        #TODO: RCL 2011-11-02 Check that required values returned.
        # Write the returned values to the access token object
        foreach my $key( keys( %{ $res_params } ) ){
            # TODO: RCL 2011-11-02 Isn't there a has_accessor way of doing this?
            if( $access_token->meta->has_method( $key ) ){
                $access_token->$key( $res_params->{$key} );
            }else{
                warn( "Unknown key found in response parameters: $key\n" );
            }
        }
        $access_token->sync_with_store;
    }
    return $access_token;
}


=head2 refresh_access_token

Make the current access token expire, and request a fresh access token

=cut
sub refresh_access_token {
    my $self = shift;

    # Make it expire now
    $self->access_token_object->expires_at( time() );

    # Request a fresh access token
    $self->access_token_object->valid_access_token();
}

=head2 request

Submit a request.  This is a wrapper arround a basic LWP::UserAgent->request, but adds the necessary
headers with the access tokens necessary for an OAuth2 request.

=cut
sub request {
    my $self = shift;
    my ($method, $uri, $header, $content) = @_;
    my $request = HTTP::Request->new(
        $method => $self->_site_url($uri), $header, $content
    );
    # We assume a bearer token type, but could extend to other types in the future
    my @bearer_token_scheme = split ':', $self->bearer_token_scheme;
    if (lc($bearer_token_scheme[0]) eq 'auth-header') {
        # Specs suggest using Bearer or OAuth2 for this value, but OAuth appears to be the de facto accepted value.
        # Going to use OAuth until there is wide acceptance of something else.
        my $auth_scheme = $self->access_token_object->token_type || $bearer_token_scheme[1] || 'OAuth';
        $request->headers->push_header(Authorization => $auth_scheme . " " . $self->access_token_object->valid_access_token);
    }
    elsif (lc($bearer_token_scheme[0]) eq 'uri-query') {
        my $query_param = $bearer_token_scheme[1] || 'oauth_token';
        $request->uri->query_form($request->uri->query_form, $query_param => $self->access_token_object->valid_access_token);
    }
    elsif (lc($bearer_token_scheme[0]) eq 'form-body') {
        croak "Embedding access token in request body is only valid for 'application/x-www-form-urlencoded' content type"
        unless $request->headers->content_type eq 'application/x-www-form-urlencoded';
        my $query_param = $bearer_token_scheme[1] || 'oauth_token';
        $request->add_content(
            ((defined $request->content and length $request->content) ?  "&" : "") .  
            uri_escape($query_param) . '=' . uri_escape($self->valid_access_token)
        );
    }
    return $self->user_agent->request( $request );
}

=head2 post

A wrapper for the request method already defining the request method as POST

=cut
sub post {
    my $self = shift;
    $self->request( 'POST', @_ );
}

=head2 get

A wrapper for the request method already defining the request method as GET

=cut
sub get {
    my $self = shift;
    $self->request( 'GET', @_ );
}

=head2 authorize_url

Returns the authorization url

=cut
sub authorize_url {
    my $self = shift;
    return $self->_make_url("authorize", $self->_authorize_params( @_ ) );
}

=head2 access_token_url

Returns the access token url

=cut
sub access_token_url {
    return shift->_make_url("access_token", @_ );
}


# Internal method to prepare the necessary authorize parameters
sub _authorize_params {
    my $self = shift;
    my %options = @_;
    $options{scope}         ||= $self->scope;
    $options{client_id}     ||= $self->client_id;
    $options{response_type} ||= 'code';
    $options{redirect_uri}  ||= $self->redirect_uri;
    
    if( $self->profile eq 'webserver' ){
        # legacy for pre v2.09 (37Signals)
        $options{type}          =   'web_server';
    }
    return %options;
}

# Internal method to prepare the necessary access token parameters
sub _access_token_params {
    my $self = shift;
    my %options = @_;  
    $options{client_id}         ||= $self->client_id;
    $options{client_secret}     ||= $self->client_secret;
    $options{grant_type}        ||= 'authorization_code';
    $options{code}              = $self->access_code if $self->access_code;
    $options{redirect_uri}  ||= $self->redirect_uri;

    if( $self->profile eq 'webserver' ){
        # legacy for pre v2.09 (37Signals)
        $options{type}          = 'web_server';
    }
    
    return %options;
}

# The URL can be put together with various information... do what you can with what you've got!
sub _make_url {
    my $self = shift;
    my $thing = shift;
    my $path = $self->{"${thing}_url_base"} || $self->{"${thing}_path"} || "/oauth/${thing}";
    return $self->_site_url($path, @_);
}

# Internal method to return the site url built from the site_url_base
sub _site_url {
    my $self = shift;
    my $path = shift;
    my %params = @_;
    my $url;
    if( $self->site_url_base ) {
        $url = URI->new_abs($path, $self->site_url_base );
    }
    else {
        $url = URI->new($path);
    }
    if (@_) {
        $url->query_form($url->query_form , %params);
    }
    return $url;
}


# Parse the query string
sub _parse_query_string {
    my $str = shift;
    my $uri = URI->new;
    $uri->query($str);
    return {$uri->query_form};
}

# Parse json non-fataly
sub _parse_json {
    my $str = shift;
    my $obj = eval{local $SIG{__DIE__}; decode_json($str)};
    return $obj;
}

1;
=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robin Clarke

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 CONTRIBUTORS

Thanks to Keith Grennan for Net::OAuth2 on which this is based

=cut

