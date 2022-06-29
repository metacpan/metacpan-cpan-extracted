# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Response.pm
## Version v0.4.13
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/09/01
## Modified 2021/09/03
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Response;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use parent qw( Module::Generic );
    use Devel::Confess;
    use Apache2::Request;
    use Apache2::Const;
    use Apache2::Response ();
    use Apache2::RequestIO ();
    use Apache2::RequestRec ();
    use Apache2::SubRequest ();
    use Apache2::Const -compile => qw( :common :http );
    use APR::Request ();
    use APR::Request::Cookie;
    use Net::API::REST::Cookies;
    use Cookie::Baker ();
    use Scalar::Util;
    use Net::API::REST::Status;
    use Nice::Try;
    use URI::Escape ();
    our $VERSION = 'v0.4.13';
};

sub init
{
    my $self = shift( @_ );
    my $r;
    $r = shift( @_ ) if( @_ % 2 );
    ## Which is an Apache2::Request, but inherits everything from Apache2::RequestRec and APR::Request::Apache2
    $self->{request} = '';
    $self->{checkonly} = 0;
    $self->SUPER::init( @_ );
    $r ||= $self->{request};
    unless( $self->{checkonly} )
    {
        return( $self->error( "No Net::API::REST::Request was provided." ) ) if( !$r );
        return( $self->error( "Net::API::REST::Request provided ($r) is not an object!" ) ) if( !Scalar::Util::blessed( $r ) );
        return( $self->error( "I was expecting an Net::API::REST::Request, but instead I got \"$r\"." ) ) if( !$r->isa( 'Net::API::REST::Request' ) );
    }
    return( $self );
}

# Response header: <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials>
sub allow_credentials { return( shift->_set_get_one( 'Access-Control-Allow-Credentials', @_ ) ); }

# Response header <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers>
sub allow_headers { return( shift->_set_get_one( 'Access-Control-Allow-Headers', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>
sub allow_methods { return( shift->_set_get_one( 'Access-Control-Allow-Methods', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin>
sub allow_origin { return( shift->_set_get_one( 'Access-Control-Allow-Origin', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>
sub alt_svc { return( shift->_set_get_multi( 'Alt-Svc', @_ ) ); }

sub bytes_sent { return( shift->_try( '_request', 'bytes_sent' ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>
sub cache_control { return( shift->_set_get_one( 'Cache-Control', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>
sub clear_site_data { return( shift->_set_get_multi( 'Clear-Site-Data', @_ ) ); }

## Apache2::Connection
sub connection { return( shift->_try( '_request', 'connection' ) ); }

## Set the http code to be returned, e.g,:
## return( $resp->code( Apache2::Const:HTTP_OK ) );
sub code { return( shift->_try( '_request', 'status', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>
# XXX More work to be done here like create a disposition method to parse its content
sub content_disposition { return( shift->_set_get_one( 'Content-Disposition', @_ ) ); }

# sub content_encoding { return( shift->_request->content_encoding( @_ ) ); }
sub content_encoding
{
    my $self = shift( @_ );
    my( $pack, $file, $line ) = caller;
    my $sub = ( caller( 1 ) )[3];
    $self->message( 3, "Got called from package $pack in file $file at line $line in sub $sub with args: '", join( "', '", @_ ), "'." );
    try
    {
        return( $self->_request->content_encoding( @_ ) );
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to access Apache Request method \"content_encoding\": $e" ) );
    }
}

## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Language
sub content_language { return( shift->headers( 'Content-Language', @_ ) ); }

sub content_languages { return( shift->_try( '_request', 'content_languages', @_ ) ); }

## sub content_length { return( shift->headers( 'Content-Length', @_ ) ); }
## https://perl.apache.org/docs/2.0/api/Apache2/Response.html#toc_C_set_content_length_
sub content_length { return( shift->_try( '_request', 'set_content_length', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Location>
sub content_location { return( shift->_set_get_one( 'Content-Location', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>
sub content_range { return( shift->_set_get_one( 'Content-Range', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>
sub content_security_policy { return( shift->_set_get_one( 'Content-Security-Policy', @_ ) ); }

sub content_security_policy_report_only { return( shift->_set_get_one( 'Content-Security-Policy-Report-Only', @_ ) ); }

## Apache content_type method is special. It does not just set the content type
sub content_type { return( shift->_try( '_request', 'content_type', @_ ) ); }
# sub content_type { return( shift->headers( 'Content-Type', @_ ) ); }

sub cookie_new_ok_but_hang_on
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Cookie name was not provided." ) ) if( !$opts->{name} );
    ## No value is ok to remove a cookie, but it needs to be an empty string, not undef
    return( $self->error( "No value was provided for cookie \"$opts->{name}\"." ) ) if( !length( $opts->{value} ) && !defined( $opts->{value} ) );
    my @valid_params = qw( comment commentURL domain expires httponly name path port secure value version );
    my $hash = {};
    foreach my $k ( @valid_params )
    {
        $hash->{ $k } = $opts->{ $k } if( length( $opts->{ $k } ) );
    }
    $hash->{value} = '' if( !CORE::exists( $hash->{value} ) );
    $hash->{domain} ||= $self->request->server_hostname;
    $hash->{expires} =~ s/d/D/ if( $hash->{expires} );
    return( $self->error( "Cookie property \"expires\" should be either a unix timestamp, or a variable expiration such as +3h for in 3 hours or +2M for in 2 month. Was provided with '$hash->{expires}'" ) ) if( $hash->{expires} !~ /^(?:\d{10,}|[\+\-]?(\d+)([YMDhms]))$/ );
    ## expires:
    ## Get or set the future expire time for the cookie.  When assigning, the new value ($set) should match /^\+?(\d+)([YMDhms]?)$/ $2 qualifies the number in
    ## $1 as representing "Y"ears, "M"onths, "D"ays, "h"ours, "m"inutes, or "s"econds (if the qualifier is omitted, the number is interpreted as representing
    ## seconds).  As a special case, $set = "now" is equivalent to $set = "0".
    ## Stupidly, APR::Request::Cookie only accept positive relative timestamp, ie +7D is ok, but not -7D :(
    ## So we have to convert it ourself into a timestamp
    my $interval =
    {
        's' => 1,
        'm' => 60,
        'h' => 3600,
        'D' => 86400,
        'M' => 86400 * 30,
        'Y' => 86400 * 365,
    };
    ## If this is a negative relative timestamp, we convert it and compute the epoch
    if( substr( $hash->{expires}, 0, 1 ) eq '-' )
    {
        if( $hash->{expires} =~ /^[\+\-]?(\d+)([YMDhms])/ )
        {
            my $offset = ( $interval->{$2} || 1 ) * int( $1 );
            $hash->{expires} = time() - $offset;
        }
    }
    
    try
    {
        $self->message( 3, "Using Apache request pool '" . $self->_request->pool . "'." );
        my $c = APR::Request::Cookie->new( $self->_request->pool, %$hash );
        $self->message( 3, "Success, returning an APR::Request::Cookie '$c' (", ref( $c ), ") object with properties: ", sub{ $self->dumper( $hash ) } );
        return( $self->error( "Unable to create an APR::Request::Cookie object: $@ (" . APR::Request::Error . ")" ) ) if( !ref( $c ) && $@ );
        return( $c );
    }
    catch( $e )
    {
        $self->message( 3, "Failed creating an APR::Request::Cookie object, returning an error." );
        return( $self->error( "An error occurred while trying to call APR::Request::Cookie method \"new\": $e" ) );
    }
}

sub cookie_new
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Cookie name was not provided." ) ) if( !$opts->{name} );
    ## No value is ok to remove a cookie, but it needs to be an empty string, not undef
    # return( $self->error( "No value was provided for cookie \"$opts->{name}\"." ) ) if( !length( $opts->{value} ) && !defined( $opts->{value} ) );
    my $c = $self->request->cookies->make( $opts ) || return( $self->pass_error( $self->request->cookies->error ) );
    $self->message( 3, "Success, returning an (", ref( $c ), ") cookie object '$c' with properties: ", sub{ $self->dumper( $opts ) } );
    return( $c );
}

## Add or replace a cookie, but because the headers function of Apache2 is based on APR::Table
## there is no replace method, AND because the value of the headers is a string and not an object
## we have to crawl each already set cookie, parse them, compare them en replace them or add them
sub cookie_replace
{
    my $self = shift( @_ );
    my $cookie = shift( @_ ) || return( $self->error( "No cookie to add to outgoing headers was provided." ) );
    ## Expecting an APR::Request::Cookie object
    return( $self->error( "Cookie provided (", ref( $cookie ), ") is not an object." ) ) if( !Scalar::Util::blessed( $cookie ) );
    return( $self->error( "Cookie object provided (", ref( $cookie ), ") does not seem to have an \"as_string\" method." ) ) if( !$cookie->can( 'as_string' ) );
    ## We use err_headers_out() which makes it also possible to set cookies upon error (regular headers_out method cannot)
    my( @cookie_headers ) = $self->err_headers->get( 'Set-Cookie' );
    if( !scalar( @cookie_headers ) )
    {
        $self->err_headers->set( 'Set-Cookie' => $cookie->as_string );
    }
    else
    {
        ## Check each cookie header set to see if ours is one of them
        my $found = 0;
        for( my $i = 0; $i < scalar( @cookie_headers ); $i++ )
        {
            my $ref = Cookie::Baker::crush_cookie( $cookie_headers[ $i ] );
            if( CORE::exists( $ref->{ $cookie->name } ) )
            {
                $cookie_headers[ $i ] = $cookie->as_string;
                $found = 1;
            }
        }
        if( !$found )
        {
            $self->err_headers->add( 'Set-Cookie' => $cookie->as_string );
        }
        else
        {
            ## Remove all Set-Cookie headers
            $self->err_headers->unset( 'Set-Cookie' );
            ## Now, re-add our updated set
            foreach my $cookie_str ( @cookie_headers )
            {
                $self->err_headers->add( 'Set-Cookie' => $cookie_str );
            }
        }
    }
    return( $cookie );
}

sub cookie_set
{
    my $self = shift( @_ );
    my $cookie = shift( @_ ) || return( $self->error( "No cookie to add to outgoing headers was provided." ) );
    ## Expecting an APR::Request::Cookie object
    return( $self->error( "Cookie provided (", ref( $cookie ), ") is not an object." ) ) if( !Scalar::Util::blessed( $cookie ) );
    return( $self->error( "Cookie object provided (", ref( $cookie ), ") does not seem to have an \"as_string\" method." ) ) if( !$cookie->can( 'as_string' ) );
    $self->err_headers->set( 'Set-Cookie' => $cookie->as_string );
    return( $cookie );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy>
sub cross_origin_embedder_policy { return( shift->_set_get_one( 'Cross-Origin-Embedder-Policy', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy>
sub cross_origin_opener_policy { return( shift->_set_get_one( 'Cross-Origin-Opener-Policy', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Resource-Policy>
sub cross_origin_resource_policy { return( shift->_set_get_one( 'Cross-Origin-Resource-Policy', @_ ) ); }

sub cspro { return( shift->content_security_policy_report_only( @_ ) ); }

## e.g. custom_response( $status, $string );
## e.g. custom_response( Apache2::Const::AUTH_REQUIRED, "Authenticate please" );
#  package MyApache2::MyShop;
#  use Apache2::Response ();
#  use Apache2::Const -compile => qw(FORBIDDEN OK);
#  sub access {
#    my $r = shift;
# 
#    if (MyApache2::MyShop::tired_squirrels()) {
#        $r->custom_response(Apache2::Const::FORBIDDEN,
#            "It's siesta time, please try later");
#        return Apache2::Const::FORBIDDEN;
#    }
# 
#    return Apache2::Const::OK;
#  }
sub custom_response { return( shift->_try( '_request', 'custom_response', @_ ) ); }

sub decode
{
    my $self = shift( @_ );
    return( APR::Request::decode( shift( @_ ) ) );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Digest>
sub digest { return( shift->_set_get_one( 'Digest', @_ ) ); }

sub encode
{
    my $self = shift( @_ );
    return( APR::Request::encode( shift( @_ ) ) );
}

sub env
{
    my $self = shift( @_ );
    my $r = $self->request;
    if( @_ )
    {
        if( scalar( @_ ) == 1 )
        {
            my $v = shift( @_ );
            if( ref( $v ) eq 'HASH' )
            {
                foreach my $k ( sort( keys( %$v ) ) )
                {
                    $r->subprocess_env( $k => $v->{ $k } );
                }
            }
            else
            {
                return( $r->subprocess_env( $v ) );
            }
        }
        else
        {
            my $hash = { @_ };
            foreach my $k ( sort( keys( %$hash ) ) )
            {
                $r->subprocess_env( $k => $hash->{ $k } );
            }
        }
    }
    else
    {
        $r->subprocess_env;
    }
}

sub err_headers
{
    my $self = shift( @_ );
    my $out = $self->_request->err_headers_out;
    if( @_ )
    {
        for( my $i = 0; $i < scalar( @_ ); $i += 2 )
        {
            $out->set( $_[ $i ] => $_[ $i + 1 ] );
        }
    }
    else
    {
        return( $out );
    }
}

sub err_headers_out { return( shift->_request->err_headers_out( @_ ) ); }

sub escape { return( URI::Escape::uri_escape( @_ ) ); }

sub etag { return( shift->headers( 'ETag', @_ ) ); }
## https://perl.apache.org/docs/2.0/api/Apache2/Response.html#toc_C_set_etag_
## sub etag { return( shift->_try( '_request', 'set_etag', @_ ) ); }

sub expires { return( shift->headers( 'Expires', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers>
# e.g.: Access-Control-Expose-Headers: Content-Encoding, X-Kuma-Revision
sub expose_headers { return( shift->_set_get_multi( 'Access-Control-Expose-Headers', @_ ) ); }

sub flush { return( shift->_try( '_request', 'rflush' ) ); }

# sub get_http_message
# {
#   my $self = shift( @_ );
#   my $code = shift( @_ ) || return;
#   my $formal_msg = $self->get_status_line( $code );
#   $formal_msg =~ s/^(\d{3})[[:blank:]]+//;
#   return( $formal_msg );
# }
sub get_http_message { return( Net::API::REST::Status->status_message( $_[1], $_[2] ) ); }

sub get_status_line { return( shift->_try( '_request', 'status_line', @_ ) ); }

# sub headers { return( shift->_request->headers_out ); }
sub headers
{
    my $self = shift( @_ );
    # my $out = $self->_request->headers_out;
    my $out = $self->_request->err_headers_out;
    if( scalar( @_ ) && !( @_ % 2 ) )
    {
        for( my $i = 0; $i < scalar( @_ ); $i += 2 )
        {
            if( !defined( $_[ $i + 1 ] ) )
            {
                $out->unset( $_[ $i ] );
            }
            else
            {
                $out->set( $_[ $i ] => $_[ $i + 1 ] );
            }
        }
    }
    elsif( scalar( @_ ) )
    {
        return( $out->get( shift( @_ ) ) );
    }
    else
    {
        return( $out );
    }
}

sub headers_out { return( shift->_request->headers_out( @_ ) ); }

## https://perl.apache.org/docs/2.0/api/Apache2/SubRequest.html#toc_C_internal_redirect_
sub internal_redirect
{
    my $self = shift( @_ );
    my $uri = shift( @_ );
    $uri = $uri->path if( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) );
    try
    {
        $self->_request->internal_redirect( $uri );
    }
    catch( $e )
    {
        $self->error( "An error occurred while trying to call Apache Request method \"internal_redirect\": $e" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    return( Apache2::Const::HTTP_OK );
}

## https://perl.apache.org/docs/2.0/api/Apache2/SubRequest.html#toc_C_internal_redirect_handler_
sub internal_redirect_handler
{
    my $self = shift( @_ );
    my $uri = shift( @_ );
    $uri = $uri->path if( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) );
    try
    {
        $self->_request->internal_redirect_handler( $uri );
    }
    catch( $e )
    {
        $self->error( "An error occurred while trying to call Apache Request method \"internal_redirect_handler\": $e" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    return( Apache2::Const::HTTP_OK );
}

sub is_info         { return( Net::API::REST::Status->is_info( $_[1] ) ); }

sub is_success      { return( Net::API::REST::Status->is_success( $_[1] ) ); }

sub is_redirect     { return( Net::API::REST::Status->is_redirect( $_[1] ) ); }

sub is_error        { return( Net::API::REST::Status->is_error( $_[1] ) ); }

sub is_client_error { return( Net::API::REST::Status->is_client_error( $_[1] ) ); }

sub is_server_error { return( Net::API::REST::Status->is_server_error( $_[1] ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>
sub keep_alive { return( shift->_set_get_one( 'Keep-Alive', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified>
sub last_modified { return( shift->_date_header( 'Last-Modified', @_ ) ); }

sub last_modified_date { return( shift->headers( 'Last-Modified-Date', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location>
sub location { return( shift->_set_get_one( 'Location', @_ ) ); }

## https://perl.apache.org/docs/2.0/api/Apache2/SubRequest.html#toc_C_run_
sub lookup_uri
{
    my $self = shift( @_ );
    my $uri = shift( @_ );
    $uri = $uri->path if( Scalar::Util::blessed( $uri ) && $uri->isa( 'URI' ) );
    try
    {
        my $subr = $self->_request->lookup_uri( $uri, @_ );
        ## Returns Apache2::Const::OK, Apache2::Const::DECLINED, etc.
        return( $subr->run );
    }
    catch( $e )
    {
        $self->error( "An error occurred while trying to call Apache Request method \"internal_redirect_handler\": $e" );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
}

## make_etag( $force_weak )
## https://perl.apache.org/docs/2.0/api/Apache2/Response.html#C_make_etag_
sub make_etag { return( shift->_try( '_request', 'make_etag', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age>
sub max_age { return( shift->_set_get_number( 'Access-Control-Max-Age', @_ ) ); }

sub meets_conditions { return( shift->_try( '_request', 'meets_conditions' ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/NEL>
sub nel { return( shift->_set_get_one( 'NEL', @_ ) ); }

## This adds the following to the outgoing headers:
## Pragma: no-cache
## Cache-control: no-cache
sub no_cache { return( shift->_try( '_request', 'no_cache', @_ ) ); }

sub print { return( shift->_try( '_request', 'print', @_ ) ); }

sub printf { return( shift->_try( '_request', 'printf', @_ ) ); }

sub redirect
{
    my $self = shift( @_ );
    ## I have to die if nothing was provided, because our return value is the http code. We can't just return undef()
    my $uri = shift( @_ ) || die( "No uri provided to redirect\n" );
    ## Stringify
    $self->headers->set( 'Location' => "$uri" );
    $self->code( Apache2::Const::HTTP_MOVED_TEMPORARILY );
    return( Apache2::Const::HTTP_MOVED_TEMPORARILY );
}

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy>
sub referrer_policy { return( shift->_set_get_one( 'Referrer-Policy', @_ ) ); }

sub request { return( shift->_set_get_object( 'request', 'Net::API::REST::Request', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>
sub retry_after { return( shift->_set_get_one( 'Retry-After', @_ ) ); }

sub rflush { return( shift->_try( '_request', 'rflush' ) ); }

## e.g. send_cgi_header( $buffer )
sub send_cgi_header { return( shift->_try( '_request', 'send_cgi_header', @_ ) ); }

## e.g. sendfile( $filename );
## sendfile( $filename, $offset );
## sendfile( $filename, $offset, $len );
sub sendfile { return( shift->_try( '_request', 'sendfile', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server>
sub server { return( shift->_set_get_one( 'Server', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>
sub server_timing { return( shift->_set_get_one( 'Server-Timing', @_ ) ); }

## e.g set_content_length( 1024 )
sub set_content_length { return( shift->_try( '_request', 'set_content_length', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>
sub set_cookie { return( shift->_set_get_one( 'Set-Cookie', @_ ) ); }

## https://perl.apache.org/docs/2.0/api/Apache2/Response.html#toc_C_set_last_modified_
sub set_last_modified { return( shift->_try( '_request', 'set_last_modified', @_ ) ); }

sub set_keepalive { return( shift->_try( '_request', 'set_keepalive', @_ ) ); }

## Returns a APR::Socket
## See Apache2::Connection manual page
sub socket { return( shift->_try( 'connection', 'client_socket', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/SourceMap>
sub sourcemap { return( shift->_set_get_one( 'SourceMap', @_ ) ); }

sub status { return( shift->_try( '_request', 'status', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>
sub strict_transport_security { return( shift->_set_get_one( 'Strict-Transport-Security', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin>
sub timing_allow_origin { return( shift->_set_get_multi( 'Timing-Allow-Origin', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Trailer>
sub trailer { return( shift->_set_get_one( 'Trailer', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding>
sub transfer_encoding { return( shift->_set_get_one( 'Transfer-Encoding', @_ ) ); }

sub unescape { return( URI::Escape::uri_unescape( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade>
sub upgrade { return( shift->_set_get_multi( 'Upgrade', @_ ) ); }

sub update_mtime { return( shift->_try( '_request', 'update_mtime', @_ ) ); }

sub uri_escape { return( shift->escape( @_ ) ); }

sub uri_unescape { return( shift->unescape( @_ ) ); }

sub url_decode { return( shift->decode( @_ ) ); }

sub url_encode { return( shift->encode( @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary>
sub vary { return( shift->_set_get_multi( 'Vary', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via>
sub via { return( shift->_set_get_multi( 'Via', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Want-Digest>
sub want_digest { return( shift->_set_get_multi( 'Want-Digest', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Warning>
sub warning { return( shift->_set_get_one( 'Warning', @_ ) ); }

## e.g. $cnt = $r->write($buffer);
## $cnt = $r->write( $buffer, $len );
## $cnt = $r->write( $buffer, $len, $offset );
sub write { return( shift->_try( '_request', 'write', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate>
sub www_authenticate { return( shift->_set_get_one( 'WWW-Authenticate', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options>
sub x_content_type_options { return( shift->_set_get_one( 'X-Content-Type-Options', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control>
sub x_dns_prefetch_control { return( shift->_set_get_one( 'X-DNS-Prefetch-Control', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>
sub x_frame_options { return( shift->_set_get_one( 'X-Frame-Options', @_ ) ); }

# <https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection>
sub x_xss_protection { return( shift->_set_get_one( 'X-XSS-Protection', @_ ) ); }

sub _request { return( shift->request->request ); }

sub _set_get_multi
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->SUPER::error( "No field was provided to set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    my $headers = $self->headers;
    if( @_ )
    {
        my $v = shift( @_ );
        return( $headers->unset( $f ) ) if( !defined( $v ) );
        if( $self->_is_array( $v ) )
        {
            # Take a copy to be safe since this is a reference
            $headers->set( $f => [@$v] );
        }
        else
        {
            $headers->set( $f => [split( /\,[[:blank:]\h]*/, $v)] );
        }
        return( $self );
    }
    else
    {
        my $v = $headers->get( $f );
        unless( $self->_is_array( $v ) )
        {
            $v = [split( /\,[[:blank:]\h]*/, $v )];
        }
        return( $self->new_array( $v ) );
    }
}

sub _set_get_one
{
    my $self = shift( @_ );
    my $f    = shift( @_ );
    return( $self->SUPER::error( "No field was provided to set its value." ) ) if( !defined( $f ) || !length( "$f" ) );
    my $headers = $self->headers;
    if( @_ )
    {
        my $v = shift( @_ );
        return( $headers->unset( $f ) ) if( !defined( $v ) );
        $headers->set( $f => $v );
        return( $self );
    }
    else
    {
        my $v = $headers->get( $f );
        return( $self->new_scalar( $v ) ) if( !ref( $v ) );
        return( $self->new_array( $v ) ) if( $self->_is_array( $v ) );
        # By default
        return( $v );
    }
}

sub _try
{
    my $self = shift( @_ );
    my $pack = shift( @_ ) || return( $self->error( "No Apache package name was provided to call method" ) );
    my $meth = shift( @_ ) || return( $self->error( "No method name was provided to try!" ) );
    my $r = Apache2::RequestUtil->request;
    # $r->log_error( "Net::API::REST::Response::_try to call method \"$meth\" in package \"$pack\"." );
    try
    {
        return( $self->$pack->$meth ) if( !scalar( @_ ) );
        return( $self->$pack->$meth( @_ ) );
    }
    catch( $e )
    {
        return( $self->error( "An error occurred while trying to call Apache ", ucfirst( $pack ), " method \"$meth\": $e" ) );
    }
}

1;

# XXX POD
__END__

=encoding utf8

=head1 NAME

Net::API::REST::Response - Apache2 Outgoing Response Access and Manipulation

=head1 SYNOPSIS

    use Net::API::REST::Response;
    ## $r is the Apache2::RequestRec object
    my $req = Net::API::REST::Request->new( request => $r, debug => 1 );
    ## or, to test it outside of a modperl environment:
    my $req = Net::API::REST::Request->new( request => $r, debug => 1, checkonly => 1 );

=head1 VERSION

    v0.4.13

=head1 DESCRIPTION

The purpose of this module is to provide an easy access to various method to process and manipulate incoming request.

This is designed to work under modperl.

Normally, one would need to know which method to access across various Apache2 mod perl modules, which makes development more time consuming and even difficult, because of the scattered documentation and even sometime outdated.

This module alleviate this problem by providing all the necessary methods in one place. Also, at the contrary of C<Apache2> modules suit, all the methods here are die safe. When an error occurs, it will always return undef() and the error will be able to be accessed using B<error> object, which is a L<Module::Generic::Exception> object.

Fo its alter ego to manipulate outgoing http response, use the L<Net::API::REST::Response> module.

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<request>

This is a required parameter to be sent with a value set to a L<Apache2::RequestRec> object

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 allow_credentials

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Credentials>

=head2 allow_headers

Sets the C<Access-Control-Allow-Headers> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers>

=head2 allow_methods

Sets the C<Access-Control-Allow-Methods> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods>

=head2 allow_origin

Sets the C<Access-Control-Allow-Origin>

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin>

=head2 alt_svc

Sets the C<Alt-Svc> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>

=head2 bytes_sent()

The number of bytes sent to the client, handy for logging, etc.

=head2 cache_control

Sets the C<Cache-Control> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>

=head2 clear_site_data

Sets the C<Clear-Site-Data> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>

=head2 code( integer )

Get/set the reply status for the client request.

Normally you would use some L<Apache2::Const> constant, e.g. L<Apache2::Const::REDIRECT>.

=head2 connection()

Returns a L<Apache2::Connection> object.

=head2 content_disposition

Sets the C<Content-Disposition> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>

=head2 content_encoding( string )

Get/set content encoding (the C<Content-Encoding> HTTP header).  Content encodings are string like C<gzip> or C<compress>.

For example, here is how to send a gzip'ed response:

     require Compress::Zlib;
     $res->content_type( "text/plain" );
     $res->content_encoding( "gzip" );
     $res->print( Compress::Zlib::memGzip( "some text to be gzipped" ) );

=head2 content_language()

Returns the http header value for C<Content-Language>

=head2 content_languages( string )

Get/set content languages (the C<Content-Language> HTTP header).  Content languages are string like C<en> or C<fr>.

It returns the current list of content languages, as an array reference.

=head2 content_length( integer )

Set the content length for this request.

See L<Apache2::Response> for more information.

=head2 content_location

Sets the C<Content-Location> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Location>

=head2 content_range

Sets the C<Content-Range> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>

=head2 content_security_policy

Sets the C<Content-Security-Policy> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy>

=head2 content_security_policy_report_only

Sets the C<Content-Security-Policy-Report-Only> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only>

=head2 content_type( mime_type )

Get/set the HTTP response Content-type header value.

For example, set the "Content-type" header to text/plain.

     $res->content_type('text/plain');

If you set this header via the C<headers_out> table directly, it will be ignored by Apache. So do not do that.

=head2 cookie_new( hash reference )

Given a hash reference with the following properties, this will create a L<Net::API::REST::Cookie> object that can be stringified and aded into a C<Set-Cookie> http header.

=over 4

=item I<name>

=item I<value>

=item I<domain>

=item I<expires>

=item I<http_only>

=item I<max_age>

=item I<path>

=item I<secure>

=item I<same_site>

=back

=head2 cookie_replace( cookie object )

Given a cookie object, this either sets the given cookie in a C<Set-Cookie> header or replace the existing one with the same cookie name, if any.

It returns the cookie object provided.

=head2 cookie_set( cookie object )

Given a cookie object, this set the C<Set-Cookie> http header for this cookie.

However, it does not check if another C<Set-Cookie> header exists for this cookie.

=head2 cross_origin_embedder_policy

Sets the C<Cross-Origin-Embedder-Policy> header

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Embedder-Policy>

=head2 cross_origin_opener_policy

Sets the C<Cross-Origin-Opener-Policy> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy>

=head2 cross_origin_resource_policy

Sets the C<Cross-Origin-Resource-Policy> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Resource-Policy>

=head2 cspro

Alias for L</content_security_policy_report_only>

=head2 custom_response()

Install a custom response handler for a given status.

    $res->custom_response( $status, $string );

The first argument is the status for which the custom response should be used (e.g. C<Apache2::Const::AUTH_REQUIRED>)

The second argument is the custom response to use. This can be a static string, or a URL, full or just the uri path (/foo/bar.txt).

B<custom_response>() does not alter the response code, but is used to replace the standard response body. For example, here is how to change the response body for the access handler failure:

     package MyApache2::MyShop;
     use Apache2::Response ();
     use Apache2::Const -compile => qw(FORBIDDEN OK);
     sub access {
         my $r = shift;

         if (MyApache2::MyShop::tired_squirrels()) {
             $r->custom_response(Apache2::Const::FORBIDDEN,
                 "It's siesta time, please try later");
             return Apache2::Const::FORBIDDEN;
         }

         return Apache2::Const::OK;
     }
     ...

     # httpd.conf
     PerlModule MyApache2::MyShop
     <Location /TestAPI__custom_response>
         AuthName dummy
         AuthType none
         PerlAccessHandler   MyApache2::MyShop::access
         PerlResponseHandler MyApache2::MyShop::response
     </Location>

When squirrels can't run any more, the handler will return 403, with the custom message:

     It's siesta time, please try later

=head2 decode( $string )

Given a url-encoded string, this returns the decoded string

This uses L<APR::Request> XS method.

=head2 digest

Sets the C<Digest> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Digest>

=head2 encode( $string )

Given a string, this returns its url-encoded version

This uses L<APR::Request> XS method.

=head2 env( name, [ name => value ] )

Get or set an environment variable.

=head2 err_headers( name => value, [ name2 => value2, etc ] )

Given one or more name => value pair, this will set them in the http header using the B<err_headers_out> method.

=head2 err_headers_out()

Get/set MIME response headers, printed even on errors and persist across internal redirects.

The difference between "headers_out" and "err_headers_out", is that the latter are printed even on error, and persist across internal redirects (so the headers printed for "ErrorDocument" handlers will have them).

For example, if a handler wants to return a 404 response, but nevertheless to set a cookie, it has to be:

     $res->err_headers_out->add('Set-Cookie' => $cookie);
     return( Apache2::Const::NOT_FOUND );

If the handler does:

     $res->headers_out->add('Set-Cookie' => $cookie);
     return( Apache2::Const::NOT_FOUND );

the "Set-Cookie" header won't be sent.

See L<Apache2::RequestRec> for more information.

=head2 escape

Provided with a value and this will return it uri escaped by calling L<URI::Escape/uri_escape>.

=head2 etag( string )

Sets the C<Etag> http header.

=head2 expires

Sets the C<expires> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expires>

=head2 expose_headers

Sets the C<Access-Control-Expose-Headers> header.

e.g.: Access-Control-Expose-Headers: Content-Encoding, X-Kuma-Revision

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers>

=head2 flush()

Flush any buffered data to the client.

    $res->flush();

Unless STDOUT stream's $| is false, data sent via C<$req->print()> is buffered. This method flushes that data to the client.

=head2 get_http_message( integer, [ language ] )

Given an http code integer, and optionally a language code, this returns the http status message in the language given.

If no language is provided, this returns the message in C<en_GB>, i.e. British English.

=head2 get_status_line( integer )

Return the C<Status-Line> for a given status code (excluding the HTTP-Version field).

If an invalid or unknown status code is passed, C<500 Internal Server Error> will be returned.

For example:

    print( $res->get_status_line( 400 ) );

will print: C<400 Bad Request>

=head2 headers( [ name, [ name => value ] )

If a name => value pair is provided, this will set the corresponding http header.

If only a name is provided, this will retrieve the corresponding http header value and return it.

If nothing is provided, it will return the http headers as a hash reference.

It uses the Apache2 B<err_headers_out> method in the background.

=head2 headers_out( name, [ value ] )

Returns or sets the key => value pairs of outgoing http headers, only on 2xx responses.

See also "err_headers_out", which allows to set headers for non-2xx responses and persist across internal redirects.

More information at L<Apache2::RequestRec>

=head2 internal_redirect( URI object | uri path )

Given a C<URI> object or a uri path string, this redirect the current request to some other uri internally.

If a C<URI> object is given, its B<path> method will be used to get the path string.

    $res->internal_redirect( $new_uri );

In case that you want some other request to be served as the top-level request instead of what the client requested directly, call this method from a handler, and then immediately return L<Apache2::Const::OK>. The client will be unaware the a different request was served to her behind the scenes.

See L<Apache2::SubRequest> for more information.

=head2 internal_redirect_handler( URI object | uri path string )

Identical to B<internal_redirect>, plus automatically sets C<$res->content_type> is of the sub-request to be the same as of the main request, if C<$res->handler> is true.

=head2 is_info( integer )

Given a http code integer, this will return true if the code is comprised between 100 and less than 200, false otherwise.

=head2 is_success( integer )

Given a http code integer, this will return true if the code is comprised between 200 and less than 300, false otherwise.

=head2 is_redirect( integer )

Given a http code integer, this will return true if the code is comprised between 300 and less than 400, false otherwise.

=head2 is_error( integer )

Given a http code integer, this will return true if the code is comprised between 400 and less than 600, false otherwise.

=head2 is_client_error( integer )

Given a http code integer, this will return true if the code is comprised between 400 and less than 500, false otherwise.

=head2 is_server_error( integer )

Given a http code integer, this will return true if the code is comprised between 500 and less than 600, false otherwise.

=head2 keep_alive

Sets the C<Keep-Alive> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>

=head2 last_modified

Sets the C<Last-Modified> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified>

=head2 last_modified_date( http datetime )

Get or set the http datetime for the http header C<Last-Modified-Date>

=head2 location

Sets the C<Location> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Location>

=head2 lookup_uri( URI object | uri path string, [ handler ] )

Create a sub request from the given URI. This sub request can be inspected to find information about the requested URI.

     $ret = $res->lookup_uri( $new_uri );
     $ret = $res->lookup_uri( $new_uri, $next_filter );

See L<Apache2::SubRequest> for more information.

=head2 make_etag( boolean )

Construct an entity tag from the resource information. If it's a real file, build in some of the file characteristics.

    $etag = $res->make_etag( $force_weak );

=head2 max_age

Sets the C<Access-Control-Max-Age> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age>

=head2 meets_conditions()

Implements condition C<GET> rules for HTTP/1.1 specification. This function inspects the client headers and determines if the response fulfills the specified requirements.

    $status = $res->meets_conditions();

It returns L<Apache2::Const::OK> if the response fulfils the condition GET rules. Otherwise some other status code (which should be returned to Apache).

=head2 nel

Sets the C<NEL> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/NEL>

=head2 no_cache( boolean )

Add/remove cache control headers:

     $prev_no_cache = $res->no_cache( $boolean );

A true value sets the "no_cache" request record member to a true value and inserts:

     Pragma: no-cache
     Cache-control: no-cache

into the response headers, indicating that the data being returned is volatile and the client should not cache it.

A false value unsets the C<no_cache> request record member and the mentioned headers if they were previously set.

This method should be invoked before any response data has been sent out.

=head2 print( list of data )

Send data to the client.

    $cnt = $res->print( @msg );

It returns how many bytes were sent (or buffered). If zero bytes were sent, B<print> will return 0E0, or C<zero but true>, which will still evaluate to 0 in a numerical context.

The data is flushed only if STDOUT stream's $| is true. Otherwise it's buffered up to the size of the buffer, flushing only excessive data.

=head2 printf( format, list )

Format and send data to the client (same as "printf").

    $cnt = $res->printf( $format, @args );

It returns how many bytes were sent (or buffered).

The data is flushed only if STDOUT stream's $| is true. Otherwise it's buffered up to the size of the buffer, flushing only excessive data.

=head2 redirect( URI object | full uri string )

Given an URI, this will prepare the http headers and return the proper code for a 301 temporary http redirect.

It should be used like this in your code:

    return( $res->redirect( "https://example.com/somewhere/" ) );

=head2 referrer_policy

Sets the C<Referrer-Policy> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy>

=head2 request()

Returns the L<Net::API::REST::Request> object.

=head2 retry_after

Sets the C<Retry-After> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>

=head2 rflush()

Flush any buffered data to the client.

Unless STDOUT stream's $| is false, data sent via C<$res->print()> is buffered. This method flushes that data to the client.

It does not return any value.

=head2 send_cgi_header()

Parse the header.

    $res->send_cgi_header( $buffer );

This method is really for back-compatibility with mod_perl 1.0. It's very inefficient to send headers this way, because of the parsing overhead.

If there is a response body following the headers it'll be handled too (as if it was sent via B<print>()).

Notice that if only HTTP headers are included they won't be sent until some body is sent (again the C<send> part is retained from the mod_perl 1.0 method).

See L<Apache2::Response> for more information.

=head2 sendfile( filepath, [ offset, length ] )

Send a file or a part of it

     $rc = $req->sendfile( $filename );
     $rc = $req->sendfile( $filename, $offset );
     $rc = $req->sendfile( $filename, $offset, $len );

It returns a L<APR::Const> constant.

On success, L<APR::Const::SUCCESS> is returned.

In case of a failure -- a failure code is returned, in which case normally it should be returned to the caller

=head2 server

Sets the C<Server> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server>

=head2 server_timing

Sets the C<Server-Timing> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>

=head2 set_content_length( integer )

Set the content length for this request.

$res->set_content_length( $length );

It does not return any value.

=head2 set_cookie

Sets the C<Set-Cookie> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>

=head2 set_last_modified( timestamp in seconds )

Sets the C<Last-Modified> response header field to the value of the mtime field in the request structure -- rationalized to keep it from being in the future.

    $res->set_last_modified( $mtime );

If the $mtime argument is passed, $r->update_mtime will be first run with that argument.

=head2 set_keepalive()

Set the keepalive status for this request.

    $ret = $res->set_keepalive();

It returns true if keepalive can be set, false otherwise.

=head2 socket()

Get/set the client socket and returns a L<APR::Socket> object.

This calls the B<client_socket> method of the L<Apache2::Connection> package.

=head2 sourcemap

Sets the C<SourceMap> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/SourceMap>

=head2 status( [ integer ] )

Get/set the reply status for the client request.

Normally you would use some L<Apache2::Const> constant, e.g. L<Apache2::Const::REDIRECT>.

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result. However, there are rare instances when you want to trick Apache into thinking that the module returned an C<Apache2::Const:OK> status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler. The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning L<Apache2::Const::OK> to Apache. e.g.:

         $r->status( $some_code );
         return( Apache2::Const::OK );

See also C<$r->status_line>, which. if set, overrides C<$r->status>.

=head2 strict_transport_security

Sets the C<Strict-Transport-Security> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>

=head2 timing_allow_origin

Sets the C<Timing-Allow-Origin> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Timing-Allow-Origin>

=head2 trailer

Sets the C<Trailer> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Trailer>

=head2 transfer_encoding

Sets the C<Transfer-Encoding> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Transfer-Encoding>

=head2 unescape

Unescape the given data chunk by calling L<URI::Escape/uri_unescape>

=head2 update_mtime( timestamp in seconds )

Set the C<$res->mtime> field to the specified value if it's later than what's already there.

    $res->update_mtime( $mtime );

=head2 upgrade

Sets the C<Upgrade> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade>

=head2 uri_escape

Provided with a string and this uses L<URI::Escape> to return an uri-escaped string.

=head2 uri_unescape

Provided with an uri-escaped string and this will decode it and return its original string.

=head2 url_decode

Provided with an url-encoded string and this will return its decoded version.

=head2 url_encode

Provided with a string and this will return an url-encoded version.

=head2 vary

Sets the C<Vary> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary>

=head2 via

Sets the C<Via> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Via>

=head2 want_digest

Sets the C<Want-Digest> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Want-Digest>

=head2 warning

Sets the C<Warning> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Warning>

=head2 write()

Send partial string to the client

     $cnt = $req->write( $buffer );
     $cnt = $req->write( $buffer, $len );
     $cnt = $req->write( $buffer, $len, $offset );

See L<Apache2::RequestIO> for more information.

=head2 www_authenticate

Sets the C<WWW-Authenticate> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate>

=head2 x_content_type_options

Sets the C<X-Content-Type-Options> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options>

=head2 x_dns_prefetch_control

Sets the C<X-DNS-Prefetch-Control> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-DNS-Prefetch-Control>

=head2 x_frame_options

Sets the C<X-Frame-Options> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options>

=head2 x_xss_protection

Sets the C<X-XSS-Protection> header.

See L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection>

=head2 _request()

Returns the embedded L<Apache2::RequestRec>

=head2 _set_get_multi

    $self->_set_get_multi( 'SomeHeader' => $some_value );

Sets or gets a header with multiple values. The value provided for the header can be either an array reference and it will be used as is (after being copied), or a regular string, which will be converted into an array reference by splitting it by comma.

If the value is undefined, it will remove the corresponding header.

    $self->_set_get_multi( 'SomeHeader' => undef() );

If no value is provided, it returns the current value for this header as a L<Module::Generic::Array> object.

=head2 _set_get_one

Sets or gets a header with the provided value. If the value is undefined, the header will be removed.

If no value is provided, it returns the current value as an array object (L<Module::Generic::Array>) or as a scalar object (L<Module::Generic::Scalar>) if it is not a reference.

=head2 _try( object accessor, method, [ arguments ] )

Given an object type, a method name and optional parameters, this attempts to call it.

Apache2 methods are designed to die upon error, whereas our model is based on returning C<undef> and setting an exception with L<Module::Generic::Exception>, because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

https://gitlab.com/jackdeguest/Net-API-REST

=head1 SEE ALSO

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
