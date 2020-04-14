# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST.pm
## Version 0.5.4
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/09/01
## Modified 2020/04/14
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST;
BEGIN
{
	use strict;
	use common::sense;
	use parent qw( Module::Generic );
	use curry;
	use version;
	use Encode ();
	use Apache2::Const qw( :common :http );
	use Apache2::RequestRec ();
	use Apache2::RequestIO ();
	use Apache2::ServerUtil ();
	use Apache2::RequestUtil ();
	use Apache2::Response ();
	use Apache2::Reload;
	use Apache2::Log;
	use APR::Base64 ();
	use APR::UUID ();
	use JSON::PP ();
	use Regexp::Common;
	use TryCatch;
	use Devel::Confess;
	use Scalar::Util ();
	## use Crypt::JWT;
	## 2019-09-26
	## We use our own drop-in replacement because of a bug in ModPerl and JSON::XS not recognising hash reference passed
	use Net::API::REST::JWT;
	use DateTime;
	# use DateTime::Format::Strptime;
	use Net::API::REST::DateTime;
	use MIME::Base64 ();
# 	use IO::Compress::Gzip;
# 	use IO::Compress::Bzip2;
# 	use IO::Compress::Deflate;
	use Net::API::REST::Request;
	use Net::API::REST::Response;
	use Net::API::REST::Status;
	our( $VERSION, $DEBUG, $VERBOSE, $API_VERSION );
	$VERSION = '0.5.4';
};

{
	$VERBOSE = 0;
	$DEBUG   = 0;
	$API_VERSION = 1;
	our @AVAILABLE_API_VERSIONS = qw( 1 );
}

sub init
{
	my $self = shift( @_ );
	$self->{request} = '';
	$self->{response} = '';
	$self->{apache_request} = '' unless( $self->{apache_request} );
	## Routes to endpoint to which are attached resources
	$self->{routes} = {} unless( scalar( keys( %{$self->{routes}} ) ) );
	$self->{api_version} = 1 if( !length( $self->{api_version} ) );
	$self->{default_methods} = [qw( GET POST )] unless( $self->{default_methods} );
	$self->{supported_methods} = [qw( DELETE GET HEAD OPTIONS POST PUT )] unless( $self->{supported_methods} );
	$self->{supported_api_versions} = [qw( 1 )] unless( $self->{supported_api_versions} );
	$self->{key} = '' unless( length( $self->{key} ) );
	$self->{jwt_accepted_algo} = [] unless( length( $self->{jwt_accepted_algo} ) );
	$self->{jwt_accepted_encoding} = [] unless( length( $self->{jwt_accepted_encoding} ) );
	$self->{jwt_encrypt} = 1 unless( length( $self->{jwt_encrypt} ) );
	$self->{jwt_algo} = 'HS256' unless( length( $self->{jwt_algo} ) );
	$self->{jwt_encoding} = 'A128GCM' unless( length( $self->{jwt_encoding} ) );
	## 200Kb
	$self->{compression_threshold} = 204800 unless( length( $self->{compression_threshold} ) );
	$self->{lang} = '' unless( length( $self->{lang} ) );
	$self->{api_uri} = '' unless( length( $self->{api_uri} ) );
	$self->SUPER::init( @_ );
	if( length( $self->{api_version} ) )
	{
		$self->api_version( $self->{api_version} );
	}
	if( $self->{routes} )
	{
		$self->routes( $self->{routes} ) || return( undef() );
	}
	$self->supported_api_versions( $self->{supported_api_versions} ) if( $self->{supported_api_versions} );
	foreach my $k ( qw( jwt_encrypt jwt_algo jwt_encoding jwt_accepted_algo jwt_accepted_encoding ) )
	{
		$self->$k( $self->{ $k } );
	}
	return( $self );
}

sub apache_request { return( shift->_set_get_object( 'apache_request', 'Apache2::RequestRec', @_ ) ); }

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

sub bailout
{
	my $self = shift( @_ );
	my $msg;
	if( ref( $_[0] ) eq 'HASH' )
	{
		$msg = shift( @_ );
	}
	else
	{
		$msg = { code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR };
		$msg->{message} = join( '', @_ ) if( @_ );
	}
	## We send the error to our error method
	$msg->{code} ||= Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
	$self->error( $msg ) if( $msg->{message} );
	CORE::delete( $msg->{skip_frames} );
	## So it gets logged or displayed on terminal
	my( $pack, $file, $line ) = caller;
	my $sub_str = ( caller( 1 ) )[3];
	my $sub = CORE::index( $sub_str, '::' ) != -1 ? substr( $sub_str, rindex( $sub_str, '::' ) + 2 ) : $sub_str;
	$self->message( 0, "** ${pack}::${sub}() [${line}]: $msg->{message}" );
	## Now we tweak the hash to send it to the client
	$msg->{message} = CORE::delete( $msg->{public_message} ) || 'An unexpected server error has occurred';
	## Give it a chance to be localised
	$msg->{message} = $self->gettext( $msg->{message} );
	my $ctype = $self->response->content_type;
	if( $ctype eq 'application/json' )
	{
		return( $self->reply( $msg->{code}, { error => $msg->{message} } ) );
	}
	else
	{
		try
		{
			my $r = $self->apache_request;
			$r->status( $msg->{code} );
			$r->rflush;
			$->print( $msg->{message} );
			return( $msg->{code} );
		}
		catch( $e )
		{
			$self->message( 3, "An error occurred while printing out data." );
			return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
		}
	}
}

sub base_path { return( shift->_set_get_scalar( 'base_path', @_ ) ); }

sub compression_threshold { return( shift->_set_get_number( 'compression_threshold', @_ ) ); }

## https://perl.apache.org/docs/2.0/api/APR/Base64.html#toc_C_decode_
sub decode_base64
{
	my $self = shift( @_ );
	my $data = shift( @_ );
	try
	{
		return( APR::Base64::decode( $data ) );
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to base64 decode data: $e" ) );
	}
}

sub decode_json
{
	my $self = shift( @_ );
	my $raw  = shift( @_ ) || return( $self->error( "No json data was provided to decode." ) );
	my $json = $self->json;
	my $hash;
	try
	{
		$hash = $json->utf8->decode( $raw );
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to decode json payload: $e" ) );
	}
	return( $hash );
}

sub decode_utf8
{
	my $self = shift( @_ );
	my $v = shift( @_ );
# 	try
# 	{
# 		return( Encode::decode_utf8( @_, FB_CROAK ) );
# 	}
# 	catch( $e )
# 	{
# 		return( $self->error( "Error while decoding text: $e" ) );
# 	}
	my $rv = eval
	{
		## utf8 is more lax than the strict standard of utf-8; see Encode man page
		Encode::decode( 'utf8', $v, FB_CROAK );
	};
	if( $@ )
	{
		$self->error( "Error while decoding text: $@" );
		return( $v );
	}
	return( $rv );
}

# sub decode_utf8{ return( Encode::decode_utf8( $_[1] ) ); }

sub default_methods { return( shift->_set_get_array( 'default_methods', @_ ) ); }

## https://perl.apache.org/docs/2.0/api/APR/Base64.html#toc_C_encode_
# sub encode_base64 { return( APR::Base64::encode( @_ ) ); }
sub encode_base64
{
	my $self = shift( @_ );
	my $data = shift( @_ ) || return( $self->error( "No valid to base64 encode was provided." ) );
	try
	{
		return( APR::Base64::encode( $data ) );
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to base64 encode data: $e" ) );
	}
}

sub encode_json
{
	my $self = shift( @_ );
	my $hash = shift( @_ ) || return( $self->error( "No perl hash reference was provided to encode." ) );
	return( $self->error( "Hash provided ($hash) is not a hash reference." ) ) if( ref( $hash ) ne 'HASH' );
	my $json = $self->json;
	my $data;
	try
	{
		$data = $json->encode( $hash );
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to encode perl data: $e\nPerl data are: ", sub{ $self->printer( $hash ) } ) );
	}
	return( $data );
}

sub encode_utf8
{
	my $self = shift( @_ );
	my $v = shift( @_ );
# 	try
# 	{
# 		return( Encode::encode_utf8( $v, FB_CROAK ) );
# 	}
# 	catch( $e )
# 	{
# 		$self->error( "Error while encoding text: $e" );
# 		return( $v );
# 	}
	my $rv = eval
	{
		## utf8 is more lax than the strict standard of utf-8; see Encode man page
		Encode::encode( 'utf8', $v, FB_CROAK );
	};
	if( $@ )
	{
		$self->error( "Error while encoding text: $@" );
		return( $v );
	}
	return( $rv );
}

# sub encode_utf8 { return( Encode::encode_utf8( $_[1] ) ); }

sub endpoint { return( shift->_set_get_object( 'endpoint', 'Net::API::REST::Endpoint', @_ ) ); }

## https://perl.apache.org/docs/2.0/api/APR/UUID.html
sub generate_uuid
{
	my $self = shift( @_ );
	try
	{
		return( APR::UUID->new->format );
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to generate an uuid using APR::UUID package: $e" ) );
	}
}

sub get_auth_bearer
{
	my $self = shift( @_ );
	my $bearer = $self->request->authorization;
	## Found a bearer
	if( $bearer )
	{
		## https://jwt.io/introduction/
		## https://tools.ietf.org/html/rfc7519
		$self->message( 3, "An Authorization bearer http header was provided: '$bearer'." );
		if( $bearer =~ /^Bearer[[:blank:]]+([a-zA-Z0-9][a-zA-Z0-9\-\_\~\+\/\=]+(?:\.[a-zA-Z0-9\_][a-zA-Z0-9\-\_\~\+\/\=]+){2,4})$/i )
		{
			my $token = $1;
			$self->message( 3, "Returning '$token'" );
			return( $token );
		}
		else
		{
			$self->message( 3, "Authorization bearer failed to match our regular expression." );
			return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Bad bearer authorization format" }) );
		}
	}
	else
	{
		## Return empty, not undef, because undef is for errors
		$self->message( 3, "No authorization bearer found, returning blank." );
		return( '' );
	}
}

## https://perl.apache.org/docs/2.0/api/Apache2/ServerUtil.html
sub get_handlers { return( shift->_try( 'server', 'get_handlers', @_ ) ); }

## Does nothing and it should be superseded by a class inheriting our module
## This gives a chance to return a localised version of our string to the user
sub gettext { return( $_[1] ); }

## In Apache2 conf:
## PerlResponseHandler MyPackage::REST which would inherit from Net::API::REST
sub handler : method
{
	## my $r = shift( @_ );
	## https://perl.apache.org/docs/2.0/user/handlers/http.html#HTTP_Request_Handler_Skeleton
	my( $class, $r ) = @_;
	# my $handlerClass = $r->dir_config( 'Net_API_REST_Handler' ) || 'Net::API::REST' ;
    my $req = Net::API::REST::Request->new( $r, debug => $DEBUG );
    ## An error has occurred
    if( !defined( $req ) )
    {
    	return( Net::API::REST::Request->error->code || Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    }
	my $self = $class->new(
		apache_request => $r,
		debug 		=> $DEBUG,
		versbose 	=> $VERBOSE,
		request		=> $req,
	);
	if( my $code = $self->log_handler )
	{
		$r->set_handlers( 'PerlPrivateLogHandler' => $code );
	}
	# $self->apache_request( $r );
	# $r->log_error( "Received Apache request $r, object debug value is: ", $self->debug );
	$self->message( 3, "Received Apache request $r, object debug value is: ", $self->debug );
    ## Full uri. $r->uri only returns the path
	my $uri = $req->uri;
	# $self->message( 3, "Set api uri to: ", $uri->scheme . '://' . $uri->host );
	$self->api_uri( URI->new( $uri->scheme . '://' . $uri->host ) );
	$self->message( 3, "Set api uri to: ", $self->api_uri );
	$r->content_type( 'application/json' );
	my $json = JSON->new->relaxed->utf8;
	$self->{json} = $json;
	
	my $resp = Net::API::REST::Response->new( request => $req, debug => $DEBUG );
	## No need to go further if the requested method is not supported
	my $ok_methods = $self->supported_methods;
	my $http_meth = $req->method;
	$self->message( 3, "http method is $http_meth" );
	if( !scalar( grep( /^$http_meth$/i, @$ok_methods ) ) )
	{
		return( Apache2::Const::HTTP_METHOD_NOT_ALLOWED );
	}
	## Check if there is a required api version and if we support it
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
		return( $self->reply( Apache2::Const::HTTP_NOT_ACCEPTABLE, { error => "API version requested ($client_version) is not supported." } ) );
	}
	
	## Protection against DNS rebinding attacks
	## https://www.w3.org/TR/cors/#list-of-headers
	if( my $req_host = $req->headers( 'Host' ) )
	{
		my $req_host_uri = URI->new( $self->api_uri->scheme . '://' . $req_host );
		if( lc( $req_host_uri->host ) ne $self->api_uri->host )
		{
			$self->messagef( 3, "Request host '%s' does not match our server host name '%s'. This is a protection against attack using DNS rebinding.", $req_host_uri->host, $self->api_uri->host );
			return( Apache2::Const::HTTP_UNAUTHORIZED );
		}
	}
	
	$self->request( $req );
	$self->response( $resp );
	
	## If there is a init_headers handler, call it to initiate the headers
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
		## $r->send_http_header;
		return( Apache2::Const::HTTP_NO_CONTENT );
	}
	
	my $origin = $req->headers( 'Origin' );
	$self->http_cors if( $origin );
	
	my $path = $uri->path;
    if( my $base = $r->dir_config( 'Net_API_REST_Base' ) ) 
    {
        $self->base_path( $base );
    }
    $self->message( 3, "Finding out the route for uri '$uri'." );
    my $ep = $self->route( $uri );
    $self->message( 3, "Endpoint object returned is '$ep'." );
    if( !defined( $ep ) )
    {
    	$self->message( 3, "Search for endpoint returned an undefined value, ie an error for uri '$uri'." );
    	my $code = $self->error->code || Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    	return( $code );
    }
    ## No resource found matching the user request, returning a 400
    elsif( !length( $ep ) )
    {
    	$self->message( 3, "No route could be found for uri '$uri'." );
    	return( Apache2::Const::HTTP_BAD_REQUEST );
    }
    else
    {
    	$self->endpoint( $ep );
    	my $handler = $ep->handler;
    	my $vars = $ep->variables;
    	$req->variables( $vars );
    	# $self->message( 3, "Handler is ", $ep->handler );
#     	require B::Deparse;
# 		my $deparse = B::Deparse->new( '-p', '-sC' );
# 		my $meth_body = $deparse->coderef2text( $ep->handler );
# 		$self->message( 3, "Deparsed code ref is: $meth_body" );
		$self->noexec->messagef( 3, <<EOT, $handler, $ep->access, join( ', ', @{$ep->methods} ), join( ', ', @{$ep->path_info} ), $self->dumper( $ep->variables->as_hash ) );
Endpoint information:
Handler .......: %s
Access type ...: %s
Ok methods ....: %s
Path info .....: %s
Variables .....: %s
EOT
    	$self->message( 3, "Executing code \"$handler\" for uri \"$uri\"." );
    	try
    	{
    		my $rc = $ep->handler->();
    		$self->message( 3, "Handler returned with code '$rc'." );
    		## Server error
    		if( !defined( $rc ) )
    		{
    			return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
    		}
			elsif( $rc == Apache2::Const::HTTP_OK )
			{
				return( Apache2::Const::OK );
			}
			else
			{
				return( $rc );
			}
			## Stop sending data !!
			$self->request->socket->close;
			exit( 0 );
    	}
    	catch( $e )
    	{
    		$self->message( 3, "Error occured in executing handler: $e" );
    		$self->error({ code => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, message => $e });
    		# return( $self->reply( 500, { message => 'An internal server error occured' } ) );
    		return( $self->bailout( "An error occurred while executing code for api resource: $e" ) );
    	}
    }
}

sub header_datetime
{
	my $self = shift( @_ );
	my $dt;
	if( @_ )
	{
		return( $self->error( "Date time provided ($dt) is not an object." ) ) if( !Scalar::Util::blessed( $_[0] ) );
		return( $self->error( "Object provided (", ref( $_[0] ), ") is not a DateTime object." ) ) if( !$_[0]->isa( 'DateTime' ) );
		$self->message( 3, "Using the DateTime provided to us ($dt)." );
		$dt = shift( @_ );
	}
	$self->message( 3, "Generating a new DateTime object." ) if( !defined( $dt ) );
	$dt = DateTime->now if( !defined( $dt ) );
	my $fmt = Net::API::REST::DateTime->new;
	$dt->set_formatter( $fmt );
	$self->message( 3, "Returning datetime object '$dt'." );
	return( $dt );
}

## Mut be overriden by sub package
sub http_cors { return; }

## https://www.w3.org/TR/cors/#http-access-control-allow-origin
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
	$self->noexec->messagef( 3, <<EOT, $ep->handler, $ep->access, join( ', ', @{$ep->methods} ), join( ', ', @{$ep->path_info} ), $self->dumper( $ep->variables->as_hash ) );
Endpoint information:
Handler .......: %s
Access type ...: %s
Ok methods ....: %s
Path info .....: %s
Variables .....: %s
EOT

	my $req_methods = [CORE::split( /\,[[:blank:]]*/, $req->headers( 'Access-Control-Request-Method' ) )];
	$self->message( 3, "Requested methods are: '", join( "', '", @$req_methods ), "'." );
	foreach my $m ( @$req_methods )
	{
		if( !$ep->is_method_allowed( $m ) )
		{
			return( Apache2::Const::HTTP_METHOD_NOT_ALLOWED );
		}
	}
	
	my $origin = $req->headers( 'Origin' ) || $req->headers( 'Access-Control-Request-Origin' );
	if( !$origin )
	{
		$self->message( 3, "No origin provided, we're done and good." );
		return( Apache2::Const::HTTP_NO_CONTENT );
	}
	my $allow_origin = $req->headers( 'Access-Control-Allow-Origin' );
	## "The string "*" cannot be used for a resource that supports credentials"
	## https://www.w3.org/TR/cors/#http-access-control-allow-origin
	if( $allow_origin )
	{
		$self->message( 3, "Checking for requested origin '$origin' and allowed origin '$allow_origin'." );
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
			$self->message( 3, "Area is restricted by authentication, setting up the origin '", $self->api_uri, "' unless it is already provided? ($origin)." );
			if( $origin )
			{
				$res->headers( 'Access-Control-Allow-Origin' => $origin );
			}
			else
			{
				## Stringify
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
			$self->message( 3, "Anyone can access." );
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
	## Check from the most restrictive allowed methods in the context of the endpoint to the broader one for generally all supported methods
	my $ok_methods = scalar( @{$ep->methods} ) ? $ep->methods : $self->supported_methods;
	$res->headers( 'Access-Control-Allow-Methods' => join( ', ', @$ok_methods ) );
	
	# $r->headers_out->add( 'Allow' => join( ',', @$ok_methods ) );
	# $r->rflush;
	return( Apache2::Const::HTTP_NO_CONTENT );
}

## To be overriden by module inheriting our package
sub init_headers { return( 1 ); }

sub is_perl_option_enabled { return( shift->_try( 'request', 'is_perl_option_enabled', @_ ) ); }

# sub json
# {
# 	my $self = shift( @_ );
# 	if( !$self->{json} )
# 	{
# 		$self->{json} = JSON->new->allow_nonref;
# 	}
# 	return( $self->{json} );
# }
## We return a new object each time, because if we cached it, some routine might set the utf8 bit flagged on while some other would not want it
sub json { return( JSON::PP->new->relaxed->convert_blessed ); }

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
	## A simple decode, most likely for public jwt like google, linkedin, etc.
	elsif( scalar( @_ ) == 1 )
	{
		my $token = shift( @_ );
		$self->message( 3, "Received a single argument. Doing a simple decode for: $token" );
		my $data;
		try
		{
			## $data = Crypt::JWT::decode_jwt( token => $token );
			$data = Net::API::REST::JWT::decode_jwt( token => $token );
		}
		catch( $e )
		{
			return( $self->error( "There was an error decoding Json Web Token payload: $e" ) );
		}
		$self->message( 3, "Returning ", sub{ $self->dump( $data ) } );
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
	## verify_iss => sub{ 1; }
	verify_aud => qr{^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$},
	};
	# PBES2-HS256+A128KW
	## accepted_alg => qr{^(?:PBES2\-HS256\+A128KW|HS256)$},
	if( $opts->{accepted_algo} )
	{
		return( $self->error( "Accepted alorithm option must be an array reference." ) ) if( ref( $opts->{accepted_algo} ) ne 'ARRAY' );
		if( scalar( @{$opts->{accepted_algo}} ) )
		{
			my $re = join( '|', @{$opts->{accepted_algo}} );
			$param->{accepted_alg} = qr{^(?:\Q$re\E)$};
		}
	}
	
	## accepted_enc => qr{^(?:A128GCM)$},
	if( $opts->{accepted_enc} )
	{
		return( $self->error( "Accepted encoding option must be an array reference." ) ) if( ref( $opts->{accepted_enc} ) ne 'ARRAY' );
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
	try
	{
		## $data = Crypt::JWT::decode_jwt( %$param );
		$data = Net::API::REST::JWT::decode_jwt( %$param );
	}
	catch( $e )
	{
		return( $self->error( "There was an error decoding Json Web Token payload: $e" ) );
	}
	return( $data );
}

sub jwt_encode
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( @_ && ref( $_[0] ) eq 'HASH' );
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
	$self->message( 3, "Creating an encrypted jwt with payload: ", sub{ $self->dumper( $payload ) } );
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
	try
	{
		## $token = Crypt::JWT::encode_jwt(
		$token = Net::API::REST::JWT::encode_jwt(
			payload => $payload,
			## do NOT allow the "none" algorithm, as this is massively insecure
			allow_none => 0,
			alg  => $opts->{algo},
			key  => ( $opts->{key} || $self->key ),
			enc  => $opts->{encoding},
		);
	}
	catch( $e )
	{
		return( $self->error( "Error in the arguments or payload when creating a Jason Web Token: $e" ) );
	}
	return( $token );
}

sub jwt_encoding { return( shift->_set_get_scalar( 'jwt_encoding', @_ ) ); }

sub jwt_encrypt { return( shift->_set_get_scalar( 'jwt_encrypt', @_ ) ); }

## We extract the jwt data, and do not verify it, which is very unsecure of course
## Best to use jwt_verify()
sub jwt_extract
{
	my $self = shift( @_ );
	my $token = shift( @_ ) || return( $self->error( "No json web token was provided to extract its data." ) );
	return( $self->error( "Token provided ($token) seems malformed. I was expecting 3 chunks of base64 data separated by dots" ) ) if( $token !~ /^([^\.]+)\.([^\.]+)\.([^\.]+)$/ );
	my( $header, $claim, $crypto )  = split( /\./, $token, 3 );
	my $hash = {};
	try
	{
		$hash->{raw_header} = MIME::Base64::decode_base64( $header );
		$hash->{raw_claim} = MIME::Base64::decode_base64( $claim );
		my $j = JSON->new->allow_nonref;
		$hash->{header} = $j->utf8->decode( $hash->{raw_header} );
		$hash->{claim} = $j->utf8->decode( $hash->{raw_claim} );
	}
	catch( $e )
	{
		return( $self->error( "An error occured while attempting to extract token data: $e" ) );
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
	$self->message( 3, "Extracting token '$token'." );
	my $hash = $self->jwt_extract( $token ) || return( undef() );
	## Something like this:
	## Downloaded from https://accounts.google.com/.well-known/openid-configuration
	## and then from https://www.googleapis.com/oauth2/v3/certs
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
		$self->message( 3, "Options to verify using rsa keys provided: ", sub{ $self->dumper( $opts->{rsa_keys} ) } );
		return( $self->error( "RSA keys provided with parameter \"rsa_keys\" is not an hash reference." ) ) if( ref( $opts->{rsa_keys} ) ne 'HASH' );
		my $keys = $opts->{rsa_keys};
		return( $self->error( "No \"keys\" property found in the rsa keys provided." ) ) if( !$keys->{keys} );
		return( $self->error( "Property \"keys\" in rsa eys provided is not an array reference (of rsa keys)." ) ) if( ref( $keys->{keys} ) ne 'ARRAY' );
		## Check all is in order before going further
		my $n = 0;
		foreach my $ref ( @{$keys->{keys}} )
		{
			$n++;
			foreach my $p ( qw( kid e kty alg n ) )
			{
				return( $self->error( "No property \"$p\" could be found in this rsa key No $n. Hash is: ", sub{ $self->dump( $ref ) } ) ) if( !$ref->{ $p } );
			}
		}
		## Make sure our header has alg set to rsa and there is a kid property, or else Crypt::JWT will die
		## So at least, we can catch this issue and return an error gracefully...
		## {"alg":"RS256","kid":"0b0bf186743471a1edcac3060d1256f9e4050ba8","typ":"JWT"}
		my $header = $hash->{header} || return( $self->error( "Unable to get the header from the jwt token '$token'." ) );
		return( $self->error( "JWT token header returned by jwt_extract is empty! Original token is: '$token'" ) ) if( !scalar( keys( %$header ) ) );
		return( $self->error( "JWT token header found has no \"alg\" property set. Original token is: '$token'" ) ) if( !$header->{alg} );
		return( $self->error( "JWT token header found has no \"kid\" property set. Original token is: '$token'" ) ) if( !$header->{kid} );
		## https://metacpan.org/pod/Crypt::JWT#key
		return( $self->error( "JWT validation was requested using rsa keys, but could not find the property \"alg\" set to \"RS256\"." ) ) if( $header->{alg} !~ /^(RS|PS|ES)\d{3}$/i );
		my $kid = $header->{kid};
		## Check if kid value is in the rsa keys provided.
		my( $e, $n );
		foreach my $ref ( @{$keys->{keys}} )
		{
			if( $ref->{kid} eq $kid )
			{
				$e = $ref->{e};
				$n = $ref->{n};
				last;
			}
		}
		$self->message( 3, "Found 'e' to be '$e' and n to be '$n'." );
		return( $self->error( "Unable to find a matching key for the one found in the token header ($kid) against the rsa keys provided." ) ) if( !CORE::length( $e ) || !CORE::length( $n ) );
		## Ok, we are very reasonably safe to call Crypt::JWT now
		my $data;
		try
		{
			## $data = Crypt::JWT::decode_jwt( token => $token );
			## $data = Crypt::JWT::decode_jwt(
			$self->message( 3, "Calling Net::API::REST::JWT::decode_jwt" );
			$data = Net::API::REST::JWT::decode_jwt(
				token 			=> $token,
				kid_keys 		=> $keys,
				decode_payload 	=> 1,
				verify_exp 		=> 0,
				debug			=> 3,
			);
		}
		catch( $e )
		{
			$self->message( 3, "An error occured while decoding the JWT: $e" );
			return( $self->error( "Faile validating jwt token '$token'. Reason is: $e" ) );
		}
		## Ok, we're good
	}
	return( $hash );
}

sub jwt_verify_audience { return( shift->_set_get_object( 'jwt_verify_audience', 'Regexp', @_ ) ); }

sub key { return( shift->_set_get_scalar( 'key', @_ ) ); }

sub lang { return( shift->_set_get_scalar( 'lang', @_ ) ); }

sub lang_unix
{
	my $self = shift( @_ );
	my $lang = $self->{lang};
	$lang =~ tr/-/_/;
	return( $lang );
}

sub lang_web
{
	my $self = shift( @_ );
	my $lang = $self->{lang};
	$lang =~ tr/_/-/;
	return( $lang );
}

sub log_error { return( shift->_try( 'apache_request', 'log_error', @_ ) ); }

sub print
{
	my $self = shift( @_ );
	my $opts = {};
	if( scalar( @_ ) == 1 && ref( $_[0] ) )
	{
		$opts = shift( @_ );
	}
	else
	{
		$opts->{data} = join( '', @_ );
	}
	return( $self->error( "No data was provided to print out." ) ) if( !CORE::length( $opts->{data} ) );
	my $r = $self->apache_request;
	my $json = $opts->{data};
	my $bytes = 0;
	## Before we use this, we have to make sure all Apache module that deal with content encoding are de-activated because they would interfere
	my $threshold = $self->compression_threshold || 0;
	$self->messagef( 3, "Data to be returned is %d bytes and the threshold is $threshold. Does it exceed the threshold? %s", CORE::length( $json ), ( CORE::length( $json ) > $threshold ? 'yes' : 'no' ) );
	## rfc1952
	## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding
	if( CORE::length( $json ) > $threshold && 
		$self->request->accepted_encoding =~ /\bgzip\b/i && 
		( my $z = IO::Compress::Gzip->new( '-', Minimal => 1 ) ) )
	{
		$self->message( 3, "Using gzip compressed content." );
		#require Compress::Zlib;
		#$r->print( Compress::Zlib::memGzip( $json ) );
		# $r->content_encoding( 'gzip' );
		$self->response->content_encoding( 'gzip' );
		$self->response->headers->set( 'Content-Encoding' => 'gzip' );
		## Why Vary? https://blog.stackpath.com/accept-encoding-vary-important/
		## We use merge, because another value may already be set
		$self->response->headers->merge( 'Vary' => 'Accept-Encoding' );
		# $r->send_http_header;
		$z->print( $json );
		$z->close;
	}
	elsif( CORE::length( $json ) > $threshold && 
		$self->request->accepted_encoding =~ /\bbzip2\b/i &&
		( my $z = IO::Compress::Bzip2->new( '-' ) ) )
	{
		$self->message( 3, "Using bzip2 compressed content." );
		## $r->content_encoding( 'bzip2' );
		$self->response->content_encoding( 'bzip2' );
		$self->response->headers->set( 'Content-Encoding' => 'bzip2' );
		$self->response->headers->merge( 'Vary' => 'Accept-Encoding' );
		# $r->send_http_header;
		$z->print( $json );
		$z->close;
	}
	elsif( CORE::length( $json ) > $threshold && 
		$self->request->accepted_encoding =~ /\bdeflate\b/i && 
		( my $z = IO::Compress::Deflate->new( '-' ) ) )
	{
		$self->message( 3, "Using zip compressed content." );
		## $r->content_encoding( 'deflate' );
		$self->response->content_encoding( 'deflate' );
		$self->response->headers->set( 'Content-Encoding' => 'deflate' );
		$self->response->headers->merge( 'Vary' => 'Accept-Encoding' );
		# $r->send_http_header;
		$z->print( $json );
		$z->close;
	}
	else
	{
		$self->message( 3, "Using un-compressed content using \$r = $r." );
		$self->response->headers->unset( 'Content-Encoding' );
		# $self->response->content_encoding( undef() );
		# $r->send_http_header;
		# $r->print( $json );
		# $json = Encode::encode_utf8( $json ) if( utf8::is_utf8( $json ) );
		try
		{
			my $bytes = $r->print( $json );
			$self->message( 3, "$bytes sent to client." );
		}
		catch( $e )
		{
			$self->message( 3, "An error occurred while trying to send data to client: $e" );
		}
	}
	# $r->rflush;
	$self->response->rflush;
	return( $self );
}

## push_handlers($hook_name => \&handler);
## push_handlers($hook_name => [\&handler, \&handler2]);
sub push_handlers { return( shift->_try( 'server', 'push_handlers', @_ ) ); }

sub reply
{
	my $self = shift( @_ );
	my( $code, $ref );
	if( scalar( @_ ) == 2 )
	{
		( $code, $ref ) = @_;
	}
	elsif( ref( $_[0] ) eq 'HASH' )
	{
		$ref = shift( @_ );
		$code = $ref->{code} if( CORE::length( $ref->{code} ) );
	}
	$self->message( 3, "Code to be returned is '$code'." );
	my $r = $self->apache_request;
	# $self->message( 2, "Got Apache request object $r" );
	if( $code !~ /^[0-9]+$/ )
	{
		#$r->custom_response( Apache2::Const::SERVER_ERROR, "Was expecting an organisation id" );
		#$r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
		#$r->rflush;
		$self->response->code( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
		$self->response->rflush;
		# $r->send_http_header;
		#$r->print( $self->json->utf8->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
		$self->response->print( $self->json->utf8->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
		$self->error( "http code to be used '$code' is invalid. It should be only integers." );
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	}
	if( ref( $ref ) ne 'HASH' )
	{
		$self->response->code( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
		$self->response->rflush;
		# $r->send_http_header;
		$self->response->print( $self->json->utf8->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
		$self->error( "Data provided to send is not an hash ref." );
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	}
	
	my $msg;
	if( CORE::exists( $ref->{success} ) )
	{
		$msg = $ref->{success};
	}
	## Maybe error is a string, or maybe it is already an error hash like { error => { message => '', code => '' } }
	elsif( CORE::exists( $ref->{error} ) && !Net::API::REST::Status->is_success( $code ) )
	{
		$msg = $ref->{error};
		$ref->{error} = {} if( ref( $ref->{error} ) ne 'HASH' );
		$ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
		$ref->{error}->{message} = $msg if( !CORE::length( $ref->{error}->{message} ) && !ref( $msg ) );
		CORE::delete( $ref->{message} ) if( CORE::length( $ref->{message} ) );
		CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
	}
	elsif( CORE::exists( $ref->{message} ) )
	{
		$msg = $ref->{message};
		## We format the message like in bailout, ie { error => { message => '', code => '' } }
		if( $self->response->is_error( $code ) )
		{
			$ref->{error} = {} if( ref( $ref->{error} ) ne 'HASH' );
			$ref->{error}->{code} = $code if( !CORE::length( $ref->{error}->{code} ) );
			$ref->{error}->{message} = $ref->{message} if( !CORE::length( $ref->{error}->{message} ) );
			CORE::delete( $ref->{message} ) if( CORE::length( $ref->{message} ) );
			CORE::delete( $ref->{code} ) if( CORE::length( $ref->{code} ) );
		}
		else
		{
			$self->message( 3, "Code '$code' is not an error code." );
		}
	}
	my $frameOffset = 0;
	my $sub = ( caller( $frameOffset + 1 ) )[3];
	$frameOffset++ if( substr( $sub, rindex( $sub, '::' ) + 2 ) eq 'reply' );
	my( $pack, $file, $line ) = caller( $frameOffset );
	$sub = ( caller( $frameOffset + 1 ) )[3];
	$self->message( 2, "Returning http status with code $code, called from package $pack in file $file at line $line within sub $sub" );
	$self->response->content_type( 'application/json' );
	# $r->status( $code );
	$self->response->code( $code );
	if( defined( $msg ) && $self->apache_request->content_type ne 'application/json' )
	{
		# $r->custom_response( $code, $msg );
		$self->response->custom_response( $code, $msg );
	}
	else
	{
		# $r->custom_response( $code, '' );
		$self->response->custom_response( $code, '' );
		#$r->status( $code );
	}
	## We make sure the code is set
	if( CORE::exists( $ref->{error} ) && !Net::API::REST::Status->is_success( $code ) )
	{
		$ref->{error}->{code} = $code if( ref( $ref->{error} ) eq 'HASH' && !CORE::length( $ref->{error}->{code} ) );
		$self->messagef( 3, "Checking for a generic message for error code '$code' and language '%s'.", $self->lang_unix );
		my $err_description;
		if( !$ref->{error}->{error_description} && ( $err_description = $self->response->get_http_message( $code, $self->lang_unix ) ) )
		{
			$self->message( 3, "Found error description: '$err_description'." );
			$ref->{error}->{error_description} = $err_description;
		}
		else
		{
			$self->message( 3, "No error description found for http code '$code'." );
			$ref->{error}->{error_description} = $self->gettext( $self->response->get_http_message( $code ) );
		}
	}
	else
	{
		$ref->{code} = $code if( !CORE::length( $ref->{code} ) );
	}
	
	my $json = $self->json->utf8->encode( $ref );
	$self->message( 3, "Sending back json using encoding '", $self->response->content_encoding, "'" );
# 	try
# 	{
# 		my $bytes = $r->print( $json );
# 		$self->message( 3, "$bytes sent to client." );
# 	}
# 	catch( $e )
# 	{
# 		$self->message( 3, "An error occurred while trying to send data to client: $e" );
# 	}
# 	# $r->rflush;
# 	$self->response->rflush;
# 	$self->message( 3, "Returning code '$code'." );
# 	return( $code );
	
	
	## Before we use this, we have to make sure all Apache module that deal with content encoding are de-activated because they would interfere
	$self->print( $json ) || do
	{
		$self->message( 3, "Net::API::REST::print had an error." );
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	};
	$self->message( 3, "Returning code '$code'." );
	return( $code );
}

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
	$self->message( 3, "Checking route for uri '$uri' using path '$path'." );
	if( my $base = $self->base_path )
	{
		$path =~ s/^\Q$base\E//;
	}
	my @points = split( /\/+/ , $path );
    ## Clean up empty path
	my $parts = [ grep{ length( $_ ) > 0 } @points ];
	my $client_api_version = '';
	if( $parts->[0] =~ /^v?(\d+(?:\.\d+)*)$/ )
	{
		$client_api_version = $1;
		shift( @$parts );
	}
	$client_api_version ||= $self->request->client_api_version || $self->api_version;
	my $routes = $self->routes;
	return( $self->error({ code => 500, message => "No routes set up to find the appropriate resource." }) ) if( !scalar( keys( %$routes ) ) );
	return( $self->reply( Apache2::Const::HTTP_NOT_ACCEPTABLE, { error => "API version requested ($client_api_version) is not supported." } ) ) if( !CORE::exists( $routes->{ $client_api_version } ) );
	my $req = $self->request;
	my $resp = $self->response;
	## Path variables like "/some/path/1234/more/thing/jack" where 1234 and jack are variables
	## 2019-11-13: This is set by the caller of route()
	# my $vars = $req->variables;
	my $vars = {};
	my $def_methods = $self->default_methods;
	## Until proven otherwise; If it is set at a certain point of the path, and nowhere after, then the path below inherit its value set before like a toll gate
	my $access = 'public';
	local $check = sub
	{
		my( $pos, $subroutes ) = @_;
		my $part = $parts->[ $pos ];
		## reserved words cannot be used in path
		return( '' ) if( $part =~ /^_(access_control|allowed_methods|handler|name|var)$/i );
		if( exists( $subroutes->{ lc( $part ) } ) )
		{
			$part = lc( $part );
			## Code reference
			if( ref( $subroutes->{ $part } ) eq 'CODE' )
			{
				## Do we have still more path?
				## If we do, we store it as variable _path_info and let the handler deal with it
				# $vars->{_path_info} = [ splice( @$parts, $pos + 1 ) ] if( $#$parts > $pos );
				# return( $subroutes->{ $part } );
				$self->message( 3, "Pattern #1: found a terminal endpoint for '$part'." );
				my $ep = Net::API::REST::Endpoint->new(
					handler => $subroutes->{ $part },
					methods => $def_methods,
					variables => $vars,
					access => $access,
				);
				$ep->path_info( [ splice( @$parts, $pos + 1 ) ] ) if( $#$parts > $pos );
				return( $ep );
			}
			## path part has sub component, so we look for a key _handler in the sub hash
			elsif( ref( $subroutes->{ $part } ) eq 'HASH' )
			{
				my $ref = $subroutes->{ $part };
				return( $self->error({ code => 500, message => "Found an entry for path part \"$part\", which is a hash reference, but could not find a key \"_handler\" inside it." }) ) if( !exists( $ref->{_handler} ) );
				return( $self->error({ code => 500, message => "Found a route for the path part \"$part\", but the handler found is not a code reference." }) ) if( ref( $ref->{_handler} ) ne 'CODE' );
				## We reached the end, return the handler
				# return( $ref->{_handler} ) if( $pos == $#$parts );
				# return( $check->( $pos + 1, $ref ) );
				$access = $ref->{_access_control} if( $ref->{_access_control} );
				if( $pos == $#$parts )
				{
					$self->message( 3, "Pattern #2: found a hash defined endpoint for '$part'." );
					my $ep = Net::API::REST::Endpoint->new(
						handler => $ref->{_handler},
						methods => ( $ref->{_allowed_methods} ? $ref->{_allowed_methods} : $def_methods ),
						variables => $vars,
						access => $access,
					);
					return( $ep );
				}
				return( $check->( $pos + 1, $ref ) );
			}
			## Not a code or a hash reference, so it has got to be a package name
			elsif( $subroutes->{ $part } =~ /^([^\-]+)\-\>(\S+)$/ )
			{
				my( $cl, $meth ) = ( $1, $2 );
				try
				{
					## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
					## require $cl unless( defined( *{"${cl}::"} ) );
					my $rc = eval{ $self->_load_class( $cl ); };
					return( $self->error({ code => 500, message => "Unable to load class \"$cl\": $@" }) ) if( $@ );
					my $o = $cl->new( request => $req, response => $resp ) || return( $self->pass_error( $cl->error ) );
					my $code = $o->can( $meth );
					return( $self->error({ code => 500, message => "Class \"$cl\" does not have a method \"$meth\"." }) ) if( !$code );
					# return( sub{ $code->( $o, api => $self, @_ ) } );
					$self->message( 3, "Pattern #3: found a dynamic class '$cl' and method '$meth' endpoint for '$part'." );
					my $ep = Net::API::REST::Endpoint->new(
						handler => sub{ $code->( $o, api => $self, @_ ) },
						methods => $def_methods,
						variables => $vars,
						access => $access,
					);
					return( $ep );
				}
				catch( $e ) 
				{
					return( $self->error({ code => 500, message => $e }) );
				}
			}
			else
			{
				return( $self->error({ code => 500, message => "Found an entry for path part \"$part\" ($subroutes->{ $part }), but I do not know what to do with it. If this was supposed to be a package, the syntax needs to be My::Package->my_sub" }) );
			}
		}
		elsif( exists( $subroutes->{ '_var' } ) )
		{
			my $ref = $subroutes->{ '_var' };
			return( $self->error({ code => 500, message => "Found a variable, and I was expecting a hash reference, but intsead got '$ref'." }) ) if( ref( $ref ) ne 'HASH' );
			return( $self->error({ code => 500, message => "Found a variable, and I was expecting a key _name to be present in the definition hash reference, but could not find one." }) ) if( !exists( $ref->{_name} ) );
			return( $self->error({ code => 500, message => "Found a variable with name \"$ref->{_name}\" and was expecting a key _handler to be present in the definition hash reference, but could not find one." }) ) if( !exists( $ref->{_handler} ) );
			my $var_name = $ref->{_name};
			## For variable type to be array
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
			## Store variable value
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
			
			## We reached the end, return the handler
			if( $pos == $#$parts )
			{
				$access = $ref->{_access_control} if( $ref->{_access_control} );
				if( ref( $ref->{_handler} ) eq 'CODE' )
				{
					$self->message( 3, "Pattern #4: found a terminal endpoint with variable '$var_name' for '$part'." );
					# return( $ref->{_handler} );
					my $ep = Net::API::REST::Endpoint->new(
						handler => $ref->{_handler},
						methods => ( $ref->{_allowed_methods} ? $ref->{_allowed_methods} : $def_methods ),
						variables => $vars,
						access => $access,
					);
					$ep->access( $ref->{_access_control} ) if( $ref->{_access_control} );
					return( $ep );
				}
				elsif( $ref->{_handler} =~ /^([^\-]+)\-\>(\S+)$/ )
				{
					my( $cl, $meth ) = ( $1, $2 );
					try
					{
						## https://stackoverflow.com/questions/32608504/how-to-check-if-perl-module-is-available#comment53081298_32608860
						# require $cl unless( defined( *{"${cl}::"} ) );
						my $rc = eval{ $self->_load_class( $cl ); };
						return( $self->error({ code => 500, message => "Unable to load class \"$cl\": $@" }) ) if( $@ );
						my $o = $cl->new( request => $req, response => $resp ) || return( $self->pass_error( $cl->error ) );
						my $code = $o->can( $meth );
						return( $self->error({ code => 500, message => "Class \"$cl\" does not have a method \"$meth\"." }) ) if( !$code );
						# return( sub{ $code->( $o, api => $self, @_ ) } );
						$self->message( 3, "Pattern #5: found a dynamic endpoint with variable '$var_name' with class '$cl' and method '$meth' for '$part'." );
						my $ep = Net::API::REST::Endpoint->new(
							handler => sub{ $code->( $o, api => $self, @_ ) },
							methods => ( $ref->{_allowed_methods} ? $ref->{_allowed_methods} : $def_methods ),
							variables => $vars,
							access => $access,
						);
						return( $ep );
					}
					catch( $e ) 
					{
						return( $self->error({ code => 500, message => $e }) );
					}
				}
				else
				{
					return( $self->error({ code => 500, message => "Found a scalar \"$ref->{_handler}\" to handle variable \"$var_name\", but I do not know what to do with it. If this was supposed to be a package, the syntax needs to be My::Package->my_sub" }) );
				}
			}
			return( $check->( $pos + 1, $ref ) );
		}
		## Empty means not found
		else
		{
			return( '' );
		}
	};
	## We return empty, not undef if nothing was found
	my $ep = $check->( 0, $routes->{ $client_api_version } );
	## An error occurred
	if( !defined( $ep ) )
	{
		return( undef() );
	}
	## Nothing found
	elsif( !length( $ep ) )
	{
		return( '' );
	}
	else
	{
		$self->message( 3, "Returning endpoint object." );
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
		## Walk through the hash to check everything is ok
		## Returns nothing if all is ok, or self returns an error description
		local $check = sub
		{
			my $this = shift( @_ );
			foreach my $k ( sort( keys( %$this ) ) )
			{
				my $v = $this->{ $k };
				if( ref( $v ) eq 'HASH' )
				{
					if( !CORE::exists( $v->{_handler} ) )
					{
						return( "No handler was specified for the end point \"$k\". I was expecting a key \"_handler\" to be present." );
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
					## We're ok
				}
				elsif( $v =~ /^([^\:]+)\:{2}[^\:]+/ )
				{
					try
					{
						# my $cl = $subroutes->{ $part };
						my $cl = $v;
						my $meth;
						if( $cl =~ /^([^\-]+)\-\>(\S+)$/ )
						{
							( $cl, $meth ) = ( $1, $2 );
						}
						# require $cl unless( defined( *{"${cl}::"} ) );
						my $rc = eval{ $self->_load_class( $cl ); };
						return( $self->error({ code => 500, message => "Unable to load class \"$cl\": $@" }) ) if( $@ );
						my $o = $cl->new( checkonly => 1 ) || return( $self->pass_error( $cl->error ) );
						if( defined( $meth ) )
						{
							return( "Class \"$cl\" does not have a method \"$meth\"." ) if( !$o->can( $meth ) );
						}
					}
					catch( $e ) 
					{
						return( $self->error({ code => 500, message => $e }) );
					}
				}
				elsif( $k =~ /^_(allowed_methods|access_control)$/ )
				{
					## Ok
				}
				## If it is neither a code reference nor a package name, we raise an error
				else
				{
					return( "I was expecting a code reference or a package name, but instead got '$v' for key $k" );
				}
			}
		};
		## first level of keys are api version numbers, such as 1, 1.2, 2, etc...
		## and for each api version there is a set of route
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

sub server
{
	my $self = shift( @_ );
	try
	{
		my $r = $self->apache_request;
		return( $r->server ) if( $r );
		return( Apache2::ServerUtil->server );
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to get the Apache server object: $e" ) );
	}
}

## sub server_version { return( version->parse( Apache2::ServerUtil::get_server_version ) ); }
## Or maybe the environment variable SERVER_SOFTWARE, e.g. Apache/2.4.18
## sub server_version { return( version->parse( Apache2::ServerUtil::get_server_version ) ); }
sub server_version 
{
	my $self = shift( @_ );
	# $self->request->log_error( "Apache version is: " . Apache2::ServerUtil::get_server_description );
	$self->message( 3,  "Apache version is: " . Apache2::ServerUtil::get_server_description );
	return( version->parse( '2.4.18' ) );
}

## $ok = $s->set_handlers($hook_name => \&handler);
## $ok = $s->set_handlers($hook_name => [\&handler, \&handler2]);
## $ok = $s->set_handlers($hook_name => []);
## $ok = $s->set_handlers($hook_name => undef);
## https://perl.apache.org/docs/2.0/api/Apache2/ServerUtil.html#C_set_handlers_
sub set_handlers { return( shift->_try( 'server', 'set_handlers', @_ ) ); }

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

sub supported_languages { return( shift->_set_get_array( 'supported_languages', @_ ) ); }

sub supported_methods { return( shift->_set_get_array( 'supported_methods', @_ ) ); }

sub warn
{
	my $self = shift( @_ );
	my $txt = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
	my( $pkg, $file, $line, @otherInfo ) = caller;
	my $sub = ( caller( 1 ) )[3];
	my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
	my $trace = Devel::StackTrace->new;
    my $frame = $trace->next_frame;
    my $frame2 = $trace->next_frame;
    my $r = $self->apache_request;
    my $txt = sprintf( "$txt called from %s in package %s in file %s at line %d\n%s\n",  $frame2->subroutine, $frame->package, $frame->filename, $frame->line, $trace->as_string );
    return( $r->warn( $txt ) ) if( $r );
	return( CORE::warn( $txt ) );
}

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
	$r->log_error( "Net::API::REST::_try to call method \"$meth\" in package \"$pack\"." );
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

package Net::API::REST::Endpoint;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
};

sub init
{
	my $self = shift( @_ );
	## ACL
	$self->{access} = 'public';
	$self->{handler} = '';
	$self->{methods} = [];
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

sub methods { return( shift->_set_get_array( 'methods', @_ ) ); }

sub path_info { return( shift->_set_get_array( 'path_info', @_ ) ); }

sub variables { return( shift->_set_get_hash_as_object( 'variables', 'Net::API::REST::Endpoint::Variables', @_ ) ); }

1;

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
		## API version 1
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
		};
		$self->{api_version} = 1;
		$self->{supported_api_versions} = [qw( 1 )];
		## By default, we support the GET and POST to access our endpoints
		## It may be adjusted endpoint by endpoint and if nothing is specified this default is used.
		$self->{default_methods} = [qw( GET POST )];
		## This is ALL possible supported methods
		$self->{supported_methods} = [qw( DELETE GET HEAD OPTIONS POST PUT )];
		$self->{supported_languages} = [qw( en-GB en fr-FR fr ja-JP )];
		$self->{key} = 'kAncmaDajnacSnbGmbXamn';
		## We want JWE (Json Web Token encrypted). This will affect jwt_encode's behaviour
		$self->{jwt_encrypt} = 1;
		## Because we are encrypting
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
	
		## Do an IP source check to be sure this is Stripe talking to us
		if( !defined( my $ip_check = $stripe->webhook_validate_caller_ip({ ip => $remote_ip, ignore_ip => $ignore_ip }) ) )
		{
			return( $self->reply({ code => $stripe->error->code, message => $stripe->error->message }) );
		}
	
		## Now, we make sure this is Stripe sending this by checking the signature of the payload
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
	
		## Ok, if we are here, we passed al checks
		## Don't wait, reply ok back to Stripe so our request does not time out
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

    v0.5.4

=head1 DESCRIPTION

The purpose of this module is to provide a powerful, yet simple framework to implement a RESTful API under Apache2 mod_perl.

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<request>

This is a required parameter to be sent with a value set to a L<Apache2::RequestRec> object

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 apache_request()

Returns the L<Apache2::RequestRec> object.

=head2 api_uri()

Returns the api URI as a C<URI> object.

=head2 api_version( integer or decimal )

Get or sets the current api version on the server.

=head2 bailout( error string )

Given an error message, this will prepare the http header and response accordingly.

It will call B<gettext> to get the localised version of the error message, so this method is expected to be overriden by inheriting package.

If the outgoing content type set is C<application/json> then this will return a properly formatted standard json error, such as:

	{ "error": { "code": 401, "message": "Something went wrong" } }

Otherwise, it will send to the client the message as is.

=head2 base_path( path )

If in the Directory directive of the Apache Virtual Host, a C<Net_API_REST_Base> was set, this method will be set with this value.

=head2 compression_threshold( integer )

The number of bytes threshold beyond which, the B<reply> method will gzip compress the data returned to the client.

=head2 decode_base64( data )

Given some data, this will decode it using base64 algorithm. It uses L<APR::Base64::decode> in the background, because L<MIME::Decoder> may have some issue under mod_perl.

=head2 decode_json( data )

This decode from utf8 some data into a perl structure.

If an error occurs, it will return undef and set an exception that can be accessed with the B<error> method.

=head2 decode_utf8( data )

Decode some data from ut8 into perl internal utf8 representation.

If an error occurs, it will return undef and set an exception that can be accessed with the B<error> method.

=head2 default_methods( [ qw( GET POST ... ) ] )

This sets or gets the default methods supported by an endpoint.

=head2 encode_base64( data )

Given some data, this will encode it using base64 algorithm. It uses L<APR::Base64::encode> in the background, because L<MIME::Decoder> may have some issue under mod_perl.

=head2 encode_json( hash reference )

Given a hash reference, this will encode it into a json data representation.

However, this will not utf8 encode it, because this is done upon printing the data and returning it to the client.

=head2 encode_utf8( data )

This encode in ut8 the data provided and return it.

If an error occurs, it will return undef and set an exception that can be accessed with the B<error> method.

=head2 endpoint( [ Net::API::REST::Endpoint object ] )

This gets or sets an L<Net::API::REST::Endpoint> object.

=head2 generate_uuid()

Generates an uuid string and return it.

=head2 get_auth_bearer()

Checks whether an C<Authorization> http header was provided, and get the Bearer value.

If no header was found, it returns an empty string.

If an error occurs, it will return undef and set an exception that can be accessed with the B<error> method.

=head2 get_handlers()

Returns a reference to a list of handlers enabled for a given phase.

	$handlers_list = $res->get_handlers( $hook_name );

A list of handlers configured to run at the child_exit phase:

	@handlers = @{ $res->get_handlers( 'PerlChildExitHandler' ) || []};

=head2 gettext( 'string id' )

Get the localised version of the string passed as an argument.

This is supposed to be superseded by the package inheriting from L<Net::API::REST>

=head2 handler()

This is the main method called by Apache to handle the response. To make this work, in the Apache configuration, you must set the handler to your package and have your package inherit from L<Net::API::REST>. For example:

	PerlResponseHandler MyPackage

When called by Apache, B<handler> will initiate a L<Net::API::REST::Request> object and a L<Net::API::REST::Response>

If the incoming request is an OPTIONS request such as a typical one issued during a javascript Ajax call, it will call the method B<http_options>() which will also set the cors policy by calling B<http_cors>()

Finally, it will try to find a route for the endpoint sought in the incoming query, and construct a L<Net::API::REST::Endpoint> object with the context information of the endpoint, including information such as variables that could exist in the path. For example:

	/org/jp/llc/123/directors/42/profile

Here the llc property has an id 123 and the directors property has an id 42. Those two variables are stored in the L<net::API::REST::Endpoint> object. This object can then be accessed with the method B<endpoint>

Having found a route, B<handler> calls the anonymous subroutine in charge of handling the endpoint.

If no route was found, B<handler> returns a C<400 Bad Request>.

If the endpoint handler returns undef(), B<handler> will return a C<500 Server Error>, otherwise it will pass the return value back to Apache. The return value should be an L<Apache2::Const> return code.

=head2 header_datetime( DateTime object )

Given a C<DateTime> object, this sets it to GMT time zone and set the proper formatter (L<Net::API::REST::DateTime>) so that the stringification is compliant with http headers standard.

=head2 http_cors()

Checks http request context and set the proper CORS http headers.

=head2 http_options()

If the request is an OPTIONS request, this method is called. It will do a C<pre-flight check> and look forward to see if the user has access to the resource sought and sets the response http headers accordingly.

=head2 init_headers( code reference )

If this is set, then L<Net::API::REST::handler> will call it.

=head2 is_perl_option_enabled()

Checks if perl option is enabled in the Virtual Host and returns a boolean value

=head2 json()

Returns a JSON object.

=head2 jwt_accepted_algo( string )

Get or set the algorithm supported for the JWT tokens.

=head2 jwt_accepted_encoding( string )

Get or set the supported encoding for the JWT tokens.

=head2 jwt_algo( string )

The chosen algorithm to create JWT tokens

=head2 jwt_decode( token )

Given a JWT token, this will decode it and returns a hash reference

=head2 jwt_encode

=head2 jwt_encoding

=head2 jwt_encrypt

=head2 jwt_extract

=head2 jwt_verify

=head2 jwt_verify_audience

=head2 key

=head2 lang( string )

Set or get the current language

=head2 lang_unix( string )

Given a language, this returns a language code formatted the unix way, ie en-GB would become en_GB

=head2 lang_web( string )

Given a language, this returns a language code formatted the web way, ie en_GB would become en-GB

=head2 log_error( string )

Given a string, this will log the data into the error log.

When log_error is accessed with the L<Apache2::RequestRec> the error gets logged into the Virtual Host log, but when log_error gets accessed via the L<Apache2::ServerUtil> object, the error get logged into the Apache main error log.

=head2 print( list )

print out the list of strings and returns the number of bytes sent.

=head2 push_handlers

=head2 reply( http code, message | hash reference )

Given an http code and a message, or just a hash reference, B<reply> will find out if the code provided is an error and format the replied json appropriately like:

	{ "error": { "code": 400, "message": "Some error" } }

It will json encode the returned data and print it out back to the client after setting the http returned code.

=head2 request()

Returns the L<Net::API::REST::Request> object. This object is set early during the instantiation in the B<handler> method.

=head2 response

Returns the L<Net::API::REST::Response> object. This object is set early during the instantiation in the B<handler> method.

=head2 route( URI object )

Given an uri, this will find the route for the endpoint sought. If nothing found, it will return an empty string.

Otherwise, a L<Net::API::REST::Endpoint> is returned.

=head2 routes( hash reference )

This sets the routes for all the endpoints proposed by the RESTful server

=head2 server()

Returns a L<Apache2::Server> object

=head2 server_version()

Tries hard to find out the version number of the Apache server.

=head2 set_handlers()

=head2 supported_api_versions( array reference )

Get or set the list of supported api versions

=head2 supported_languages( array reference )

Get or set the list of supported language codes, such as fr_FR, en_GB, ja_JP, zh_TW, etc

=head2 supported_methods( array reference )

Get or set the list of supported http methods.

=head2 warn( list )

Given a list of string, this sends a warning.

=head2 well_known()

If the http request is for /.well-know, then we simply decline to process it.

This does not mean it won't get processed, but just that we pass and let Apache handle it directly.

=head2 _try( object type, method name, @_ )

Given an object type, a method name and optional parameters, this attempts to call it.

Apache2 methods are designed to die upon error, whereas our model is based on returning C<undef> and setting an exception with L<Module::Generic::Exception>, because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

=head1 Net::API::REST::Endpoint methods

=head2 access()

This specifies the level of access: private or restricted

=head2 handler()

Returns the handler found to handle the endpoint

=head2 is_method_allowed()

Returns a boolean on whether the given method is allowed.

=head2 methods()

Returns an array reference of the methods allowed for this endpoint.

=head2 path_info()

Returns a string for this path info, if any.

=head2 variables()

Returns a hash reference of name => value pairs for the variables found in the endpoint sought by in the http request. For example:

	/org/jp/llc/12/directors/23/profile

In this case, llc has an id value of 12 and the director an id value of 23. They will be recorded as variables as instructed by the route map set by the package using L<Net::API::REST>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

https://git.deguest.jp/jack/Net-API-REST

=head1 SEE ALSO

L<Apache2::Request>, L<Apache2::RequestRec>, L<Apache2::RequestUtil>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
