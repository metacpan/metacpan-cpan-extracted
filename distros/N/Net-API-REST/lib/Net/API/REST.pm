# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST.pm
## Version v1.2.4
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/09/01
## Modified 2025/11/06
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use Apache2::API qw( :common );
    use parent qw( Apache2::API );
    use vars qw( $VERSION $DEBUG $API_VERSION );
    use curry;
    use version;
    use Apache2::Reload;
    use JSON::PP ();
    use Regexp::Common;
    use Scalar::Util ();
    # use Crypt::JWT;
    # 2019-09-26
    # We use our own drop-in replacement because of a bug in ModPerl and JSON::XS not recognising hash reference passed
    use Net::API::REST::JWT;
    # use DateTime::Format::Strptime;
    use Net::API::REST::DateTime;
    use MIME::Base64 ();
#   use IO::Compress::Gzip;
#   use IO::Compress::Bzip2;
#   use IO::Compress::Deflate;
    use Net::API::REST::Request;
    use Net::API::REST::Response;
    use Apache2::API::Status;
    $VERSION = 'v1.2.4';
};

use strict;
use warnings;

$DEBUG = 0;
$API_VERSION = 1;
our @AVAILABLE_API_VERSIONS = qw( 1 );

sub init
{
    my $self = shift( @_ );
    $self->{request}                = '' unless( $self->{request} );
    $self->{response}               = '' unless( $self->{response} );
    $self->{apache_request}         = '' unless( $self->{apache_request} );
    # Routes to endpoint to which are attached resources
    $self->{routes}                 = {} unless( scalar( keys( %{$self->{routes}} ) ) );
    $self->{api_version}            = 1 if( !length( $self->{api_version} ) );
    $self->{default_methods}        = [qw( GET POST )] unless( $self->{default_methods} );
    $self->{is_allowed}             = {} unless( $self->{is_allowed} && scalar( keys( %{$self->{is_allowed}} ) ) );
    $self->{supported_content_types} = [] unless( $self->{supported_methods} );
    $self->{supported_methods}      = [qw( DELETE GET HEAD OPTIONS POST PUT )] unless( $self->{supported_methods} );
    $self->{supported_api_versions} = [qw( 1 )] unless( $self->{supported_api_versions} );
    $self->{key}                    = '' unless( length( $self->{key} ) );
    $self->{jwt_accepted_algo}      = [] unless( length( $self->{jwt_accepted_algo} ) );
    $self->{jwt_accepted_encoding}  = [] unless( length( $self->{jwt_accepted_encoding} ) );
    $self->{jwt_encrypt}            = 1 unless( length( $self->{jwt_encrypt} ) );
    $self->{jwt_algo}               = 'HS256' unless( length( $self->{jwt_algo} ) );
    $self->{jwt_encoding}           = 'A128GCM' unless( length( $self->{jwt_encoding} ) );
    # 200Kb
    $self->{compression_threshold}  = 204800 unless( length( $self->{compression_threshold} ) );
    $self->{lang}                   = '' unless( length( $self->{lang} ) );
    $self->{api_uri}                = '' unless( length( $self->{api_uri} ) );
    $self->{is_allowed}             = {} unless( $self->{is_allowed} && ref( $self->{is_allowed} ) eq 'HASH' );
    # Default handlers
    $self->{is_allowed}->{access}   = sub{ return( Apache2::Const::HTTP_OK ); } unless( exists( $self->{is_allowed}->{access} ) && ref( $self->{is_allowed}->{access} ) eq 'CODE' );
    $self->{is_allowed}->{network}  = sub{ return( Apache2::Const::HTTP_OK ); } unless( exists( $self->{is_allowed}->{network} ) && ref( $self->{is_allowed}->{network} ) eq 'CODE' );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( length( $self->{api_version} ) )
    {
        $self->api_version( $self->{api_version} );
    }
    if( $self->{routes} )
    {
        $self->routes( $self->{routes} ) || return( $self->pass_error );
    }
    $self->supported_api_versions( $self->{supported_api_versions} ) if( $self->{supported_api_versions} );
    foreach my $k ( qw( jwt_encrypt jwt_algo jwt_encoding jwt_accepted_algo jwt_accepted_encoding ) )
    {
        $self->$k( $self->{ $k } );
    }
    return( $self );
}

sub api_uri { return( shift->_set_get_object( 'api_uri', 'URI', @_ ) ); }

sub api_version
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        unless( ref( $v ) eq 'version' )
        {
            $v = version->parse( $v );
        }
        $self->{api_version} = $v;
    }
    return( $self->{api_version} );
}

sub base_path { return( shift->_set_get_scalar( 'base_path', @_ ) ); }

sub checkonly { return( shift->_set_get_boolean( 'checkonly', @_ ) ); }

sub default_methods { return( shift->_set_get_array( 'default_methods', @_ ) ); }

sub endpoint { return( shift->_set_get_object( 'endpoint', 'Net::API::REST::Endpoint', @_ ) ); }

# In Apache2 conf:
# PerlResponseHandler MyPackage::REST which would inherit from Net::API::REST
sub handler : method
{
    # https://perl.apache.org/docs/2.0/user/handlers/http.html#HTTP_Request_Handler_Skeleton
    my( $class, $r ) = @_;
    # my $handlerClass = $r->dir_config( 'Net_API_REST_Handler' ) || 'Net::API::REST' ;
    my $debug = $r->dir_config( 'DEBUG' ) || $DEBUG;
    my $req = Net::API::REST::Request->new( $r, debug => $debug );
    # An error has occurred
    if( !defined( $req ) )
    {
        $r->log_error( "${class}::handler: Error instantiating an Net::API::REST::Request object: " . Net::API::REST::Request->error );
        return( Net::API::REST::Request->error->code || Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    my $resp = Net::API::REST::Response->new( request => $req, debug => $debug ) || do
    {
        $r->log_error( "${class}::handler: Error instantiating an Net::API::REST::Response object: " . Net::API::REST::Response->error );
        return( Net::API::REST::Response->error->code || Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    };
    my $self = $class->new(
        apache_request => $r,
        debug       => $debug,
        request     => $req,
        response    => $resp,
    );
    if( !defined( $self ) )
    {
        $r->log_error( "Error instantiating a new $class object: ", $class->error );
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    
    if( my $code = $self->log_handler )
    {
        $r->set_handlers( 'PerlPrivateLogHandler' => $code );
    }
    
    # $self->apache_request( $r );
    # $r->log_error( "Received Apache request $r, object debug value is: ", $self->debug );
    # Full uri. $r->uri only returns the path
    my $uri = $req->uri;
    $self->api_uri( URI->new( $uri->scheme . '://' . $uri->host ) );
    # Response content type
    $r->content_type( 'application/json' );
    my $json = JSON->new->relaxed->utf8;
    $self->{json} = $json;
    
    # No need to go further if the ip address is not allowed to access the REST api.
    # Here you could check for IP ban, or whether there is enough authorisation to access the endpoint
    my $ok_net = $self->is_allowed( 'network' );
    if( $ok_net && ref( $ok_net ) )
    {
        # Get a return code, and possibly a hash containing the message property
        my( $rc, $rdef ) = $ok_net->( $req->remote_ip );
        if( $resp->is_error( "$rc" ) )
        {
            if( $self->_is_a( $rc, 'Net::API::REST::RC' ) )
            {
                return( $self->reply({ code => $rc->code, message => $rc->message }) );
            }
            elsif( $rdef && $self->_is_hash( $rdef ) && CORE::exists( $rdef->{message} ) )
            {
                return( $self->reply({ code => $rc, message => $rdef->{message} }) );
            }
            # Net::API::REST::reply will automatically set a json with an error message based on the user language
            else
            {
                return( $self->reply({ code => $rc }) );
            }
        }
    }
    
    # No need to go further if the requested method is not supported
    my $ok_methods = $self->supported_methods;
    my $http_meth = $req->method;
    if( scalar( @$ok_methods ) && !scalar( grep( /^$http_meth$/i, @$ok_methods ) ) )
    {
        # Net::API::REST::reply will automatically set a json with an error message based on the user language
        return( $self->reply({ code => Apache2::Const::HTTP_METHOD_NOT_ALLOWED }) );
    }
    
    # Check supported content-type
    # Ref: <https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html>
    my $ok_ct = $self->supported_content_types;
    # Only the content type, ie without the charset. Example: application/json; charset=utf-8
    my $ct = lc( $req->type );
    # We check if content type is provided at all since it could be missing, such as in 
    # a OPTIONS, POST or GET request with no content or query
    if( length( $ct ) && scalar( @$ok_ct ) && !scalar( grep( $ct eq $_, @$ok_ct ) ) )
    {
        # Net::API::REST::reply will automatically set a json with an error message based on the user language
        return( $self->reply({ code => Apache2::Const::HTTP_NOT_ACCEPTABLE }) );
    }
    
    # Check if there is a required api version and if we support it
    if( $req->client_api_version )
    {
        my $ok_versions = $self->supported_api_versions;
        my $client_version = $req->client_api_version;
        my $client_api_version_is_ok = 0;
        foreach my $v ( @$ok_versions )
        {
            if( $v == $client_version )
            {
                $client_api_version_is_ok++;
            }
        }
        return( $self->reply( Apache2::Const::HTTP_NOT_ACCEPTABLE, { error => "API version requested ($client_version) is not supported." } ) ) unless( $client_api_version_is_ok );
    }
    
    # Protection against DNS rebinding attacks
    # https://www.w3.org/TR/cors/#list-of-headers
    if( my $req_host = $req->headers( 'Host' ) )
    {
        my $req_host_uri = URI->new( $self->api_uri->scheme . '://' . $req_host );
        if( lc( $req_host_uri->host ) ne $self->api_uri->host )
        {
            # Net::API::REST::reply will automatically set a json with an error message based on the user language
            return( $self->reply({ code => Apache2::Const::HTTP_UNAUTHORIZED }) );
        }
    }
    
    $self->request( $req );
    $self->response( $resp );
    
    # If there is a init_headers handler, call it to initiate the headers
    my $init_headers = $self->init_headers;
    if( $init_headers && ref( $init_headers ) eq 'CODE' )
    {
        $init_headers->({ request => $req, response => $resp });
    }
    
    if( $http_meth eq 'OPTIONS' )
    {
        return( $self->http_options );
    }
    elsif( $http_meth eq 'HEAD' )
    {
        # $r->send_http_header;
        return( Apache2::Const::HTTP_NO_CONTENT );
    }
    
    my $origin = $req->headers( 'Origin' );
    if( $origin )
    {
        $self->http_cors;
    }
    
    my $path = $uri->path;
    if( my $base = $r->dir_config( 'Net_API_REST_Base' ) ) 
    {
        $self->base_path( $base );
    }
    my $ep = $self->route( $uri );
    if( !defined( $ep ) )
    {
        my $json = {};
        my $code = $self->error->code;
        if( $code )
        {
            $json->{code} = $code;
            $json->{message} = $self->error->message;
        }
        else
        {
            $json->{code} = Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
        }
        # Net::API::REST::reply will automatically set a json with an error message based on the user language
        return( $self->reply( $json ) );
    }
    # No resource found matching the user request, returning a 400
    elsif( !length( $ep ) )
    {
        # Net::API::REST::reply will automatically set a json with an error message based on the user language
        return( $self->reply({ code => Apache2::Const::HTTP_BAD_REQUEST }) );
    }
    elsif( !$ep->is_method_allowed( $http_meth ) )
    {
        return( $self->reply({ code => Apache2::Const::HTTP_METHOD_NOT_ALLOWED }) );
    }
    else
    {
        $self->endpoint( $ep );
        my $handler = $ep->handler;
        my $vars = $ep->variables;
        $req->variables( $vars );
#       require B::Deparse;
#       my $deparse = B::Deparse->new( '-p', '-sC' );
#       my $meth_body = $deparse->coderef2text( $ep->handler );
        my $tmpl = <<EOT;
Endpoint information:
Handler .......: %s
Access type ...: %s
Ok methods ....: %s
Path ..........: %s
Path info .....: %s
Variables .....: %s
Params ........: %s
EOT
        $self->noexec->messagef( 3, $tmpl, $handler, $ep->access, join( ', ', @{$ep->methods} ), $ep->path, join( ', ', @{$ep->path_info} ), $self->dumper( $ep->variables->as_hash( strict => 1 ) ), $self->dumper( $ep->params->as_hash( strict => 1 ) ) );
        # Check access with handler
        my $ok_access = $self->is_allowed( 'access' );
        if( $ok_access && ref( $ok_access ) eq 'CODE' )
        {
            my( $rc, $rdef ) = $ok_access->( $ep );
            if( $resp->is_error( "$rc" ) )
            {
                # Net::API::REST::reply will automatically set a json with an error message based on the user language
                # return( $self->reply({ code => $rc }) );
                if( $self->_is_a( $rc, 'Net::API::REST::RC' ) )
                {
                    return( $self->reply({ code => $rc->code, message => $rc->message }) );
                }
                elsif( $rdef && $self->_is_hash( $rdef ) && CORE::exists( $rdef->{message} ) )
                {
                    return( $self->reply({ code => $rc, message => $rdef->{message} }) );
                }
                # Net::API::REST::reply will automatically set a json with an error message based on the user language
                else
                {
                    return( $self->reply({ code => $rc }) );
                }
            }
        }
        
#         use B::Deparse;
#         my $deparse = B::Deparse->new("-p", "-sC");
#         my $code_body = $deparse->coderef2text( $handler );
        
        # try-catch
        local $@;
        my $rc = eval
        {
            # my $rc = $ep->handler->();
            $handler->();
        };
        if( $@ )
        {
            $self->error({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => $@ });
            # return( $self->reply( 500, { message => 'An internal server error occured' } ) );
            return( $self->bailout( "An error occurred while executing code for api resource: $@" ) );
        }
        # Server error
        if( !defined( $rc ) )
        {
            # Net::API::REST::reply will automatically set a json with an error message based on the user language
            # It is ok to set a reply ourself here, because if it were a normal response, we would not be getting an undef value
            return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR }) );
            # return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
        }
        elsif( $rc == Apache2::Const::HTTP_OK )
        {
            return( Apache2::Const::OK );
        }
        else
        {
            return( $rc );
        }
        # Stop sending data !!
        $self->request->socket->close;
        exit(0);
    }
}

# Mut be overriden by sub package
sub http_cors { return; }

# https://www.w3.org/TR/cors/#http-access-control-allow-origin
sub http_options
{
    my $self = shift( @_ );
    my $req = $self->request;
    my $res = $self->response;
    my $uri = $req->uri;
    my $ep = $self->route( $uri );
    my $http_meth = $req->method;
    if( !defined( $ep ) )
    {
        return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
    elsif( !CORE::length( $ep ) )
    {
        return( Apache2::Const::HTTP_NOT_FOUND );
    }
    my $tmpl = <<EOT;
Endpoint information:
Handler .......: %s
Access type ...: %s
Ok methods ....: %s
Path info .....: %s
Variables .....: %s
EOT
    $self->noexec->messagef( 3, $tmpl, $ep->handler, $ep->access, join( ', ', @{$ep->methods} ), join( ', ', @{$ep->path_info} ), $self->dumper( $ep->variables->as_hash ) );

    my $req_methods = [CORE::split( /\,[[:blank:]]*/, ( $req->headers( 'Access-Control-Request-Method' ) || '' ) )];
    if( scalar( @$req_methods ) )
    {
        foreach my $m ( @$req_methods )
        {
            if( !$ep->is_method_allowed( $m ) )
            {
                return( Apache2::Const::HTTP_METHOD_NOT_ALLOWED );
            }
        }
        if( !$ep->methods->is_empty )
        {
            $res->headers( 'Access-Control-Allow-Methods' => $ep->methods->join( ', ' )->scalar );
        }
        else
        {
            $res->headers( 'Access-Control-Allow-Methods' => '*' );
        }
    }
    
    my $origin = $req->headers( 'Origin' ) || $req->headers( 'Access-Control-Request-Origin' );
    if( !$origin )
    {
        return( Apache2::Const::HTTP_NO_CONTENT );
    }
    my $allow_origin = $req->headers( 'Access-Control-Allow-Origin' );
    # "The string "*" cannot be used for a resource that supports credentials"
    # https://www.w3.org/TR/cors/#http-access-control-allow-origin
    if( $allow_origin )
    {
        if( $ep->access eq 'restricted' )
        {
            if( $allow_origin eq '*' )
            {
                $res->headers( 'Access-Control-Allow-Origin' => $origin );
                $res->headers( 'Access-Control-Max-Age' => 5 );
            }
        }
        $res->headers( 'Access-Control-Allow-Credentials' => 'true' );
    }
    else
    {
        if( $ep->access eq 'restricted' )
        {
            if( $origin )
            {
                $res->headers( 'Access-Control-Allow-Origin' => $origin );
            }
            else
            {
                # Stringify
                $res->headers( 'Access-Control-Allow-Origin' => $self->api_uri . '' );
            }
            $res->headers(
                'Access-Control-Allow-Credentials' => 'true',
                'Access-Control-Max-Age' => 5
            );
        }
        elsif( $origin )
        {
            $res->headers(
                'Access-Control-Allow-Origin' => $origin,
                'Access-Control-Allow-Credentials' => 'true',
                'Access-Control-Max-Age' => 5
            );
        }
        else
        {
            $res->headers( 'Access-Control-Allow-Origin' => '*' );
        }
    }
    my $req_headers = $req->headers( 'Access-Control-Request-Headers' );
    if( $req_headers )
    {
        $res->headers( 'Access-Control-Allow-Headers' => $req_headers );
    }
    my $cred_required = $req->headers( 'Credentials' );
    if( lc( $cred_required ) eq 'include' )
    {
        $res->headers( 'Access-Control-Allow-Credentials' => 'true' );
    }
    # Check from the most restrictive allowed methods in the context of the endpoint to the broader one for generally all supported methods
    my $ok_methods = scalar( @{$ep->methods} ) ? $ep->methods : $self->supported_methods;
    $res->headers( 'Access-Control-Allow-Methods' => join( ', ', @$ok_methods ) );
    
    # $r->headers_out->add( 'Allow' => join( ',', @$ok_methods ) );
    # $r->rflush;
    return( Apache2::Const::HTTP_NO_CONTENT );
}

# To be overriden by module inheriting our package
sub init_headers { return(1); }

# Set or get handlers for various phases to check if the user is allowed access
# Currently available handlers: network and access
sub is_allowed
{
    my $self = shift( @_ );
    my $all  = $self->{is_allowed};
    if( @_ )
    {
        return( $self->error( "Wrong number of parameters provided: '", join( "', '", @_ ), "'." ) ) if( scalar( @_ ) > 1 && !( scalar( @_ ) % 2 ) );
        if( !( scalar( @_ ) % 2 ) )
        {
            while( my( $key, $code ) = splice( @_, 0, 2 ) )
            {
                if( $code )
                {
                    return( $self->error( "I was expecting a code reference for the handler '$key', but instead I got '$code'." ) ) if( ref( $code ) ne 'CODE' );
                    $all->{ $key } = $code;
                }
            }
            return( $self );
        }
        else
        {
            my $key = shift( @_ );
            return( '' ) if( !exists( $all->{ $key } ) );
            return( $all->{ $key } );
        }
    }
}

sub jwt_accepted_algo { return( shift->_set_get_array( 'jwt_accepted_algo', @_ ) ); }

sub jwt_accepted_encoding { return( shift->_set_get_array( 'jwt_accepted_encoding', @_ ) ); }

sub jwt_algo { return( shift->_set_get_scalar( 'jwt_algo', @_ ) ); }

sub jwt_decode
{
    my $self = shift( @_ );
    my $opts = {};
    if( ref( $_[0] ) eq 'HASH' )
    {
        $opts = shift( @_ );
    }
    # A simple decode, most likely for public jwt like google, linkedin, etc.
    elsif( scalar( @_ ) == 1 )
    {
        my $token = shift( @_ );
        my $data;
        # try-catch
        local $@;
        eval
        {
            # $data = Crypt::JWT::decode_jwt( token => $token );
            $data = Net::API::REST::JWT::decode_jwt( token => $token );
        };
        if( $@ )
        {
            return( $self->error( "There was an error decoding Json Web Token payload: $@" ) );
        }
        return( $data );
    }
    return( $self->error( "No encryption key was set up in our object or provided." ) ) if( !$self->key && !$opts->{key} );
    return( $self->error( "No token was provided to decode." ) ) if( !$opts->{token} );
    $opts->{algo} ||= $self->jwt_algo;
    $opts->{accepted_algo} ||= $self->jwt_accepted_algo;
    $opts->{accepted_encoding} ||= $self->jwt_accepted_encoding;
    $opts->{verify_audience} ||= $self->jwt_verify_audience;
    my $param =
    {
    token => $opts->{token},
    key => $opts->{key},
    decode_payload => 1,
    decode_header => 1,
    # verify_iss => sub{ 1; }
    verify_aud => qr{^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$},
    };
    # PBES2-HS256+A128KW
    # accepted_alg => qr{^(?:PBES2\-HS256\+A128KW|HS256)$},
    if( $opts->{accepted_algo} )
    {
        return( $self->error( "Accepted alorithm option must be an array reference." ) ) if( !$self->_is_array( $opts->{accepted_algo} ) );
        if( scalar( @{$opts->{accepted_algo}} ) )
        {
            my $re = join( '|', @{$opts->{accepted_algo}} );
            $param->{accepted_alg} = qr{^(?:\Q$re\E)$};
        }
    }
    
    # accepted_enc => qr{^(?:A128GCM)$},
    if( $opts->{accepted_enc} )
    {
        return( $self->error( "Accepted encoding option must be an array reference." ) ) if( !$self->_is_array( $opts->{accepted_enc} ) );
        if( scalar( @{$opts->{accepted_enc}} ) )
        {
            my $re = join( '|', @{$opts->{accepted_enc}} );
            $param->{accepted_enc} = qr{^(?:\Q$re\E)$};
        }
    }
    
    if( ref( $opts->{verify_audience} ) eq 'Regexp' )
    {
        $param->{verify_aud} = $opts->{verify_audience};
    }
    
    my $data;
    # try-catch
    local $@;
    eval
    {
        ## $data = Crypt::JWT::decode_jwt( %$param );
        $data = Net::API::REST::JWT::decode_jwt( %$param );
    };
    if( $@ )
    {
        return( $self->error( "There was an error decoding Json Web Token payload: $@" ) );
    }
    return( $data );
}

sub jwt_encode
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No encryption key was set up in our object or provided." ) ) if( !$self->key && !$opts->{key} );
    $opts->{encrypt} ||= $self->jwt_encrypt if( !length( $opts->{encrypt} ) );
    $opts->{algo} ||= $self->jwt_algo;
    if( $opts->{encrypt} )
    {
        $opts->{algo} ||= 'PBES2-HS256+A128KW';
    }
    else
    {
        $opts->{algo} ||= 'HS256';
    }
    $opts->{encoding} ||= $self->jwt_encoding || 'A128GCM';
    return( $self->error( "No payload was provided." ) ) if( !$opts->{payload} );
    return( $self->error( "Payload submitted is not an hash reference." ) ) if( ref( $opts->{payload} ) ne 'HASH' );
    my $payload = $opts->{payload};
    $payload->{iss} = $opts->{issuer} if( length( $opts->{issuer} ) );
    $payload->{aud} = $opts->{audience} if( length( $opts->{audience} ) );
    $payload->{azd} = $opts->{audience} if( length( $opts->{audience} ) );
    $payload->{iat} = $opts->{issued_at} if( length( $opts->{issued_at} ) );
    $payload->{sub} = $opts->{subject} if( length( $opts->{subject} ) );
    if( length( $opts->{expires} ) )
    {
        $payload->{exp} = $opts->{expires};
    }
    elsif( length( $opts->{ttl} ) )
    {
        return( $self->error( "Property \"ttl\" provided is not an integer." ) ) if( $opts->{ttl} !~ /^\d+$/ );
        $payload->{exp} = $opts->{iat} + $opts->{ttl};
    }
    my $token;
    my %params =
    (
    payload => $payload,
    ## do NOT allow the "none" algorithm, as this is massively insecure
    allow_none => 0,
    alg  => $opts->{algo},
    key  => ( $opts->{key} || $self->key ),
    enc  => $opts->{encoding},
    );
    my @possible_additional_parameters = qw(
        allow_none
        auto_iat
        extra_headers
        keypass
        relative_exp
        relative_nbf
        serialization
        shared_unprotected_headers
        unprotected_headers
        zip
    );
    for( @possible_additional_parameters )
    {
        $params{ $_ } = $opts->{ $_ } if( CORE::exists( $opts->{ $_ } ) && CORE::length( $opts->{ $_ } ) );
    }
    
    # try-catch
    local $@;
    eval
    {
        ## $token = Crypt::JWT::encode_jwt(
        $token = Net::API::REST::JWT::encode_jwt( %params );
    };
    if( $@ )
    {
        return( $self->error( "Error in the arguments or payload when creating a Jason Web Token: $@" ) );
    }
    return( $token );
}

sub jwt_encoding { return( shift->_set_get_scalar( 'jwt_encoding', @_ ) ); }

sub jwt_encrypt { return( shift->_set_get_scalar( 'jwt_encrypt', @_ ) ); }

# We extract the jwt data, and do not verify it, which is very unsecure of course
# Best to use jwt_verify()
sub jwt_extract
{
    my $self = shift( @_ );
    my $token = shift( @_ ) || return( $self->error( "No json web token was provided to extract its data." ) );
    return( $self->error( "Token provided ($token) seems malformed. I was expecting 3 chunks of base64 data separated by dots" ) ) if( $token !~ /^([^\.]+)\.([^\.]+)\.([^\.]+)$/ );
    my( $header, $claim, $crypto )  = split( /\./, $token, 3 );
    my $hash = {};
    # try-catch
    local $@;
    eval
    {
        $hash->{raw_header} = MIME::Base64::decode_base64( $header );
        $hash->{raw_claim} = MIME::Base64::decode_base64( $claim );
        my $j = JSON->new->allow_nonref;
        $hash->{header} = $j->utf8->decode( $hash->{raw_header} );
        $hash->{claim} = $j->utf8->decode( $hash->{raw_claim} );
    };
    if( $@ )
    {
        return( $self->error( "An error occured while attempting to extract token data: $@" ) );
    }
    return( $hash );
}

sub jwt_verify
{
    my $self  = shift( @_ );
    my $token;
    my $opts  = {};
    if( @_ )
    {
        if( ref( $_[0] ) eq 'HASH' )
        {
            $opts = shift( @_ );
        }
        elsif( scalar( @_ ) >= 2 && !( @_ % 2 ) )
        {
            $opts = { @_ };
        }
        else
        {
            $token = shift( @_ );
        }
    }
    $token ||= $opts->{token} || return( $self->error( "No json web token was provided to extract its data." ) );
    my $hash = $self->jwt_extract( $token ) || return( undef() );
    # Something like this:
    # Downloaded from https://accounts.google.com/.well-known/openid-configuration
    # and then from https://www.googleapis.com/oauth2/v3/certs
    # {
    #   "keys": [
    #     {
    #       "kid": "2bf8418b2963f366f5fefdd127b2cee07c887e65",
    #       "e": "AQAB",
    #       "kty": "RSA",
    #       "alg": "RS256",
    #       "n": "uA8MNzSvgJTB_eHWj_HnpGzgtfBzsO4PjdNkEvdETRHEvyqIyqQnACRUNQ9KACnPV3R1M_1VlkJGRJ-xI3By3uylEOh4VagVRlCjLbsmuXburlOLn3TZSkwR7XE3pvVqcypq4nLPdu6foV__wcrLkZPMJzq654vepbOIegx5iVIvV2ilfdqs7VTwHRAUQU6nYfa8jaUwj1H_-zlaaHK-vxm-lWdGjAyiv-xBj5UmY24WtkTuX-MWLvOgbrqcYzMpzEm-LCdBbZR4qjQbWEatRISp4QW31xBZxF2FwMK2YWXDUW_GhXy0hgbsSyX-6jziTDSsulk9SNstSXmYCTZtvw",
    #       "use": "sig"
    #     },
    #     {
    #       "use": "sig",
    #       "kid": "0b0bf186743471a1edcac3060d1256f9e4050ba8",
    #       "e": "AQAB",
    #       "kty": "RSA",
    #       "alg": "RS256",
    #       "n": "0s9r8J5G5I77VpYWS-ttQ8GBDZBlxN_TZHl4DJHAi1WzvxQcP0hBPdASNqAnAuXA-ZxMpMtW_ovjhwo1Ncqpofd3c0H5mSzA9nsmmiex3AO7ZbkaGIdOcMYr4ttOFKZJn2giZWsfQuTlMEvcGyghViyy6l7t1-dMyxjbNOAVLVn25PHfWLbtffv-5EXFXt0Bp0wf0JjPghy4xXf3GjqqqaG_pOnmY_g2c6s8NwZG8dLymiqq0sta3URCUzDYnEHfx7Ol-grOYBOg6YjQP-gl0r5_uvB9Vl9jXKz-WcUUqVTuLp6S-CBstsOheUpSjX3vVP48KJIS4DX6NFHgjn8ooQ"
    #     }
    #   ]
    # }
    if( $opts->{rsa_keys} )
    {
        return( $self->error( "RSA keys provided with parameter \"rsa_keys\" is not an hash reference." ) ) if( ref( $opts->{rsa_keys} ) ne 'HASH' );
        my $keys = $opts->{rsa_keys};
        return( $self->error( "No \"keys\" property found in the rsa keys provided." ) ) if( !$keys->{keys} );
        return( $self->error( "Property \"keys\" in rsa eys provided is not an array reference (of rsa keys)." ) ) if( !$self->_is_array( $keys->{keys} ) );
        # Check all is in order before going further
        my( $e, $n );
        $n = 0;
        foreach my $ref ( @{$keys->{keys}} )
        {
            $n++;
            foreach my $p ( qw( kid e kty alg n ) )
            {
                return( $self->error( "No property \"$p\" could be found in this rsa key No $n. Hash is: ", sub{ $self->dump( $ref ) } ) ) if( !$ref->{ $p } );
            }
        }
        # Make sure our header has alg set to rsa and there is a kid property, or else Crypt::JWT will die
        # So at least, we can catch this issue and return an error gracefully...
        # {"alg":"RS256","kid":"0b0bf186743471a1edcac3060d1256f9e4050ba8","typ":"JWT"}
        my $header = $hash->{header} || return( $self->error( "Unable to get the header from the jwt token '$token'." ) );
        return( $self->error( "JWT token header returned by jwt_extract is empty! Original token is: '$token'" ) ) if( !scalar( keys( %$header ) ) );
        return( $self->error( "JWT token header found has no \"alg\" property set. Original token is: '$token'" ) ) if( !$header->{alg} );
        return( $self->error( "JWT token header found has no \"kid\" property set. Original token is: '$token'" ) ) if( !$header->{kid} );
        # https://metacpan.org/pod/Crypt::JWT#key
        return( $self->error( "JWT validation was requested using rsa keys, but could not find the property \"alg\" set to \"RS256\"." ) ) if( $header->{alg} !~ /^(RS|PS|ES)\d{3}$/i );
        my $kid = $header->{kid};
        # Check if kid value is in the rsa keys provided.
        foreach my $ref ( @{$keys->{keys}} )
        {
            if( $ref->{kid} eq $kid )
            {
                $e = $ref->{e};
                $n = $ref->{n};
                last;
            }
        }
        return( $self->error( "Unable to find a matching key for the one found in the token header ($kid) against the rsa keys provided." ) ) if( !CORE::length( $e ) || !CORE::length( $n ) );
        # Ok, we are very reasonably safe to call Crypt::JWT now
        my $data;
        # try-catch
        local $@;
        eval
        {
            # $data = Crypt::JWT::decode_jwt( token => $token );
            # $data = Crypt::JWT::decode_jwt(
            $data = Net::API::REST::JWT::decode_jwt(
                token           => $token,
                kid_keys        => $keys,
                decode_payload  => 1,
                verify_exp      => 0,
                debug           => 3,
            );
        };
        if( $@ )
        {
            return( $self->error( "Faile validating jwt token '$token'. Reason is: $@" ) );
        }
        # Ok, we're good
    }
    return( $hash );
}

sub jwt_verify_audience { return( shift->_set_get_object( 'jwt_verify_audience', 'Regexp', @_ ) ); }

sub key { return( shift->_set_get_scalar( 'key', @_ ) ); }

sub request { return( shift->_set_get_object( 'request', 'Net::API::REST::Request', @_ ) ); }

sub response { return( shift->_set_get_object( 'response', 'Net::API::REST::Response', @_ ) ); }

sub route
{
    my $self = shift( @_ );
    # my $parts = shift( @_ ) || return( $self->error( "No path parts as array reference was provided." ) );
    #return( $self->error( "Path parts provided ($parts) is not an array reference." ) ) if( ref( $parts ) ne 'ARRAY' );
    my $uri = shift( @_ ) || return( $self->error({
        code => 400,
        message => "No uri was provided to find the appropriate route."
    }) );
    return( $self->error({ code => 500, message => "URI provided \"$uri\" is not an object." }) ) if( !Scalar::Util::blessed( $uri ) );
    return( $self->error({ code => 500, message => "URI object provided \"$uri\" is not an URI object." }) ) if( !$uri->isa( 'URI' ) );
    my $path = $uri->path;
    if( my $base = $self->base_path )
    {
        $path =~ s/^\Q$base\E//;
    }
    my @points = split( /\/+/ , $path );
    # Clean up empty path
    my $parts = [ grep{ length( $_ ) > 0 } @points ];
    my $client_api_version = '';
    if( $parts->[0] =~ /^v?(\d+(?:\.\d+)*)$/ )
    {
        $client_api_version = $1;
        shift( @$parts );
    }
    $client_api_version ||= $self->request->client_api_version || $self->api_version;
    my $routes = $self->routes;
    if( !scalar( keys( %$routes ) ) )
    {
        return( $self->error({ code => 500, message => "No routes set up to find the appropriate resource." }) );
    }
    elsif( !CORE::exists( $routes->{ $client_api_version } ) )
    {
        return( $self->error({ code => Apache2::Const::HTTP_NOT_ACCEPTABLE, message => "API version requested ($client_api_version) is not supported." }) );
    }
    my $req = $self->request;
    my $resp = $self->response;
    # Path variables like "/some/path/1234/more/thing/jack" where 1234 and jack are variables
    # 2019-11-13: This is set by the caller of route()
    # my $vars = $req->variables;
    my $vars = {};
    my $def_methods = $self->default_methods;
    my $http_meth = lc( $req->method // '' );
    # Until proven otherwise; If it is set at a certain point of the path, and nowhere after, then the path below inherit its value set before like a toll gate
    my $access = 'public';
    my $params;
    my $check;
    $check = sub
    {
        my( $pos, $subroutes ) = @_;
        my $part = $parts->[ $pos ];
        # reserved words cannot be used in path
        return( '' ) if( $part =~ /^_(access_control|allowed_methods|handler|name|var|delete|get|head|post|put)$/i );
        if( exists( $subroutes->{ lc( $part ) } ) )
        {
            $part = lc( $part );
            # Code reference
            if( ref( $subroutes->{ $part } ) eq 'CODE' )
            {
                # Do we have still more path?
                # If we do, we store it as variable _path_info and let the handler deal with it
                # $vars->{_path_info} = [ splice( @$parts, $pos + 1 ) ] if( $#$parts > $pos );
                # return( $subroutes->{ $part } );
                my $ep = Net::API::REST::Endpoint->new(
                    handler => $subroutes->{ $part },
                    methods => $def_methods,
                    variables => $vars,
                    access => $access,
                    path => $uri,
                    ( defined( $params ) ? ( params => $params ) : () ),
                    debug => $self->debug,
                );
                $ep->path_info( [ splice( @$parts, $pos + 1 ) ] ) if( $#$parts > $pos );
                return( $ep );
            }
            # path part has sub component, so we look for a key _handler in the sub hash
            elsif( ref( $subroutes->{ $part } ) eq 'HASH' )
            {
                my $ref = $subroutes->{ $part };
                if( !exists( $ref->{_handler} ) &&
                    !exists( $ref->{_delete} ) &&
                    !exists( $ref->{_get} ) && 
                    !exists( $ref->{_head} ) &&
                    !exists( $ref->{_post} ) &&
                    !exists( $ref->{_put} ) )
                {
                    return( $self->error({ code => 500, message => "Found an entry for path part \"$part\", which is a hash reference, but could not find a key \"_handler\", \"_delete\", \"_get\", \"_head\", \"_post\", or \"_put\" inside it." }) );
                }
                my $methods = {};
                foreach my $h ( qw( _delete _get _head _post _put ) )
                {
                    if( exists( $ref->{ $h } ) )
                    {
                        $methods->{ uc( substr( $h, 1 ) ) } = $ref->{ $h };
                    }
                }

                my $supported_methods = [sort( keys( %$methods ) )];
                # If this is just a pre-flight check, at this stage the handler does not matter
                my $handler = $http_meth eq 'options'
                    ? sub{}
                    : exists( $methods->{ uc( $http_meth ) } ) ? $methods->{ uc( $http_meth ) } : $ref->{_handler};
                
                # We reached the end, return the handler
                # return( $ref->{_handler} ) if( $pos == $#$parts );
                # return( $check->( $pos + 1, $ref ) );
                $access = $ref->{_access_control} if( $ref->{_access_control} );
                $params = $ref->{_params} if( CORE::exists( $ref->{_params} ) && ref( $ref->{_params} ) eq 'HASH' );
                
                if( $pos == $#$parts )
                {
                    if( ref( $handler ) eq 'CODE' )
                    {
                        my $ep = Net::API::REST::Endpoint->new(
                            handler => $handler,
                            methods => exists( $methods->{ uc( $http_meth ) } )
                                ? [uc( $http_meth )]
                                : ( scalar( @$supported_methods ) 
                                    ? $supported_methods 
                                    : $ref->{_allowed_methods} 
                                        ? $ref->{_allowed_methods} 
                                        : $def_methods ),
                            variables => $vars,
                            access => $access,
                            path => $uri,
                            ( defined( $params ) ? ( params => $params ) : () ),
                            debug => $self->debug,
                        );
                        return( $ep );
                    }
                    elsif( $handler =~ /^([^\-]+)\-\>(\S+)$/ )
                    {
                        my( $cl, $meth ) = ( $1, $2 );
                        # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
                        # require $cl unless( defined( *{"${cl}::"} ) );
                        $self->_load_class( $cl ) || return( $self->pass_error({ code => 500 }) );
                        # NOTE: 2021-09-05 (Jacques): See above same comment for the same issue, i.e. we only need to use the class name to check if the method exists, otherwise creating an instance of the object would have undesirable consequences under OPTIONS
                        my $code = $cl->can( $meth );
                        return( $self->error({ code => 500, message => "Class \"$cl\" does not have a method \"$meth\"." }) ) if( !$code );
                        # return( sub{ $code->( $o, api => $self, @_ ) } );
                        # try-catch
                        local $@;
                        my $ep = eval
                        {
                            Net::API::REST::Endpoint->new(
                                handler => sub
                                {
                                    my $o = $cl->new(
                                        apache_request => $self->apache_request,
                                        debug => $self->debug,
                                        request => $req,
                                        response => $resp,
                                        # Pass the api object here as well
                                        api => $self,
                                    );
                                    return( $self->pass_error( $cl->error ) ) if( !defined( $o ) );
                                    $code->( $o, api => $self, @_ );
                                },
                                methods => exists( $methods->{ uc( $http_meth ) } )
                                    ? [uc( $http_meth )]
                                    :  ( scalar( @$supported_methods )
                                        ? $supported_methods 
                                        : $ref->{_allowed_methods} 
                                            ? $ref->{_allowed_methods} 
                                            : $def_methods ),
                                variables => $vars,
                                access => $access,
                                path => $uri,
                                ( defined( $params ) ? ( params => $params ) : () ),
                                debug => $self->debug,
                            );
                        };
                        if( $@ )
                        {
                            return( $self->error({ code => 500, message => $@ }) );
                        }
                        return( $ep );
                    }
                    else
                    {
                        return( $self->error({ code => 500, message => "Found a route for the path part \"${part}\" and HTTP method ${http_meth}, but the handler found is not a code reference." }) );
                    }
                }
                return( $check->( $pos + 1, $ref ) );
            }
            # Not a code or a hash reference, so it has got to be a package name
            elsif( $subroutes->{ $part } =~ /^([^\-]+)\-\>(\S+)$/ )
            {
                my( $cl, $meth ) = ( $1, $2 );
                # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
                # require $cl unless( defined( *{"${cl}::"} ) );
                # my $rc = eval{ $self->_load_class( $cl ); };
                $self->_load_class( $cl ) || return( $self->pass_error({ code => 500 }) );
                # NOTE: 2021-09-05 (Jacques): This turned out to be a bad idea to check if a method exists in class, because by merely instantiating an object, it would trigger execution of code that is undesirable when running under OPTIONS, which only aims to check sanity and not actually run the query.
                # As it turns out $cl->can( $meth ) works just as well.
                # my $o = $cl->new(
                #    apache_request => $self->apache_request,
                #    debug => $self->debug,
                #    request => $req,
                #    response => $resp,
                #    # Pass the api object here as well
                #    api => $self,
                # ) || return( $self->pass_error( $cl->error ) );
                # my $code = $o->can( $meth );
                my $code = $cl->can( $meth );
                return( $self->error({ code => 500, message => "Class \"$cl\" does not have a method \"$meth\"." }) ) if( !$code );
                # return( sub{ $code->( $o, api => $self, @_ ) } );
                # try-catch
                local $@;
                my $ep = eval
                {
                    Net::API::REST::Endpoint->new(
                        handler => sub
                        {
                            my $o = $cl->new(
                               apache_request => $self->apache_request,
                               debug => $self->debug,
                               request => $req,
                               response => $resp,
                               # Pass the api object here as well
                               api => $self,
                            );
                            return( $self->pass_error( $cl->error ) ) if( !defined( $o ) );
                            $code->( $o, api => $self, @_ );
                        },
                        methods => $def_methods,
                        variables => $vars,
                        access => $access,
                        path => $uri,
                        ( defined( $params ) ? ( params => $params ) : () ),
                        debug => $self->debug,
                    );
                };
                if( $@ )
                {
                    return( $self->error({ code => 500, message => $@ }) );
                }
                return( $ep );
            }
            else
            {
                return( $self->error({ code => 500, message => "Found an entry for path part \"$part\" ($subroutes->{ $part }), but I do not know what to do with it. If this was supposed to be a package, the syntax needs to be My::Package->my_sub" }) );
            }
        }
        elsif( exists( $subroutes->{_var} ) )
        {
            my $ref = $subroutes->{_var};
            return( $self->error({ code => 500, message => "Found a variable, and I was expecting a hash reference, but intsead got '$ref'." }) ) if( ref( $ref ) ne 'HASH' );
            return( $self->error({ code => 500, message => "Found a variable, and I was expecting a key _name to be present in the definition hash reference, but could not find one." }) ) if( !exists( $ref->{_name} ) );
            if( !exists( $ref->{_handler} ) &&
                !exists( $ref->{_delete} ) &&
                !exists( $ref->{_get} ) && 
                !exists( $ref->{_head} ) &&
                !exists( $ref->{_post} ) &&
                !exists( $ref->{_put} ) )
            {
                return( $self->error({ code => 500, message => "Found a variable with name \"$ref->{_name}\" and was expecting a key _handler to be present in the definition hash reference, but could not find one." }) );
            }
            
            my $methods = {};
            foreach my $h ( qw( _delete _get _head _post _put ) )
            {
                if( exists( $ref->{ $h } ) )
                {
                    $methods->{ uc( substr( $h, 1 ) ) } = $ref->{ $h };
                }
            }

            my $supported_methods = [sort( keys( %$methods ) )];
            # If this is just a pre-flight check, at this stage the handler does not matter
            my $handler = $http_meth eq 'options'
                ? sub{}
                : exists( $methods->{ uc( $http_meth ) } ) ? $methods->{ uc( $http_meth ) } : $ref->{_handler};
            
            my $var_name = $ref->{_name};
            $params = $ref->{_params} if( CORE::exists( $ref->{_params} ) && ref( $ref->{_params} ) eq 'HASH' );
            # For variable type to be array
            if( exists( $ref->{_type} ) )
            {
                if( lc( $ref->{_type} ) eq 'array' || $ref->{_type} eq '[]' )
                {
                    if( exists( $vars->{ $var_name } ) )
                    {
                        my $prev = $vars->{ $var_name };
                        $vars->{ $var_name } = [ $prev ] if( ref( $prev ) ne 'ARRAY' );
                    }
                    else
                    {
                        $vars->{ $var_name } = [];
                    }
                }
            }
            # Store variable value
            if( exists( $vars->{ $var_name } ) )
            {
                my $prev = $vars->{ $var_name };
                $vars->{ $var_name } = [ $prev ] if( ref( $prev ) ne 'ARRAY' );
                push( @{$vars->{ $var_name }}, $part );
            }
            else
            {
                $vars->{ $var_name } = $part;
            }
            
            # We reached the end, return the handler
            if( $pos == $#$parts )
            {
                $access = $ref->{_access_control} if( $ref->{_access_control} );
                if( ref( $handler ) eq 'CODE' )
                {
                    # return( $ref->{_handler} );
                    my $ep = Net::API::REST::Endpoint->new(
                        handler => $handler,
                        methods => ( scalar( @$supported_methods ) ? $supported_methods : $ref->{_allowed_methods} ? $ref->{_allowed_methods} : $def_methods ),
                        variables => $vars,
                        access => $access,
                        path => $uri,
                        ( defined( $params ) ? ( params => $params ) : () ),
                        debug => $self->debug,
                    );
                    $ep->access( $ref->{_access_control} ) if( $ref->{_access_control} );
                    return( $ep );
                }
                elsif( $handler =~ /^([^\-]+)\-\>(\S+)$/ )
                {
                    my( $cl, $meth ) = ( $1, $2 );
                    # https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
                    # require $cl unless( defined( *{"${cl}::"} ) );
                    $self->_load_class( $cl ) || return( $self->pass_error({ code => 500 }) );
                    # NOTE: 2021-09-05 (Jacques): See above same comment for the same issue, i.e. we only need to use the class name to check if the method exists, otherwise creating an instance of the object would have undesirable consequences under OPTIONS
                    # my $o = $cl->new(
                    #     apache_request => $self->apache_request,
                    #     debug => $self->debug,
                    #     request => $req,
                    #     response => $resp,
                    #     # Pass the api object here as well
                    #     api => $self,
                    # ) || return( $self->pass_error( $cl->error ) );
                    # my $code = $o->can( $meth );
                    my $code = $cl->can( $meth );
                    return( $self->error({ code => 500, message => "Class \"$cl\" does not have a method \"$meth\"." }) ) if( !$code );
                    # return( sub{ $code->( $o, api => $self, @_ ) } );
                    # try-catch
                    local $@;
                    my $ep = eval
                    {
                        Net::API::REST::Endpoint->new(
                            handler => sub
                            {
                                my $o = $cl->new(
                                    apache_request => $self->apache_request,
                                    debug => $self->debug,
                                    request => $req,
                                    response => $resp,
                                    # Pass the api object here as well
                                    api => $self,
                                );
                                return( $self->pass_error( $cl->error ) ) if( !defined( $o ) );
                                $code->( $o, api => $self, @_ );
                            },
                            methods => ( scalar( @$supported_methods ) ? $supported_methods : $ref->{_allowed_methods} ? $ref->{_allowed_methods} : $def_methods ),
                            variables => $vars,
                            access => $access,
                            path => $uri,
                            ( defined( $params ) ? ( params => $params ) : () ),
                            debug => $self->debug,
                        );
                    };
                    if( $@ )
                    {
                        return( $self->error({ code => 500, message => $@ }) );
                    }
                    return( $ep );
                }
                else
                {
                    return( $self->error({ code => 500, message => "Found a scalar \"${handler}\" to handle variable \"$var_name\", but I do not know what to do with it. If this was supposed to be a package, the syntax needs to be My::Package->my_sub" }) );
                }
            }
            return( $check->( $pos + 1, $ref ) );
        }
        # Empty means not found
        else
        {
            return( '' );
        }
    };
    # We return empty, not undef if nothing was found
    my $ep = $check->( 0, $routes->{ $client_api_version } );
    # An error occurred
    if( !defined( $ep ) )
    {
        return;
    }
    # Nothing found
    elsif( !length( $ep ) )
    {
        return( '' );
    }
    else
    {
        return( $ep );
    }
}

sub routes
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $hash = shift( @_ ) || return( $self->error({ code => 500, message => "No route hash reference was provided." }) );
        return( $self->error({ code => 500, message => "Routes provided ($hash) is not a hash reference." }) ) if( ref( $hash ) ne 'HASH' );
        my $req = $self->request;
        my $resp = $self->response;
        # Walk through the hash to check everything is ok
        # Returns nothing if all is ok, or self returns an error description
        my $check;
        $check = sub
        {
            my $this = shift( @_ );
            foreach my $k ( sort( keys( %$this ) ) )
            {
                my $v = $this->{ $k };
                if( $k eq '_params' )
                {
                    return( "Value provided for _params is not an hash reference." ) if( ref( $v ) ne 'HASH' );
                }
                elsif( ref( $v ) eq 'HASH' )
                {
                    if( !CORE::exists( $v->{_handler} ) &&
                        !CORE::exists( $v->{_delete} ) && 
                        !CORE::exists( $v->{_get} ) && 
                        !CORE::exists( $v->{_head} ) && 
                        !CORE::exists( $v->{_post} ) && 
                        !CORE::exists( $v->{_put} ) )
                    {
                        return( "The keyword '_handlers' used is mispelled. It should be '_handler'" ) if( CORE::exists( $this->{_handlers} ) );
                        return( "No handler was specified for the end point \"$k\". I was expecting a key \"_handler\", \"_delete\", \"_get\", \"_head\", \"_post\", or \"_put\" to be present." );
                    }
                    if( my $err = $check->( $v ) )
                    {
                        return( $err );
                    }
                }
                elsif( $k eq '_name' )
                {
                    return( "Value provided for _name is empty." ) if( !length( $v ) );
                    return( "Value provided for _name is a reference, but I was expecting a scalar." ) if( ref( $v ) );
                }
                elsif( ref( $v ) eq 'CODE' )
                {
                    # We're ok
                }
                elsif( $v =~ /^([^\:]+)\:{2}[^\:]+/ )
                {
                    # my $cl = $subroutes->{ $part };
                    my $cl = $v;
                    my $meth;
                    if( $cl =~ /^([^\-]+)\-\>(\S+)$/ )
                    {
                        ( $cl, $meth ) = ( $1, $2 );
                    }
                    # require $cl unless( defined( *{"${cl}::"} ) );
                    $self->_load_class( $cl ) || return( $self->pass_error({ code => 500 }) );
                    # 2021-09-06: We do not need to instantiate an object to check if the module 'can' a method, and also this would trigger code which could lead to undesired results, because the instantiated object does not know if this is an actual query and at this stage could be missing authentication tokens to work properly. Yes, I am talking out of experience here :)
                    #my $o = $cl->new(
                    #    apache_request => $self->apache_request,
                    #    debug => $self->debug,
                    #    request => $req,
                    #    response => $resp,
                    #    # Pass the api object here as well
                    #    api => $self,
                    #    checkonly => 1
                    #) || return( $self->pass_error( $cl->error ) );
                    if( !defined( $meth ) )
                    {
                        return( "Class \"$cl\" does not have a method \"$meth\"." ) if( !$cl->can( $meth ) );
                    }
                }
                elsif( $k eq '_allowed_method' )
                {
                    return( "The keyword '_allowed_method' used is mispelled. It should be '_allowed_methods'" ) if( !CORE::exists( $this->{_allowed_methods} ) );
                }
                elsif( $k eq '_access_controls' )
                {
                    return( "The keyword '_access_controls' used is mispelled. It should be '_access_control'" ) if( !CORE::exists( $this->{_access_control} ) );
                }
                elsif( $k =~ /^_(allowed_methods|access_control)$/ )
                {
                    # Ok
                }
                # If it is neither a code reference nor a package name, we raise an error
                else
                {
                    return( "I was expecting a code reference or a package name, but instead got '$v' for key $k" );
                }
            }
        };
        # first level of keys are api version numbers, such as 1, 1.2, 2, etc...
        # and for each api version there is a set of route
        my @api_versions = keys( %$hash );
        foreach my $vers ( @api_versions )
        {
            if( $vers !~ /^\d+(?:\.\d+)*$/ )
            {
                return( $self->error( "API version number '$vers' is not a valid version number. Valid values are 1, 1.2, 1.5.3 for example." ) );
            }
            elsif( ref( $hash->{ $vers } ) ne 'HASH' )
            {
                return( $self->error( "API version number '$vers' value is not an hash reference. Its value must be a route to resources as hash reference." ) );
            }
        }
        
        foreach my $version ( sort( @api_versions ) )
        {
            if( my $err = $check->( $hash->{ $version } ) )
            {
                return( $self->error({ code => 500, message => $err }) );
            }
        }
        $self->{routes} = $hash;
    }
    return( $self->{routes} );
}

sub supported_api_versions
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = ref( $_[0] ) ? shift( @_ ) : \@_;
        my $vers = [];
        foreach my $this ( @$v )
        {
            push( @$vers, version->parse( $this ) );
        }
        $self->{supported_api_versions} = $vers;
    }
    return( $self->{supported_api_versions} );
}

sub supported_content_types { return( shift->_set_get_array( 'supported_content_types', @_ ) ); }

sub supported_languages { return( shift->_set_get_array( 'supported_languages', @_ ) ); }

sub supported_methods { return( shift->_set_get_array( 'supported_methods', @_ ) ); }

sub well_known
{
    my $self = shift( @_ );
    return( Apache2::Const::DECLINED );
}

sub _try
{
    my $self = shift( @_ );
    my $pack = shift( @_ ) || return( $self->error( "No Apache package name was provided to call method" ) );
    my $meth = shift( @_ ) || return( $self->error( "No method name was provided to try!" ) );
    my $r = Apache2::RequestUtil->request;
    # $r->log_error( "Net::API::REST::_try to call method \"$meth\" in package \"$pack\"." );
    # try-catch
    local $@;
    my $rv = eval
    {
        return( $self->$pack->$meth ) if( !scalar( @_ ) );
        return( $self->$pack->$meth( @_ ) );
    };
    if( $@ )
    {
        return( $self->error( "An error occurred while trying to call Apache ", ucfirst( $pack ), " method \"$meth\": $@" ) );
    }
    return( $rv );
}

# NOTE: Net::API::REST::Endpoint package
package Net::API::REST::Endpoint;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
};

sub init
{
    my $self = shift( @_ );
    # ACL
    $self->{access} = 'public';
    $self->{handler} = '';
    $self->{methods} = [];
    $self->{params} = {};
    $self->{path} = '';
    $self->{path_info} = [];
    $self->{variables} = {};
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub access { return( shift->_set_get_scalar( 'access', @_ ) ); }

sub handler { return( shift->_set_get_code( 'handler', @_ ) ); }

sub is_method_allowed
{
    my $self = shift( @_ );
    my $meth = shift( @_ );
    my $ok_methods = $self->methods;
    return( scalar( grep( /^$meth$/i, @$ok_methods ) ) );
}

sub methods { return( shift->_set_get_array_as_object( 'methods', @_ ) ); }

sub params { return( shift->_set_get_hash_as_mix_object( 'params', @_ ) ); }

sub path { return( shift->_set_get_uri( 'path', @_ ) ); }

sub path_info { return( shift->_set_get_array_as_object( 'path_info', @_ ) ); }

# sub variables { return( shift->_set_get_hash_as_object( 'variables', 'Net::API::REST::Endpoint::Variables', @_ ) ); }
sub variables { return( shift->_set_get_hash_as_mix_object( 'variables', @_ ) ); }

# NOTE: Net::API::REST::RC package
package Net::API::REST::RC;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use overload (
        '""' => 'as_string',
    );
};

sub init
{
    my $self = shift( @_ );
    $self->{code}    = undef();
    $self->{message} = undef();
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub as_string { return( shift->{code} ); }

sub code { return( shift->_set_get_number( 'code', @_ ) ); }

sub message { return( shift->_set_get_scalar_as_object( 'message', @_ ) ); }

sub TO_JSON { return( shift->{code} ); }

1;
# NOTE: pod
__END__

=encoding utf8

=head1 NAME

Net::API::REST - Framework for RESTful APIs

=head1 SYNOPSIS

    package MyPackage;
    BEGIN
    {
        use strict;
        use curry;
        use parent qw( Net::API::REST );
        use Net::API::Stripe;
    };
    
    sub init
    {
        my $self = shift( @_ );
        $self->{routes} =
        {
        # API version 1
        1 =>
            {
            'favicon.ico' => $self->curry::noop,
            auth =>
                {
                google =>
                    {
                    _handler => $self->curry::oauth_google,
                    callback => $self->curry::oauth_google(callback => 1),
                    },
                linkedin =>
                    {
                    _handler => $self->curry::oauth_linkedin,
                    callback => $self->curry::oauth_linkedin(callback => 1),
                    },
                },
            },
            stripe => $self->curry::stripe,
            # Whatever method is fine. Will call the method handle in package MyAPI::Users to handle the endpoint
            users => 'MyAPI::Users->handle',
            preferences =>
            {
                _access_control => 'restricted',
                _delete => $self->curry::remove_preferences,
                _get => $self->curry::get_preferences,
                _post => $self->curry::update_preferences,
            },
        };
        $self->{api_version} = 1;
        $self->{supported_api_versions} = [qw( 1 )];
        # By default, we support the GET and POST to access our endpoints
        # It may be adjusted endpoint by endpoint and if nothing is specified this default is used.
        $self->{default_methods} = [qw( GET POST )];
        # This is ALL possible supported methods
        $self->{supported_methods} = [qw( DELETE GET HEAD OPTIONS POST PUT )];
        $self->{supported_languages} = [qw( en-GB en fr-FR fr ja-JP )];
        $self->{key} = 'kAncmaDajnacSnbGmbXamn';
        # We want JWE (Json Web Token encrypted). This will affect jwt_encode's behaviour
        $self->{jwt_encrypt} = 1;
        # Because we are encrypting
        $self->{jwt_algo} = 'PBES2-HS256+A128KW';
        $self->{jwt_encoding} = 'A128GCM' unless( length( $self->{jwt_encoding} ) );
        $self->{jwt_accepted_algo} = [qw( PBES2-HS256+A128KW HS256 )];
        $self->{jwt_accepted_encoding} = [qw( A128GCM )];
        $self->SUPER::init( @_ );
        return( $self );
    }
    
    sub stripe
    {
        my $self = shift( @_ );
        my $ep = $self->endpoint;
        my $pinfo = $ep->path_info;
        my $remote_ip = $self->request->remote_ip;
        my $sig = $self->request->headers( 'Stripe-Signature' );
        return( $self->reply({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "No signature found" }) ) if( !CORE::length( $sig ) );
        my $payload = $self->request->data || return( $self->reply({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "No payload data received from the client." }) );
        ## Net::API::Stripe object
        my $stripe = Net::API::Stripe->new(
            # Enable debug to get debug data in http server log
            debug => 0,
            conf_file => "/home/john_doe/stripe-settings.json",
        ) || do
        {
            $self->message( 3, "Unable to initiate a Net::API::Stripe object using the configuration file /home/john_doe/stripe-settings.json" );
            return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => $self->oops }) );
        };
    
        # Do an IP source check to be sure this is Stripe talking to us
        if( !defined( my $ip_check = $stripe->webhook_validate_caller_ip({ ip => $remote_ip, ignore_ip => $ignore_ip }) ) )
        {
            return( $self->reply({ code => $stripe->error->code, message => $stripe->error->message }) );
        }
    
        # Now, we make sure this is Stripe sending this by checking the signature of the payload
        my $check = $stripe->webhook_validate_signature({
            secret => $signing_secret,
            signature => $sig,
            payload => $payload,
            time_tolerance => $max_time_spread,
        });
        if( !defined( $check ) )
        {
            return( $self->reply({code => $stripe->error->code, message => $stripe->error->message }) );
        }
    
        # Ok, if we are here, we passed all checks
        # Don't wait, reply ok back to Stripe so our request does not time out
        $self->response->code( Apache2::Const::HTTP_OK );
        my $json = $self->json->utf8->encode({ code => 200, success => $self->true });
        $self->response->print( $json );
        $self->response->rflush;
        # Do something with the payload received
        my $evt = $stripe->event( $payload ) || 
        return( $self->reply({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => $self->oops }) );
        printf( STDERR "Received an event from api version %s on %s for Stripe object type %s\n", $evt->api_version, $evt->created->iso8601, $evt->type );
        return( Apache2::Const::HTTP_OK );
    }

=head1 VERSION

    v1.2.4

=head1 DESCRIPTION

The purpose of this module is to provide a powerful, yet simple framework to implement a RESTful API under Apache2 mod_perl.

As of version C<1.0.0>, this module inherits from L<Apache2::API>. Please check its documentation. Other methods specific to this module are documented here.

=head1 METHODS

=head2 new

This initiates the package and take the following parameters:

=over 4

=item * C<request>

This is a required parameter to be sent with a value set to a L<Apache2::RequestRec> object

=item * C<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 api_uri()

Returns the api URI as a C<URI> object.

=head2 api_version( integer or decimal )

Get or sets the current api version on the server.

=head2 base_path( path )

If in the Directory directive of the Apache Virtual Host, a C<Net_API_REST_Base> was set, this method will be set with this value.

=head2 compression_threshold( integer )

The number of bytes threshold beyond which, the B<reply> method will gzip compress the data returned to the client.

=head2 default_methods( [ qw( GET POST ... ) ] )

This sets or gets the default methods supported by an endpoint.

=head2 endpoint( [ Net::API::REST::Endpoint object ] )

This gets or sets an L<Net::API::REST::Endpoint> object.

=head2 handler

This is the main method called by Apache to handle the response. To make this work, in the Apache configuration, you must set the handler to your package and have your package inherit from L<Net::API::REST>. For example:

    PerlResponseHandler MyPackage

When called by Apache, B<handler> will initiate a L<Net::API::REST::Request> object and a L<Net::API::REST::Response>

If the incoming request is an OPTIONS request such as a typical one issued during a javascript Ajax call, it will call the method B<http_options>() which will also set the cors policy by calling B<http_cors>()

Finally, it will try to find a route for the endpoint sought in the incoming query, and construct a L<Net::API::REST::Endpoint> object with the context information of the endpoint, including information such as variables that could exist in the path. For example:

    /org/jp/llc/123/directors/42/profile

Here the llc property has an id 123 and the directors property has an id 42. Those two variables are stored in the L<Net::API::REST::Endpoint> object. This object can then be accessed with the method B<endpoint>

Having found a route, B<handler> calls the anonymous subroutine in charge of handling the endpoint.

If no route was found, B<handler> returns a C<400 Bad Request>.

If the endpoint handler returns undef(), B<handler> will return a C<500 Server Error>, otherwise it will pass the return value back to Apache. The return value should be an L<Apache2::Const> return code.

=head2 http_cors()

Checks http request context and set the proper CORS http headers.

=head2 http_options()

If the request is an OPTIONS request, this method is called. It will do a C<pre-flight check> and look forward to see if the user has access to the resource sought and sets the response http headers accordingly.

=head2 init_headers( code reference )

If this is set, then L<Net::API::REST::handler> will call it.

=head2 is_allowed

Get or set handlers to check permission for various aspects of the api.

Each handler must return a valid HTTP Status code as an L<Apache2::Cons> value and if the returned code is an error, L<Net::API::REST> will stop right there and return it to Apache. See L<Net::API::REST::Status> for more information.

Currently supported handlers types are:

=over 4

=item I<access>

This is called in L</handler> and before it runs the code associated with the endpoint.

For example:

    $self->is_allowed( access => sub
    {
        my $req = $self->request;
        my $ep  = $self->endpoint;
        my $ref;
        # See: <https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html>
        if( $ep->access eq 'restricted' )
        {
            if( !$req->headers->get( 'Authorization' ) || !$req->headers->get( 'X-CSRF-Token' ) )
            {
                return( Apache2::Const::HTTP_NOT_ACCEPTABLE );
            }
            elsif( !( $ref = $self->auth_check ) )
            {
                return( Apache2::Const::HTTP_UNAUTHORIZED );
            }
        }
        # To implement the double submit security measure
        elsif( !$req->headers->get( 'X-CSRF-Token' ) )
        {
            return( Apache2::Const::HTTP_NOT_ACCEPTABLE );
        }
    });

=item I<content_type>

This handler, if present, is called from L</handler> before executing the code reference associated with the endpoint.

It is designed to check the content type in the request is acceptable as a security measure recommended and described in L<OWASP REST security cheat sheet|https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html>

For example:

    $self->is_allowed( content_type => sub
    {
        my $type = shift( @_ );
        # You can also get the request content type with:
        # my $type = $self->request->type;
    });

=item I<method>

This handler, if present, is called with the request method (e.g. GET, POST, etc) to check if it is allowed.

Note that C<OPTIONS> is different and should always be allowed to implement pre-flight check for L<CORS|https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS>

For example:

    $self->is_allowed( method => sub
    {
        my $meth = shift( @_ );
        my $ok_methods = [qw( GET POST )];
        return( Apache2::Const::HTTP_METHOD_NOT_ALLOWED ) if( !scalar( grep( $meth eq $_, @$ok_methods ) ) );
    });

Note that this is equivalent to setting the value of L</supported_methods> to an array reference with values C<GET POST>, but provides you with more granularity and control.

=item I<network>

This is called very early in L</handler> and is designed to check if the user's ip is authorised to access the api.

The handler is called with the remote ip address as a string.

This could be a good opportunity to check for api abuse and throttling.

For example:

    $self->is_allowed( network => sub
    {
        my $ip = shift( @_ );
        if( $self->is_banned( $ip ) )
        {
            return( Apache2::Const::HTTP_FORBIDDEN );
        }
        elsif( $self->is_throttled( $ip ) )
        {
            return( Apache2::Const::HTTP_TOO_MANY_REQUESTS );
        }
        else
        {
            # returning Apache2::Const::OK would work too although it is not the same value
            return( Apache2::Const::HTTP_OK );
        }
    });

=back

=head2 jwt_accepted_algo( string )

Get or set the algorithm supported for the JWT tokens.

=head2 jwt_accepted_encoding( string )

Get or set the supported encoding for the JWT tokens.

=head2 jwt_algo( string )

The chosen algorithm to create JWT tokens

=head2 jwt_decode( token )

Given a JWT token, this will decode it and returns a hash reference

=head2 jwt_encode

Provided with an hash reference of parameters, and this will prepare the token data and call L<Net::API::REST::JWT/encode_jwt>

It accepts the following arguments and additional arguments recognised by L<Net::API::REST::JWT> can also be provided and will be passed to L<Net::API::REST::JWT/encode_jwt> directly.

It returns the encrypted token as a string or C<undef> if an error occurred which can be retrieved using the L<Module::Generic/error> method.

=over 4

=item * C<algo>

This will set the I<alg> property in the token.

=item * C<audience>

This will set the I<aud> property in the token payload.

=item * C<encoding>

This will set the I<enc> property in the token payload.

=item * C<encrypt>

If true, this will encrypt the token. When provided this will affect the I<algo>.

For example, when not encrypted, by default the algorithm used is C<HS256>, but when encryption is activated, the algorithm becomes C<PBES2-HS256+A128KW>

=item * C<expires>

This will set the I<exp> property in the token payload.

=item * C<issued_at>

This will set the I<iat> property in the token payload.

=item * C<issuer>

This will set the I<iss> property in the token payload.

=item * C<key>

This will set the I<key> property in the token payload.

=item * C<payload>

The hash data to become the token payload. It can contains discretionary elements.

=item * C<subject>

This will set the I<sub> property in the token payload.

=item * C<ttl>

If provided, this will set the I<exp> property to I<iat> + I<ttl>

=back

=head2 jwt_encoding

=head2 jwt_encrypt

=head2 jwt_extract

=head2 jwt_verify

=head2 jwt_verify_audience

=head2 key

=head2 request()

Returns the L<Net::API::REST::Request> object. This object is set early during the instantiation in the B<handler> method.

=head2 response

Returns the L<Net::API::REST::Response> object. This object is set early during the instantiation in the B<handler> method.

=head2 route( URI object )

Given an uri, this will find the route for the endpoint sought and return and L<Net::API::REST::Endpoint> object.
If nothing found, it will return an empty string.
If there was an error, it will return C<undef> and set an error object that can be retrieved with the inherited L<Module::Generic/error> method. The error object will also contain a C<code> attribute which will represent an http status code.

L</route> is called from L</handler> to get the endpoint object and related handler, then calls the handler after performing a number of operations. See L</handler> for more information.

Otherwise, a L<Net::API::REST::Endpoint> is returned.

=head2 routes( hash reference )

This sets the routes for all the endpoints proposed by the RESTful server

=head2 supported_api_versions( array reference )

Get or set the list of supported api versions

=head2 supported_content_types

Get or set an array of supported content types, such as C<application/json>, C<text/html> or C<text/plain>

=head2 supported_languages( array reference )

Get or set the list of supported language codes, such as fr_FR, en_GB, ja_JP, zh_TW, etc

=head2 supported_methods( array reference )

=head2 well_known()

If the http request is for /.well-know, then we simply decline to process it.

This does not mean it won't get processed, but just that we pass and let Apache handle it directly.

=head2 _try( object type, method name, @_ )

Given an object type, a method name and optional parameters, this attempts to call it.

Apache2 methods are designed to die upon error, whereas our model is based on returning C<undef> and setting an exception with L<Module::Generic::Exception>, because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::REST::JWT>, L<Net::API::REST::Endpoint>, L<Net::API::REST::Request>, L<Net::API::REST::Response>

L<Apache2::API::DateTime>, L<Apache2::API::Query>, L<Apache2::API::Request>, L<Apache2::API::Response>, L<Apache2::API::Status>

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
