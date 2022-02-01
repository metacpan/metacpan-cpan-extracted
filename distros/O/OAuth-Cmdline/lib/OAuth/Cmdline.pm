###########################################
package OAuth::Cmdline;
###########################################
use strict;
use warnings;
use URI;
use YAML qw( DumpFile LoadFile );
use HTTP::Request::Common;
use URI;
use LWP::UserAgent;
use Log::Log4perl qw(:easy);
use JSON qw( from_json );
use MIME::Base64;
use Moo;

our $VERSION = '0.07'; # VERSION
# ABSTRACT: OAuth2 for command line applications using web services

has client_id     => ( is => "rw" );
has client_secret => ( is => "rw" );
has local_uri      => ( 
  is      => "rw",
  default => "http://localhost:8082",
);
has homedir => ( 
  is      => "ro",
  default => glob '~',
);
has base_uri    => ( is => "rw" );
has login_uri   => ( is => "rw" );
has site        => ( is => "rw" );
has scope       => ( is => "rw" );
has token_uri   => ( is => "rw" );
has redir_uri   => ( is => "rw" );
has access_type => ( is => "rw" );
has raise_error => ( is => "rw" );

###########################################
sub redirect_uri {
###########################################
    my( $self ) = @_;

    return $self->local_uri . "/callback";
}

###########################################
sub cache_file_path {
###########################################
    my( $self ) = @_;

      # creds saved  ~/.[site].yml
    return $self->homedir . "/." .
           $self->site . ".yml";
}

###########################################
sub full_login_uri {
###########################################
    my( $self ) = @_;

    my $full_login_uri = URI->new( $self->login_uri );

    $full_login_uri->query_form (
      client_id     => $self->client_id(),
      response_type => "code",
      (defined $self->redirect_uri() ?
        ( redirect_uri  => $self->redirect_uri() ) :
        ()
      ),
      scope         => $self->scope(),
      ($self->access_type() ?
          (access_type => $self->access_type()) : ()),
    );

    DEBUG "full login uri: $full_login_uri";
    return $full_login_uri;
}

###########################################
sub access_token {
###########################################
    my( $self ) = @_;

    if( $self->token_expired() ) {
        $self->token_refresh() or LOGDIE "Token refresh failed";
    }

    my $cache = $self->cache_read();
    return $cache->{ access_token };
}

###########################################
sub authorization_headers {
###########################################
    my( $self ) = @_;

    return ( 
        'Authorization' => 
            'Bearer ' . $self->access_token
    );
}

###########################################
sub token_refresh_authorization_header {
###########################################
    my( $self ) = @_;

    return ();
}

###########################################
sub token_refresh {
###########################################
    my( $self ) = @_;

    DEBUG "Refreshing access token";

    my $cache = $self->cache_read();

    $self->token_uri( $cache->{ token_uri } );

    my $req = &HTTP::Request::Common::POST(
        $self->token_uri,
        {
            refresh_token => $cache->{ refresh_token },
            client_id     => $cache->{ client_id },
            client_secret => $cache->{ client_secret },
            grant_type    => 'refresh_token',
        },
        $self->token_refresh_authorization_header(),
    );

    my $ua = LWP::UserAgent->new();
    my $resp = $ua->request($req);

    if( $resp->is_success() ) {
        my $data = 
        from_json( $resp->content() );

        DEBUG "Token refreshed, will expire in $data->{ expires_in } seconds";

        $cache->{ access_token } = $data->{ access_token };
        $cache->{ expires }      = $data->{ expires_in } + time();

    ($cache, $data) = $self->update_refresh_token($cache, $data);

        $self->cache_write( $cache );
        return 1;
    }

    ERROR "Token refresh failed: ", $resp->status_line();
    return undef;
}

###########################################
sub update_refresh_token {
###########################################
    my( $self, $cache, $data ) = @_;
    
    return ($cache, $data);
}

###########################################
sub token_expired {
###########################################
    my( $self ) = @_;

    my $cache = $self->cache_read();

    my $time_remaining = $cache->{ expires } - time();

    if( $time_remaining < 300 ) {
        if( $time_remaining < 0 ) {
            DEBUG "Token expired ", -$time_remaining, " seconds ago";
        } else {
            DEBUG "Token will expire in $time_remaining seconds";
        }

        DEBUG "Token needs to be refreshed.";
        return 1;
    }

    return 0;
}

###########################################
sub token_expire {
###########################################
    my( $self ) = @_;

    my $cache = $self->cache_read();

    $cache->{ expires } = time() - 1;
    $self->cache_write( $cache );
}

###########################################
sub cache_read {
###########################################
    my( $self ) = @_;

    if( ! -f $self->cache_file_path ) {
        LOGDIE "Cache file ", $self->cache_file_path, " not found. ",
          "See GETTING STARTED in the docs for how to get started.";
    }

    return LoadFile $self->cache_file_path;
}

###########################################
sub cache_write {
###########################################
    my( $self, $cache ) = @_;

    my $old_umask = umask 0177;

    DumpFile $self->cache_file_path, $cache;

    umask $old_umask;
    return 1;
}

###########################################
sub tokens_get_additional_params {
###########################################
    my( $self, $params ) = @_;

    return $params;
}

###########################################
sub tokens_get {
###########################################
    my( $self, $code ) = @_;

    my $req = &HTTP::Request::Common::POST(
        $self->token_uri, $self->tokens_get_additional_params(
        [
            code          => $code,
            client_id     => $self->client_id,
            client_secret => $self->client_secret,
            redirect_uri  => $self->redirect_uri,
            grant_type    => 'authorization_code',
        ])
    );

    my $ua = LWP::UserAgent->new();
    my $resp = $ua->request($req);

    if( $resp->is_success() ) {
        my $json = $resp->content();
        DEBUG "Received: [$json]";
        my $data = from_json( $json );

        return ( $data->{ access_token }, 
            $data->{ refresh_token },
            $data->{ expires_in } );
    }

    my $error;
    eval {
        my $json = $resp->content();
        DEBUG "Received: [$json]",
        my $data = from_json( $json );
        $error = $data->{'error'};
    };
    # An exception will be thrown if the content is not JSON
    if ($@) {
        $error = $resp->content();
    }

    LOGDIE $resp->status_line() . ' - ' . $error . "\n";
    return undef;
}

###########################################
sub tokens_collect {
###########################################
    my( $self, $code ) = @_;

    my( $access_token, $refresh_token,
        $expires_in ) = $self->tokens_get( $code );

    my $cache = {
        access_token  => $access_token,
        refresh_token => $refresh_token,
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        expires       => time() + $expires_in,
        token_uri     => $self->token_uri,
    };

    $self->cache_write( $cache );
}

###########################################
sub http_get {
###########################################
    my( $self, $url, $query ) = @_;

    my $ua = LWP::UserAgent->new();

    my $uri = URI->new( $url );
    $uri->query_form( @$query ) if defined $query;

    DEBUG "Fetching $uri";

    my $resp = $ua->get( $uri, 
        $self->authorization_headers, @$query );

    if( $resp->is_error ) {
        if( $self->raise_error ) {
            die $resp->message;
        }
        return undef;
    }

    return $resp->decoded_content;
}

###########################################
sub client_init_conf_check {
###########################################
    my( $self, $url ) = @_;

    my $conf = { };
    if( -f $self->cache_file_path ) {
        $conf = $self->cache_read();
    }

    if( !exists $conf->{ client_id } or
        !exists $conf->{ client_secret } ) {
        die "You need to register your application on " .
          "$url and add the client_id and " .
          "client_secret entries to " . $self->cache_file_path . "\n";
    }
    
    $self->client_id( $conf->{ client_id } );
    $self->client_secret( $conf->{ client_secret } );

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline - OAuth2 for command line applications using web services

=head1 VERSION

version 0.07

=head1 SYNOPSIS

      # Use a site-specific class instead of the parent class, see
      # description below for generic cases

    my $oauth = OAuth::Cmdline::GoogleDrive->new( );
    $oauth->access_token();

=head1 DESCRIPTION

OAuth::Cmdline helps standalone command line scripts to deal with 
web services requiring OAuth access tokens.

=head1 WARNING: LIMITED ALPHA RELEASE

While C<OAuth::Cmdline> has been envisioned to work with 
various OAuth-controlled web services, it is currently tested with the
following services, shown below with their subclasses:

=over

=item B<OAuth::Cmdline::GoogleDrive>
- Google Drive

=item B<OAuth::Cmdline::Spotify>
- Spotify

=item B<OAuth::Cmdline::MicrosoftOnline>
- Azure AD and other OAuth2-authenticated services that use the Microsoft
Online common authentication endpoint (tested with Azure AD via the Graph
API)

=item B<OAuth::Cmdline::Automatic>
- Automatic.com car plugin

=item B<OAuth::Cmdline::Youtube>
- Youtube viewer reports

=item B<OAuth::Cmdline::Smartthings>
- Smartthings API

=back

If you want to use this module for a different service, go ahead and try
it, it might just as well work. In this case, specify the C<site> parameter,
which determines the name of the cache file with the access token and
other settings in your home directory:

      # Will use standard OAuth techniques and save your
      # tokens in ~/.some-other.site.yml
    my $oauth = OAuth::Cmdline->new( site => "some-other-site" );

=head1 GETTING STARTED

To obtain the initial set of access and refresh tokens from the 
OAuth-controlled site, you need to register your command line app
with the site and you'll get a "Client ID" and a "Client Secret" 
in return. Also, the site's SDK will point out the "Login URI" and
the "Token URI" to be used with the particular service.
Then, run the following script (the example uses the Spotify web service)

    use OAuth::Cmdline;
    use OAuth::Cmdline::Mojo;

    my $oauth = OAuth::Cmdline::GoogleDrive->new(
        client_id     => "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        client_secret => "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY",
        login_uri     => "https://accounts.google.com/o/oauth2/auth",
        token_uri     => "https://accounts.google.com/o/oauth2/token",
        scope         => "user-read-private",
    );
    
    my $app = OAuth::Cmdline::Mojo->new(
        oauth => $oauth,
    );
    
    $app->start( 'daemon', '-l', $oauth->local_uri );

and point a browser to the URL displayed at startup. Clicking on the
link displayed will take you to the OAuth-controlled site, where you need
to log in and allow the app access to the user data, following the flow
provided on the site. The site will then redirect to the web server
started by the script, which will receive an initial access token with 
an expiration date and a refresh token from the site, and store it locally
in the cache file in your home directory (~/.sitename.yml).

=head1 ACCESS TOKEN ACCESS

Once the cache file has been initialized, the application can use the
C<access_token()> method in order to get a valid access token. If 
C<OAuth::Cmdline> finds out that the cached access token is expired, 
it'll automatically refresh it for you behind the scenes.

C<OAuth::Cmdline> also offers a convenience function for providing a hash
with authorization headers for use with LWP::UserAgent:

    my $resp = $ua->get( $url, $oauth->authorization_headers );

This will create an "Authorization" header based on the access token and
include it in the request to the web service.

=head2 Public Methods

=over 4

=item C<new()>

Instantiate a new OAuth::Cmdline::XXX object. XXX stands for the specific
site's implementation, and can be "GoogleDrive" or one of the other
subclasses listed above.

=item C<authorization_headers()>

Returns the HTTP header name and value the specific site requires for
authentication. For example, in GoogleDrive's case, the values are:

    AuthorizationBearer xxxxx.yyy

The method is used to pass the authentication header key and value 
to an otherwise unauthenticated web request, like

    my $resp = $ua->get( $url, $oauth->authorization_headers );

=item C<token_expired()>

(Internal) Check if the access token is expired and will be refreshed
on the next call of C<authorization_headers()>.

=item C<token_expire()>

Force the expiration of the access token, so that the next request 
obtains a new one.

=back

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
