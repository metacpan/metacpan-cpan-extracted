# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Request.pm
## Version 0.8.3
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/09/01
## Modified 2020/01/13
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Request;
BEGIN
{
	use strict;
	use common::sense;
	use parent qw( Module::Generic );
	use Encode ();
	use Devel::Confess;
	use Apache2::Request;
	use Scalar::Util;
	use Apache2::Const;
	use Apache2::Connection ();
	use Apache2::RequestRec ();
	use Apache2::RequestUtil ();
	use Apache2::ServerUtil ();
	use Apache2::RequestIO ();
	use Apache2::Log;
	use APR::Pool ();
	use APR::Socket ();
	use APR::Request::Cookie;
	use APR::Request::Apache2;
	use Net::API::REST::Cookies;
	use URI;
	use URI::Query;
	use URI::Escape;
	use HTTP::AcceptLanguage;
	use Net::API::REST::DateTime;
	use DateTime;
	# use DateTime::Format::Strptime;
	use JSON;
	use TryCatch;
	use version;
	our $VERSION = '0.8.3';
	our @DoW = qw( Sun Mon Tue Wed Thu Fri Sat );
	our @MoY = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	our $MoY = {};
	@$MoY{ @MoY } = ( 1..12 );
	our $GMT_ZONE = { 'GMT' => 1, 'UTC' => 1, 'UT' => 1, 'Z' => 1 };
	our( $SERVER_VERSION );
};

sub init
{
	my $self = shift( @_ );
	my $r;
	$r = shift( @_ ) if( @_ % 2 );
	$self->{request} = $r;
	$self->{checkonly} = 0;
	$self->SUPER::init( @_ );
	$self->{variables} = {};
	$r ||= $self->{request};
	$self->{charset} = '';
	$self->{client_api_version} = '';
	$self->{auth} = '';
	$self->{_server_version} = '';
	## Which is an Apache2::Request, but inherits everything from Apache2::RequestRec and APR::Request::Apache2
	unless( $self->{checkonly} )
	{
		return( $self->error( "No Apache2::RequestRec was provided." ) ) if( !$r );
		return( $self->error( "Apache2::RequestRec provided ($r) is not an object!" ) ) if( !Scalar::Util::blessed( $r ) );
		return( $self->error( "I was expecting an Apache2::RequestRec, but instead I got \"$r\"." ) ) if( !$r->isa( 'Apache2::RequestRec' ) );
		$self->{request} = $r;
		my $headers = $self->headers;
		## rfc 6750 https://tools.ietf.org/html/rfc6750
		my $auth = $headers->{Authorization};
		$self->auth( $auth ) if( length( $auth ) );
		my $ctype_raw = $self->content_type;
		$self->message( 3, "Content-type of data received is '$ctype_raw'." );
		my $accept_raw = $self->accept;
		## Content-Type: application/json; encoding=utf-8
		my $ctype_def = $self->_split_str( $ctype_raw );
		## Accept: application/json; version=1.0; encoding=utf-8
		my $accept_def = $self->_split_str( $accept_raw );
		my $ctype = lc( $ctype_def->{value} );
		$self->type( $ctype );
		my $enc   = CORE::exists( $ctype_def->{param}->{charset} ) 
			? lc( $ctype_def->{param}->{charset} ) 
			: undef();
		$self->message( 3, "Found content type of '$ctype' and charset of '$enc'. \$ctype_def is: ", sub{ $self->dumper( $ctype_def ) } );
		my $accept = $accept_def->{value};
		my $client_api_version = CORE::exists( $accept_def->{param}->{version} ) 
			? $accept_def->{param}->{version}
			: undef();
		$self->charset( $enc ) if( length( $enc ) );
		$self->client_api_version( $client_api_version ) if( length( $client_api_version ) );
	
		my $json = $self->json;
		$self->messagef( 3, "Loading http payload data into buffer \$payload for length %d.", $self->length );
# 		my $payload = '';
# 		if( $self->length > 0 )
# 		{
# 			$r->read( $payload, $self->length );
# 		}
# 		elsif( lc( $ctype ) eq 'application/json' )
# 		{
# 			1 while( $r->read( $payload, 1096, CORE::length( $payload ) ) );
# 		}
		my $payload = $self->data;
		$self->messagef( 3, "Content-type is '$ctype' and length is %d", CORE::length( $payload ) );
		if( $ctype eq 'application/json' && CORE::length( $payload ) )
		{
			my $json_data = '';
			try
			{
				$json_data = $json->decode( $payload );
			}
			catch( $e )
			{
				$self->message( 3, "Error while trying to decode json paylod '$payload': $e" );
				return( $self->error({ code => Apache2::Const::HTTP_BAD_REQUEST, message => "Json data provided is malformed." }) );
			}
			$self->payload( $json_data );
		}
	}
	return( $self );
}

## Tells whether the connection has been aborted or not
sub aborted { return( shift->_try( 'connection', 'aborted' ) ); }

## e.g. text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
sub accept { return( shift->headers->{ 'Accept' } ); }

## e.g. gzip, deflate, br
sub accept_encoding { return( shift->headers->{ 'Accept-Encoding' } ); }

## e.g.: en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2
sub accept_language { return( shift->headers->{ 'Accept-Language' } ); }

## The allowed methods, GET, POST, PUT, OPTIONS, HEAD, etc
sub allowed { return( shift->_try( 'request', 'allowed', @_ ) ); }

sub as_string { return( shift->_try( 'request', 'as_string' ) ); }

sub auth { return( shift->_set_get_scalar( 'auth', @_ ) ); }

sub authorization { return( shift->headers( 'Authorization', @_ ) ); }

sub auth_type { return( shift->_try( 'request', 'auth_type', @_ ) ); }

## Must manually update the counter
## $r->connection->keepalives($r->connection->keepalives + 1);
## See Apache2::RequestRec
sub auto_header 
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $v = shift( @_ );
		return( $self->request->assbackwards( $v ? 0 : 1 ) );
	}
	return( $self->request->assbackwards );
}

## See Apache2::Request
sub body { return( shift->_try( 'request', 'body', @_ ) ); }

sub charset { return( shift->_set_get_scalar( 'charset', @_ ) ); }

sub checkonly { return( shift->_set_get_scalar( 'checkonly', @_ ) ); }

sub child_terminate { return( shift->_try( 'request', 'child_terminate' ) ); }

sub client_api_version
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $v = shift( @_ );
		unless( ref( $v ) eq 'version' )
		{
			$v = version->parse( $v );
		}
		$self->{client_api_version} = $v;
	}
	return( $self->{client_api_version} );
}

## Close the client connection
## APR::Socket->close is not implemented; left undone
## So this is a successful work around
sub close
{
	my $self = shift( @_ );
	## Using APR::Socket to get the fileno
	my $fd = $self->socket->fileno;
	my $sock = IO::File->new;
	if( $sock->fdopen( $fd, 'w' ) )
	{
		$self->message( 3, "Closing the Apache client connection." );
		return( $sock->close );
	}
	else
	{
		$self->message( 3, "Could not get a writable file handle on the socket file descriptor '$fd'." );
		return( 0 );
	}
}

sub code { return( shift->_try( 'request', 'status', @_ ) ); }

## Apache2::Connection
sub connection { return( shift->_try( 'request', 'connection' ) ); }

sub connection_id { return( shift->_try( 'connection', 'id' ) ); }

sub content { return( ${ shift->request->slurp_filename } ); }

sub content_encoding { return( shift->_try( 'request', 'content_encoding', @_ ) ); }

sub content_languages { return( shift->_try( 'request', 'content_languages', @_ ) ); }

sub content_length { return( shift->headers( 'Content-Length' ) ); }

# sub content_type { return( shift->_try( 'request', 'content_type' ) ); }
sub content_type
{
	my $self = shift( @_ );
	my $ct = $self->headers( 'Content-Type' );
	return( $ct ) if( !scalar( @_ ) );
	$self->error( "Warning only: caller is trying to use ", ref( $self ), " to set the content-type. Use Net::API::REST::Response for that instead." );
	return( $self->request->content_type( @_ ) );
}

## To get individual cookie sent. See APR::Request::Cookie
## APR::Request::Cookie
# sub cookie { return( shift->cookies->get( @_ ) ); }
sub cookie
{
	my $self = shift( @_ );
	my $name = shift( @_ );
	$self->message( 3, "Got here to get cookie name '$name'." );
	## An erro has occurred if this is undef
	my $jar = $self->cookies || return( undef() );
	$self->message( 3, "Found cookies jar object '$jar'. Getting cookie '$name'" );
	my $v;
	try
	{
		$v = $jar->get( $name );
		$v = URI::Escape::uri_unescape( $v ) if( CORE::length( $v ) );
	}
	catch( $e )
	{
		$self->message( 3, "An error occurred while trying to get the cookie for '$name': $e" );
	}
	return( $v );
}

## To get all cookies; then we can fetch then with $jar->get( 'this_cookie' ) for example
## sub cookies { return( shift->request->jar ); }
## https://grokbase.com/t/modperl/modperl/06c91r49n4/apache2-cookie-apr-request-cookie
# sub cookies { return( APR::Request::Apache2->handle( shift->request->pool )->jar ); }

# my $req = APR::Request::Apache2->handle( $self->r );
# my %cookies;
# if ( $req->jar_status =~ /^(?:Missing input data|Success)$/ ) {
# my $jar = $req->jar;
# foreach my $key ( keys %$jar ) {
# $cookies{$key} = $jar->get($key);
# }
# }
# 
# ## Send warning with headers to explain bad cookie
# else {
# warn( "COOKIE ERROR: "
# . $req->jar_status . "\n"
# . Data::Dumper::Dumper( $self->r->headers_in() ) );
# }

sub cookies_v1
{
	my $self = shift( @_ );
	try
	{
		$self->message( 3, "Getting Apache pool object." );
		my $pool = $self->request->pool;
		$self->message( 3, "Apache pool object is: '$pool'" );
		$self->message( 3, "Getting an APR Table object instance." );
		# my $o = APR::Request::Apache2->handle( $self->request->pool );
		my $o = APR::Request::Apache2->handle( $self->request );
		if( $o->jar_status =~ /^(?:Missing input data|Success)$/ )
		{
			$self->message( 3, "Object is '$o'. Returning the jar. Object has method 'jar'? ", ( $o->can( 'jar' ) ? 'yes' : 'no' ) );
			return( $o->jar );
		}
		else
		{
			$self->message( 3, "Malformed cookie found: ", $o->jar_status, "\nOriginal request is: ", $self->as_string );
		}
	}
	catch( $e )
	{
		return( $self->error( "An error occurred while trying to get the jar object of the APR::Request::Apache2: $e" ) );
	}
}

sub cookies
{
	my $self = shift( @_ );
	return( $self->{_jar} ) if( $self->{_jar} );
	my $jar = Net::API::REST::Cookies->new( request => $self, debug => $self->debug ) ||
	return( $self->error( "An error occurred while trying to get the cookie jar." ) );
	$jar->fetch;
	$self->{_jar} = $jar;
	return( $jar );
}

sub data
{
	my $self = shift( @_ );
	return( $self->{data} ) if( $self->{_data_processed} );
	my $r = $self->request;
	my $ctype = $self->type;
	my $payload = '';
	if( $self->length > 0 )
	{
		$self->messagef( 3, "Reading %d bytes of data", $self->length );
		$r->read( $payload, $self->length );
	}
	elsif( lc( $ctype ) eq 'application/json' )
	{
		$self->message( 3, "No data length is provided, but type is json so we read until the end." );
		1 while( $r->read( $payload, 1096, CORE::length( $payload ) ) );
	}
	$self->messagef( 3, "Found %d bytes of data read from http client.", CORE::length( $payload ) );
	try
	{
		## This is set during the init() phase
		my $charset = $self->charset;
		$self->message( 3, "Found charset '$charset'." );
		if( $charset )
		{
			$self->message( 3, "Decoding charset encoding with '$charset'." );
			$payload = Encode::decode( $charset, $payload, Encode::FB_CROAK );
		}
		else
		{
			$self->message( 3, "Decoding charset with default encoding 'utf8'." );
			$payload = Encode::decode_utf8( $payload, Encode::FB_CROAK );
		}
	}
	catch( $e )
	{
		$self->message( 3, "Character decoding failed with error: $e" );
		return( $self->error( "Error while decoding payload received from http client: $e" ) );
	}
	$self->{data} = $payload;
	$self->{_data_processed}++;
	return( $payload );
}

sub datetime { return( Net::API::REST::DateTime->new( debug => shift->debug ) ); }

sub document_root { return( shift->_try( 'request', 'document_root', @_ ) ); }

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

sub err_headers_out { return( shift->request->err_headers_out ); }

sub filename { return( shift->_try( 'request', 'filename' ) ); }

## APR::Finfo
sub finfo { return( shift->_try( 'request', 'finfo' ) ) }

## $handlers_list = $r->get_handlers($hook_name);
## https://perl.apache.org/docs/2.0/api/Apache2/RequestUtil.html#C_get_handlers_
sub get_handlers { return( shift->_try( 'request', 'get_handlers', @_ ) ); }

## e.g. get_status_line( 404 ) would return 404 Not Found
sub get_status_line { return( shift->_try( 'request', 'get_status_line', @_ ) ); }

sub global_request { return( Apache2::RequestUtil->request ); }

## sub headers { return( shift->request->headers_in ); }
sub headers
{
	my $self = shift( @_ );
	my $in = $self->request->headers_in;
	if( @_ )
	{
		my $v = shift( @_ );
		return( $in->{ $v } );
	}
	else
	{
		return( $in );
	}
}

sub headers_as_hashref
{
	my $self = shift( @_ );
	my $ref = {};
	my $h = $self->headers;
	while( my( $k, $v ) = each( %$h ) )
	{
		if( CORE::exists( $ref->{ $k } ) )
		{
			if( ref( $ref->{ $k } ) eq 'ARRAY' )
			{
				CORE::push( @{$ref->{ $k }}, $v );
			}
			else
			{
				my $old = $ref->{ $k };
				$ref->{ $k } = [];
				CORE::push( @{$ref->{ $k }}, $old, $v );
			}
		}
		else
		{
			$ref->{ $k } = $v;
		}
	}
	return( $ref );
}

sub headers_as_json
{
	my $self = shift( @_ );
	my $ref = $self->headers_as_hashref;
	my $json;
	try
	{
		## Non-utf8 encoded, because this resulting data may be sent over http or stored in a database which would typically encode data on the fly, and double encoding will damage data
		$json = $self->json->encode( $ref );
	}
	catch( $e )
	{
		return( $self->error( "An error occured while encoding the headers hash reference into json: $e" ) );
	}
	return( $json );
}

sub headers_in { return( shift->request->headers_in ); }

sub headers_out { return( shift->request->headers_out ); }

sub hostname { return( shift->_try( 'request', 'hostname' ) ); }

sub http_host { return( shift->uri->host ); }

sub id { return( shift->_try( 'connection', 'id' ) ); }

sub if_modified_since
{
	my $self = shift( @_ );
	my $v = $self->headers( 'If-Modified-Since' ) || return;
	return( $self->datetime->str2datetime( $v ) );
}

sub if_none_match { return( shift->headers( 'If-None-Match', @_ ) ); }

sub input_filters { return( shift->_try( 'request', 'input_filters' ) ); }

## A HEAD request maybe ?
sub is_header_only { return( shift->request->header_only ); }

## To find out if a PerlOptions is activated like +GlobalRequest or -GlobalRequest
sub is_perl_option_enabled { return( shift->_try( 'request', 'is_perl_option_enabled', @_ ) ); }

sub json
{
	my $self = shift( @_ );
	if( !$self->{json} )
	{
		$self->{json} = JSON->new->relaxed;
	}
	return( $self->{json} );
}

sub keepalive { return( shift->_try( 'connection', 'keepalive' ) ); }

sub keepalives { return( shift->_try( 'connection', 'keepalives' ) ); }

sub languages
{
	my $self = shift( @_ );
	my $lang = $self->accept_language || return( [] );
	my $al = HTTP::AcceptLanguage->new( $lang );
	my( @langs ) = $al->languages;
	return( \@langs );
}

sub length { return( shift->_try( 'request', 'bytes_sent' ) ); }

sub local_host { return( shift->_try( 'connection', 'local_host' ) ); }

sub local_ip { return( shift->_try( 'connection', 'local_ip' ) ); }

sub location { return( shift->_try( 'request', 'location' ) ); }

sub log_error { return( shift->_try( 'request', 'log_error' ) ); }

sub method { return( shift->_try( 'request', 'method' ) ); }

sub mtime { return( shift->_try( 'request', 'mtime' ) ); }

sub next { return( shift->_try( 'request', 'next' ) ); }

## Tells the client not to cache the response
sub no_cache { return( shift->_try( 'request', 'no_cache', @_ ) ); }

## Takes an APR::Table object
## There is also one available via the connection object
## I returns an APR::Table object which can be used like a hash ie foreach my $k ( sort( keys( %{$table} ) ) )
sub notes
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $hash = shift( @_ );
		return( $self->error( "Value provided is not a hash reference." ) ) if( ref( $hash ) ne 'HASH' );
		#my $pool = $self->pool->new;
		#my $table = APR::Table::make( $pool, 1 );
		#foreach my $k ( sort( keys( %$hash ) ) )
		#{
		#	$table->set( $k => $hash->{ $k } );
		#}
		my $r = $self->request;
		#$r->notes( $table );
		$r->pnotes( $hash );
	}
	return( $self->request->notes );
}

sub output_filters { return( shift->_try( 'request', 'output_filters' ) ); }

sub params
{
	my $self = shift( @_ );
	my $r = Apache2::Request->new( $self->request );
	return( $self->query ) if( $self->method eq 'GET' );
	## https://perl.apache.org/docs/1.0/guide/snippets.html#Reusing_Data_from_POST_request
	## my %params = $r->method eq 'POST' ? $r->content : $r->args;
	## Data are in pure utf8; not perl's internal, so it is up to us to decode them
	my( @params ) = $r->param;
	# $self->message( 3, "Found the following keys in post data: '", join( "', '", @params ), "'," );
	my $form = {};
	#my $io = IO::File->new( ">/tmp/form_data.txt" );
	#my $io2 = IO::File->new( ">/tmp/form_data_after_our_decoding.txt" );
	#my $raw = IO::File->new( ">/tmp/raw_form_data.txt" );
	#$io->binmode( ':utf8' );
	#$io2->binmode( ':utf8' );
	foreach my $k ( @params )
	{
		my( @values ) = $r->param( $k );
		# $self->message( 3, "Adding value '", $values[0], "' for key '$k'." );
		#$raw->print( "$k => " );
		#$io->print( "$k => " );
		my $name = Encode::is_utf8( $k ) ? $k : Encode::decode_utf8( $k );
		#$io2->print( "$name => " );
		$form->{ $name } = scalar( @values ) > 1 ? \@values : $values[0];
		if( ref( $form->{ $name } ) )
		{
			#$raw->print( "[\n" );
			#$io->print( "[\n" );
			#$io2->print( "[\n" );
			for( my $i = 0; $i < scalar( @{$form->{ $name }} ); $i++ )
			{
				#$raw->print( "\t[$i]: ", $form->{ $name }->[ $i ], "\n" );
				#$io->print( "\t[$i]: ", $form->{ $name }->[ $i ], "\n" );
				$form->{ $name }->[ $i ] = Encode::is_utf8( $form->{ $name }->[ $i ] ) ? $form->{ $name }->[ $i ] : Encode::decode_utf8( $form->{ $name }->[ $i ] );
				#$io2->print( "\t[$i]: ", $form->{ $name }->[ $i ], "\n" );
			}
			#$raw->print( "];\n" );
			#$io->print( "];\n" );
			#$io2->print( "];\n" );
		}
		else
		{
			#$raw->print( $form->{ $name }, "\n" );
			#$io->print( $form->{ $name }, "\n" );
			$form->{ $name } = Encode::is_utf8( $form->{ $name } ) ? $form->{ $name } : Encode::decode_utf8( $form->{ $name } );
			#$io2->print( $form->{ $name }, "\n" );
		}
	}
	#$raw->close;
	#$io->close;
	#$io2->close;
	return( $form );
}

sub path_info { return( shift->_try( 'request', 'path_info', @_ ) ); }

sub payload { return( shift->_set_get_hash( 'payload', @_ ) ); }

sub per_dir_config { return( shift->_try( 'rquest', 'per_dir_config' ) ); }

sub pnotes { return( shift->_try( 'request', 'pnotes', @_ ) ); }

sub pool { return( shift->_try( 'connection', 'pool' ) ); }

sub preferred_language
{
	my $self = shift( @_ );
	my $ok_langs = [];
	if( @_ )
	{
		return( $self->error( "I was expecting a list of supported languages as array reference, but instead I received this '", join( "', '", @_ ), "'." ) ) if( ref( $_[0] ) ne 'ARRAY' );
		## Make a copy
		$ok_langs = [ @{$_[0]} ];
		## Make sure the languages provided are in web format (e.g. en-GB), not unix format (e.g. en_GB)
		for( my $i = 0; $i < scalar( @$ok_langs ); $i++ )
		{
			$ok_langs->[ $i ] =~ tr/_/-/;
		}
	}
	else
	{
		return( $self->error( "No supported languages list was provided as array reference." ) );
	}
	# $self->messagef( 3, "Our support languages are '%s'.", join( "', '", @$ok_langs ) );
	## No supported languages was provided
	return( '' ) if( !scalar( @$ok_langs ) );
	# $self->message( 3, "Client accept language is: '", $self->accept_language, "'." );
	## The user has not set his/her preferred languages
	my $accept_langs = $self->accept_language || return( '' );
	# $self->message( 3, "http accept language is '$accept_langs', initiating a HTTP::AcceptLanguage object." );
	my $al = HTTP::AcceptLanguage->new( $accept_langs );
	## Get the most suitable one
	my $ok = $al->match( @$ok_langs );
	# $self->messagef( 3, "Best match found based on our support languages '%s' is '$ok'", join( "', '", @$ok_langs ) );
	return( $ok ) if( CORE::length( $ok ) );
	## No match, we return empty. undef is for error only
	return( '' );
}

sub prev { return( shift->_try( 'request', 'prev' ) ); }

sub protocol { return( shift->_try( 'request', 'protocol' ) ); }

sub proxyreq { return( shift->_try( 'request', 'proxyreq', @_ ) ); }

## push_handlers( PerlCleanupHandler => \&handler );
## $ok = $r->push_handlers($hook_name => \&handler);
## $ok = $r->push_handlers($hook_name => ['Foo::Bar::handler', \&handler2]);
## https://perl.apache.org/docs/2.0/api/Apache2/RequestUtil.html#C_push_handlers_
sub push_handlers { return( shift->_try( 'request', 'push_handlers', @_ ) ); }

sub query
{
	my $self = shift( @_ );
	my $qs = $self->query_string;
	my $qq = URI::Query->new( $qs );
	my %hash = $qq->hash;
	return( \%hash );
}

## Set/get a query string
sub query_string { return( shift->_try( 'request', 'args', @_ ) ); }

## Apache2::RequestIO
sub read { return( shift->_try( 'request', 'read', @_ ) ); }

sub referer { return( shift->headers->{Referer} ); }

## sub remote_addr { return( shift->connection->remote_ip ); }
sub remote_addr
{
	my $self = shift( @_ );
	my $vers = $self->server_version;
	my $serv = $self->request;
	## http://httpd.apache.org/docs/2.4/developer/new_api_2_4.html
	## We have to prepend the version with 'v', because it will faill when there is a dotted decimal with 3 numbers, 
	## e.g. 2.4.16 > 2.2 will return false !!
	## but v2.4.16 > v2.2 returns true :(
	## Already contacted the author about this edge case (2019-09-22)
	if( version->parse( "v$vers" ) > version->parse( 'v2.2' ) )
	{
		my $addr;
		try
		{
			$addr = $serv->useragent_addr;
		}
		catch( $e )
		{
			warn( "Unable to get the remote addr with the method useragent_addr: $e\n" );
			return( undef() );
		}
	}
	else
	{
		return( $self->connection->remote_addr );
	}
}

sub remote_host { return( shift->_try( 'connection', 'remote_host' ) ); }

## sub remote_ip { return( shift->connection->remote_ip ); }
sub remote_ip
{
	my $self = shift( @_ );
	my $vers = $self->server_version;
	$self->message( 3, "Checking if server version '$vers' is higher than 2.2" );
	my $serv = $self->request;
	$self->message( 3, "Is the REMOTE_ADDR environment variable available? (", $self->env( 'REMOTE_ADDR' ), ")" );
	## http://httpd.apache.org/docs/2.4/developer/new_api_2_4.html
	## We have to prepend the version with 'v', because it will faill when there is a dotted decimal with 3 numbers, 
	## e.g. 2.4.16 > 2.2 will return false !!
	## but v2.4.16 > v2.2 returns true :(
	## Already contacted the author about this edge case (2019-09-22)
	if( version->parse( "v$vers" ) > version->parse( 'v2.2' ) )
	{
		my $ip;
		try
		{
			$ip = $serv->useragent_ip;
		}
		catch( $e )
		{
			warn( "Unable to get the remote ip with the method useragent_ip: $e\n" );
		}
		$ip = $self->env( 'REMOTE_ADDR' ) if( !CORE::length( $ip ) );
		return( $ip ) if( CORE::length( $ip ) );
		return( undef() );
	}
	else
	{
		return( $self->connection->remote_ip );
	}
}

sub reply
{
	my $self = shift( @_ );
	my $code = shift( @_ );
	my $ref  = shift( @_ );
	my $r    = $self->request;
	my( $call_pack, $call_file, $call_line ) = caller;
	my $call_sub = ( caller(1) )[3];
	$self->message( 2, "Got Apache request object $r from package $call_pack in file $call_file at line $call_line from sub $call_sub" );
	if( $code !~ /^[0-9]+$/ )
	{
		#$r->custom_response( Apache2::Const::SERVER_ERROR, "Was expecting an organisation id" );
		$r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
		$r->rflush;
		# $r->send_http_header;
		$->print( $self->json->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
		$self->error( "http code to be used '$code' is invalid. It should be only integers." );
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	}
	if( ref( $ref ) ne 'HASH' )
	{
		$r->status( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
		$r->rflush;
		# $r->send_http_header;
		$->print( $self->json->encode({ 'error' => 'An unexpected server error occured', 'code' => 500 }) );
		$self->error( "Data provided to send is not an hash ref." );
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	}
	my $msg = CORE::exists( $ref->{ 'success' } ) 
		? $ref->{ 'success' } 
		: CORE::exists( $ref->{ 'error' } ) 
			? $ref->{ 'error' } 
			: undef();
	$self->message( 2, "Returning http status with code $code" );
	$r->status( $code );
	if( defined( $msg ) )
	{
		$r->custom_response( $code, $msg );
	}
	else
	{
		$r->status( $code );
	}
	$r->rflush;
	$ref->{code} = $code if( !CORE::exists( $ref->{code} ) );
	try
	{
		$->print( $self->json->encode( $ref ) );
		return( $code );
	}
	catch( $e )
	{
		$self->error( "An error occurred while calling Apache Request method \"print\": $e" );
		return( Apache2::Const::HTTP_INTERNAL_SERVER_ERROR );
	}
}

sub request { return( shift->_set_get_object( 'request', 'Apache2::Request', @_ ) ); }

# sub request_time { return( shift->request->request_time ); }
sub request_time
{
	my $self = shift( @_ );
	my $t = $self->request->request_time;
	my $dt = DateTime->from_epoch( epoch => $t, time_zone => 'local' );
	## A Net::API::REST::DateTime object
	my $fmt = $self->datetime;
	$dt->set_formatter( $fmt );
	return( $dt );
}

## Return Apache2::ServerUtil object
sub server { return( shift->request->server ); }

sub server_admin { return( shift->_try( 'server', 'server_admin', @_ ) ); }

sub server_hostname { return( shift->_try( 'server', 'server_hostname', @_ ) ); }

sub server_name { return( shift->_try( 'request', 'get_server_name' ) ); }

sub server_port { return( shift->_try( 'request', 'get_server_port' ) ); }

## Or maybe the environment variable SERVER_SOFTWARE, e.g. Apache/2.4.18
## sub server_version { return( version->parse( Apache2::ServerUtil::get_server_version ) ); }
sub server_version 
{
	my $self = shift( @_ );
	## Cached
	$self->{_server_version} = $SERVER_VERSION if( !CORE::length( $self->{_server_version} ) && CORE::length( $SERVER_VERSION ) );
	return( $self->{_server_version} ) if( CORE::length( $self->{_server_version} ) );
	## $self->request->log_error( "Apache version is: " . Apache2::ServerUtil::get_server_description );
	## e.g.: Apache version is: Apache/2.4.16 (Unix) PHP/5.5.38 mod_apreq2-20090110/2.8.0 mod_perl/2.0.10 Perl/v5.30.0
	## but could also be just 'Apache' depending on server configuration....
	my $desc = Apache2::ServerUtil::get_server_description;
	$self->message( 3, "Apache description is: '$desc'" );
	my $version;
	if( $desc =~ /\bApache\/([\d\.]+)/ )
	{
		$version = $1;
	}
	## XXX to test our alternative approach
	$self->message( 3, "Found Apache version '$version' from its description" );
	$version = undef();
	if( !defined( $version ) )
	{
		my $path = $self->env( 'PATH' );
		$self->message( 3, "PATH is: '$path'." );
		## Typical: /bin:/usr/bin:/usr/local/bin
		if( $path !~ /\/usr\/sbin/ )
		{
			my @path = CORE::split( /:/, $path );
			CORE::push( @path, '/usr/sbin', '/usr/local/sbin' );
			$path = join( ':', @path );
			$self->env( 'PATH' => $path );
			$self->message( 3, "PATH is now: ", $self->env( 'PATH' ) );
		}
		$self->message( 3, "Trying to find out the Apache version from its binary." );
		my $apache_bin;
		foreach my $bin ( qw( apache2 httpd ) )
		{
			$apache_bin = $self->_find_bin( $bin );
			last if( defined( $apache_bin ) );
		}
		$self->message( 3, "Found binary at $apache_bin" );
		if( defined( $apache_bin ) )
		{
			## e.g.:
			## Server version: Apache/2.4.16 (Unix)
			## Server built:   Jul 22 2015 21:03:09
			my $ver_str = qx( $apache_bin -v );
			$self->message( 3, "Version string is '$ver_str'" );
			if( ( split( /\r?\n/, $ver_str ) )[0] =~ /\bApache\/([\d\.]+)/ )
			{
				$version = $1;
			}
		}
	}
	$self->message( 3, "Returning version '$version'." );
	if( $version )
	{
		$self->{_server_version} = $SERVER_VERSION = version->parse( $version );
		return( $self->{_server_version} );
	}
	return( '' );
}

## e.g. set_basic_credentials( $user, $password );
sub set_basic_credentials { return( shift->_try( 'request', 'set_basic_credentials', @_ ) ); }

## set_handlers( PerlCleanupHandler => [] );
## $ok = $r->set_handlers($hook_name => \&handler);
## $ok = $r->set_handlers($hook_name => ['Foo::Bar::handler', \&handler2]);
## $ok = $r->set_handlers($hook_name => []);
## $ok = $r->set_handlers($hook_name => undef);
## https://perl.apache.org/docs/2.0/api/Apache2/RequestUtil.html#C_set_handlers_
sub set_handlers { return( shift->_try( 'request', 'set_handlers', @_ ) ); }

sub slurp_filename { return( shift->_try( 'request', 'slurp_filename' ) ); }

## Returns a APR::Socket
## See Apache2::Connection manual page
sub socket { return( shift->_try( 'connection', 'client_socket', @_ ) ); }

sub status { return( shift->_try( 'request', 'status', @_ ) ); }

sub status_line { return( shift->_try( 'request', 'status_line' ) ); }

sub subprocess_env { return( shift->_try( 'request', 'subprocess_env' ) ); }

sub type
{
	my $self = shift( @_ );
	if( @_ )
	{
		## Something like text/html, text/plain or application/json, etc...
		$self->{type} = shift( @_ );
	}
	elsif( !CORE::length( $self->{type} ) )
	{
		my $ctype_raw = $self->content_type;
		$self->message( 3, "Content-type of data received is '$ctype_raw'." );
		## Content-Type: application/json; encoding=utf-8
		my $ctype_def = $self->_split_str( $ctype_raw );
		## Accept: application/json; version=1.0; encoding=utf-8
		my $ctype = lc( $ctype_def->{value} );
		$self->{type} = $ctype if( $ctype );
		my $enc   = CORE::exists( $ctype_def->{param}->{charset} ) 
			? lc( $ctype_def->{param}->{charset} ) 
			: undef();
		$self->charset( $enc ) if( CORE::length( $enc ) );
	}
	return( $self->{type} );
}

sub unparsed_uri
{
	my $self = shift( @_ );
	my $uri = $self->uri;
	my $unparseed_path = $self->request->unparsed_uri;
	my $unparsed_uri = URI->new( $uri->scheme . '://' . $uri->host_port . $unparseed_path );
	return( $unparsed_uri );
}

#sub uri { return( URI->new( shift->request->uri( @_ ) ) ); }
## FYI, there is also the APR::URI module, but I could not see the value of it
## https://perl.apache.org/docs/2.0/api/APR/URI.html
sub uri
{
	my $self = shift( @_ );
	my $r = $self->request;
	my $host = $r->get_server_name;
	my $port = $r->get_server_port;
	my $proto = ( $port == 443 ) ? 'https' : 'http';
	my $path = $r->unparsed_uri;
	return( URI->new( "${proto}://${host}:${port}${path}" ) );
}

sub user { return( shift->_try( 'request', 'user' ) ); }

sub user_agent { return( shift->headers->{ 'User-Agent' } ); }

sub variables { return( shift->_set_get_hash( 'variables', @_ ) ); }

sub _find_bin
{
	my $self = shift( @_ );
	my $bin  = shift( @_ ) || return( '' );
	my $path = $self->env( 'PATH' );
	my @path = split( /\:/, $path );
	my $full_path;
	foreach my $dir ( @path )
	{
		if( -e( "$dir/$bin" ) && -f( "$dir/$bin" ) )
		{
			$full_path = "$dir/$bin";
			last;
		}
	}
	return( $full_path );
}

## Taken from http://www.perlmonks.org/bare/?node_id=319761
## This will do a split on a semi-colon, but being mindful if before it there is an escaped backslash
## For example, this would not be skipped: something\;here
## But this would be split: something\\;here resulting in something\ and here after unescaping
sub _split_str
{
	my $self = shift( @_ );
	my $s    = shift( @_ );
	return( {} ) if( !length( $s ) );
	my $sep  = @_ ? shift( @_ ) : ';';
	my @parts = ();
	my $i = 0;
	foreach( split( /(\\.)|$sep/, $s ) ) 
	{
		defined( $_ ) ? do{ $parts[$i] .= $_ } : do{ $i++ };
	}
	# $self->message( 3, "Field parts are: ", sub{ $self->dumper( \@parts ) } );
	my $header_val = shift( @parts );
	my $param = {};
	foreach my $frag ( @parts )
	{
		$frag =~ s/^[[:blank:]]+|[[:blank:]]+$//g;
		my( $attribute, $value ) = split( /[[:blank:]]*\=[[:blank:]]*/, $frag, 2 );
		# $self->message( 3, "\tAttribute is '$attribute' and value '$value'. Fragment processed was '$frag'" );
		$value =~ s/^\"|\"$//g;
		## Check character string and length. Should not be more than 255 characters
		## http://tools.ietf.org/html/rfc1341
		## http://www.iana.org/assignments/media-types/media-types.xhtml
		## Won't complain if this does not meet our requirement, but will discard it silently
		if( $attribute =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && length( $attribute ) <= 255 )
		{
			if( $value =~ /^[a-zA-Z][a-zA-Z0-9\_\-]+$/ && length( $value ) <= 255 )
			{
				$param->{ lc( $attribute ) } = $value;
			}
		}
	}
	return( { 'value' => $header_val, 'param' => $param } );
}

sub _try
{
	my $self = shift( @_ );
	my $pack = shift( @_ ) || return( $self->error( "No Apache package name was provided to call method" ) );
	my $meth = shift( @_ ) || return( $self->error( "No method name was provided to try!" ) );
	my $r = Apache2::RequestUtil->request;
	$r->log_error( "Net::API::REST::Request::_try to call method \"$meth\" in package \"$pack\"." );
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

__END__

=encoding utf8

=head1 NAME

Net::API::REST::Request - Apache2 Incoming Request Access and Manipulation

=head1 SYNOPSIS

	use Net::API::REST::Request;
	## $r is the Apache2::RequestRec object
	my $req = Net::API::REST::Request->new( request => $r, debug => 1 );
	## or, to test it outside of a modperl environment:
	my $req = Net::API::REST::Request->new( request => $r, debug => 1, checkonly => 1 );

=head1 VERSION

    v0.8.3

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

=item I<checkonly>

If true, it will not perform the initialisation it would usually do under modperl.

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 aborted()

Tells whether the connection has been aborted or not

=head2 accept()

Returns the http C<Accept> header value, such as C<text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8>

=head2 accept_encoding()

Returns the http C<Accept-Encoding> header value

=head2 accept_language()

Returns the http C<Accept-Language> header value such as C<en-GB,fr-FR;q=0.8,fr;q=0.6,ja;q=0.4,en;q=0.2>

=head2 allowed()

Returns the allowed methods, such as GET, POST, PUT, OPTIONS, HEAD, etc

=head2 as_string()

Returns the http request as a string

=head2 auth()

Returns the C<Authorization> header value if any. This ill have been processed upo object initiation phase.

=head2 authorization()

Returns the http C<authorization> header value. This is similar to B<auth>().

=head2 auth_type()

Returns the authentication type

=head2 auto_header( boolean )

Given a boolean value, this enables the auto header or not. In the back, this calls the method B<assbackwards>

If this is disabled, you need to make sure to manually update the counter, such as:

	$req->connection->keepalives( $req->connection->keepalives + 1 );

See L<Apache2::RequestRec> for more information on this.

=head2 body( name )

Returns an APR::Request::Param::Table object containing the POST data parameters of the Apache2::Request object.

	my $body = $req->body;

An optional name parameter can be passed to return the POST data parameter associated with the given name:

	my $foo_body = $req->body("foo");

This is similar to the C<param> method with slight difference. Check L<Apache2::Request> for more information.

=head2 charset()

Returns the charset, if any, found in the http request received and processed upon initialisation of this module object.

=head2 checkonly( boolean )

This is also an object initialisation property.

If true, this will discard the normal processing of incoming http request under modperl.

This is useful and intended when testing this module offline.

=head2 child_terminate()

Terminate the current worker process as soon as the current request is over.

See L<Apache::RequestUtil> for more information.

=head2 client_api_version()

Returns the client api version requested, if provided. This is set during the object initialisation phase.

An example header to require api version 1.0 would be:

	Accept: application/json; version=1.0; encoding=utf-8

=head2 close()

This close the client connection.

This is not implemented in by L<APR::Socket>, so this is an efficient work around.

However, a word of caution, you most likely do not need or want to close manually the client connection and instea have your method return Apache2::Const::OK or any other constant matching the http code you want to return.

=head2 code()

Returns the response status code.

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result.  However, there are rare instances when you want to trick Apache into thinking that the module returned an "Apache2::Const::OK" status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler.  The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning "Apache2::Const::OK" to Apache. e.g.:

	$req->status( $some_code );
	return( Apache2::Const::OK );

=head2 connection()

Returns a L<Apache2::Connection> object.

=head2 connection_id()

Returns the connection id; unique at any point in time. See L<Apache2::Connection> for more information.

=head2 content()

Returns the content of the file specified with C<$req->filename>. It calls B<slurp_filename> from L<Apache2::Request>, but instead of returning a scalar reference, it returns the data itself.

=head2 content_encoding()

Returns the value of the C<Content-Encoding> HTTP response header

=head2 content_languages()

Retrieves the value of the C<Content-Language> HTTP header

=head2 content_length()

Returns the length in byte of the request body.

=head2 content_type()

Retrieves the value of the Content-type header value. See L<Apache2::RequestRec> for more information.

=head2 cookie( name )

Returns the current value for the given cookie name.

This works by calling the B<cookies> method, which returns a cookie jar object which is a L<Net::API::REST::Cookies> object.

=head2 cookies()

Returns a L<Net::API::REST::Cookies> object acting as a jar with various methods to access, manipulate and create cookies.

=head2 data()

Read the incoming data payload and decode it from its encoded charset into perl internal utf8.

This is specifically designed for json payload.

It returns a string of data.

=head2 document_root( [ string ] )

Retrieve the document root for this server.

If a value is provided, it sets the document root to a new value only for the duration of the current request.

See L<Apache2::RequestUtil> for more information.

=head2 env

=head2 err_headers_out( hash )

Get/set MIME response headers, printed even on errors and persist across internal redirects.

According to the L<Apache2::RequestRec> documentation:

The difference between "headers_out" and "err_headers_out", is that the latter are printed even on error, and persist across internal redirects (so the headers printed for "ErrorDocument" handlers will have them).

For example, if a handler wants to return a 404 response, but nevertheless to set a cookie, it has to be:

	$r->err_headers_out->add( 'Set-Cookie' => $cookie );
	return( Apache2::Const::NOT_FOUND );

If the handler does:

	$r->headers_out->add( 'Set-Cookie' => $cookie );
	return( Apache2::Const::NOT_FOUND );

the C<Set-Cookie> header won't be sent.

See L<Apache2::RequestRec> for more information.

=head2 filename( string )

Get/set the filename on disk corresponding to this response

See L<Apache2::RequestRec> for more information.

=head2 finfo()

Get and set the finfo request record member

See L<Apache2::RequestRec> for more information.

=head2 get_handlers( hook_name )

Returns a reference to a list of handlers enabled for a given phase.

	$handlers_list = $r->get_handlers( $hook_name );

Example, a list of handlers configured to run at the response phase:

	my @handlers = @{ $r->get_handlers('PerlResponseHandler') || [] };

=head2 get_status_line()

Return the "Status-Line" for a given status code (excluding the HTTP-Version field).

For example:

	print( $req->get_status_line( 400 ) );

will print:

	400 Bad Request

=head2 global_request()

Returns the L<Apache2::RequestRec> object made global with the proper directive in the Apache VirtualHost configuration.

This calls the module L<Apache::RequestUtil> to retrieve this value.

=head2 headers( string )

Returns a hash reference of headers key => value pairs. If a header name is provided, this will return its value instead.

This calls the method B<headers_in>() behind.

=head2 headers_as_hashref()

Returns the list of headers as an hash reference.

=head2 headers_as_json()

Returns the list of headers as a json data

=head2 headers_in()

Returns the list of the headers as hash or the individual value of a header:

	my $cookie = $r->headers_in->{Cookie} || '';

=head2 headers_out( name, [ value ] )

Returns or sets the key => value pairs of outgoing http headers, only on 2xx responses.

See also "err_headers_out", which allows to set headers for non-2xx responses and persist across internal redirects.

More information at L<Apache2::RequestRec>

=head2 hostname( [ hostname ] )

Retrieve or set the http server host name, such as www.example.com.

This is not the machine hostname.

More information at L<Apache2::RequestRec>

=head2 http_host()

Returns an C<URI> object of the http host being accessed. This is created during object initiation phase.

=head2 id()

Returns the connection id; unique at any point in time. See L<Apache2::Connection> for more information.

This is the same as B<connection_id>()

=head2 if_modified_since()

Returns the value of the http header If-Modified-Since as a C<DateTime> object.

If no such header exists, it returns C<undef()>

=head2 if_none_match()

Returns the value of the http header C<If-None-Match>

=head2 input_filters( [ filter ] )

Get/set the first filter in a linked list of request level input filters. It returns a L<Apache2::Filter> object.

	$input_filters      = $r->input_filters();
	$prev_input_filters = $r->input_filters( $new_input_filters );

According to the L<Apache2::RequestRec> documentation:

For example instead of using C<$r->read()> to read the POST data, one could use an explicit walk through incoming bucket brigades to get that data. The following function C<read_post()> does just that (in fact that's what C<$r->read()> does behind the scenes):

	 use APR::Brigade ();
	 use APR::Bucket ();
	 use Apache2::Filter ();

	 use Apache2::Const -compile => qw(MODE_READBYTES);
	 use APR::Const    -compile => qw(SUCCESS BLOCK_READ);

	 use constant IOBUFSIZE => 8192;

	 sub read_post {
		 my $r = shift;

		 my $bb = APR::Brigade->new($r->pool,
									$r->connection->bucket_alloc);

		 my $data = '';
		 my $seen_eos = 0;
		 do {
			 $r->input_filters->get_brigade($bb, Apache2::Const::MODE_READBYTES,
											APR::Const::BLOCK_READ, IOBUFSIZE);

			 for (my $b = $bb->first; $b; $b = $bb->next($b)) {
				 if ($b->is_eos) {
					 $seen_eos++;
					 last;
				 }

				 if ($b->read(my $buf)) {
					 $data .= $buf;
				 }

				 $b->remove; # optimization to reuse memory
			 }

		 } while (!$seen_eos);

		 $bb->destroy;

		 return $data;
	 }

As you can see C<$r->input_filters> gives us a pointer to the last of the top of the incoming filters stack.


=head2 is_header_only()

Returns a boolean value on whether the request is a C<HEAD> request or not.

=head2 is_perl_option_enabled()

Check whether a directory level "PerlOptions" flag is enabled or not. This returns a boolean value.

For example to check whether the "SetupEnv" option is enabled for the current request (which can be disabled with "PerlOptions -SetupEnv") and populate the environment variables table if disabled:

	 $r->subprocess_env unless $r->is_perl_option_enabled('SetupEnv');

See also: PerlOptions and the equivalent function for server level PerlOptions flags.

See the L<Apache2::RequestUtil> module documentation for more information.

=head2 json()

Returns a C<JSON> object with the C<relaxed> attribute enabled so that it allows more relaxed json data.

=head2 keepalive()

This method answers the question: Should the the connection be kept alive for another HTTP request after the current request is completed?

	 use Apache2::Const -compile => qw(:conn_keepalive);
	 ...
	 my $c = $r->connection;
	 if ($c->keepalive == Apache2::Const::CONN_KEEPALIVE) {
		 # do something
	 }
	 elsif ($c->keepalive == Apache2::Const::CONN_CLOSE) {
		 # do something else
	 }
	 elsif ($c->keepalive == Apache2::Const::CONN_UNKNOWN) {
		 # do yet something else
	 }
	 else {
		 # die "unknown state";
	 }

Notice that new states could be added later by Apache, so your code should make no assumptions and do things only if the desired state matches.

See L<Apache2::Connection> for more information.

=head2 keepalives()

How many requests were already served over the current connection.

This method is only relevant for keepalive connections. The core connection output filter "ap_http_header_filter" increments this value when the response headers are sent and it decides that the connection should not be closed (see "ap_set_keepalive()").

If you send your own set of HTTP headers with "$r->assbackwards", which includes the "Keep-Alive" HTTP response header, you must make sure to increment the "keepalives" counter.

See L<Apache2::Connection> for more information.

=head2 languages()

This will check the Accept-Languages http headers and derived a list of priority ordered user preferred languages and return an array reference.

See also the B<preferred_language> method.

=head2 length()

Returns the length in bytes of the request body.

=head2 local_host()

Used for ap_get_server_name when UseCanonicalName is set to DNS (ignores setting of HostnameLookups)

Better to use the B<server_name> instead.

=head2 local_ip()

Return our server IP address as string.

=head2 location()

Get the path of the <Location> section from which the current "Perl*Handler" is being called.

Returns a string.

=head2 log_error( string )

=head2 main()

Get the main request record and returns a L<Apache2::RequestRec> object.

If the current request is a sub-request, this method returns a blessed reference to the main request structure. If the current request is the main request, then this method returns C<undef>.

To figure out whether you are inside a main request or a sub-request/internal redirect, use C<$r->is_initial_req>.

=head2 method( string )

Get/set the current request method (e.g. "GET", "HEAD", "POST", etc.).

if a new value was passed the previous value is returned.

=head2 mtime()

Last modified time of the requested resource.

Returns a timestamp in second since epoch.

=head2 next()

Pointer to the redirected request if this is an external redirect.

Returns a L<Apache2::RequestRec> blessed reference to the next (internal) request structure or C<undef> if there is no next request.

=head2 no_cache()

Add/remove cache control headers. A true value sets the "no_cache" request record member to a true value and inserts:

	 Pragma: no-cache
	 Cache-control: no-cache

into the response headers, indicating that the data being returned is volatile and the client should not cache it.

A false value unsets the "no_cache" request record member and the mentioned headers if they were previously set.

This method should be invoked before any response data has been sent out.

See L<Apache2::RequestUtil> for more information.

=head2 notes( string )

Get/set text notes for the duration of this request. These notes can be passed from one module to another (not only mod_perl, but modules in any other language).

If a new value was passed, returns the previous value.

The returned value is a L<APR::Table> object.

=head2 output_filters( [ filter ] )

Get the first filter in a linked list of request level output filters. It returns a L<Apache2::Filter> object.

If a new output filters was passed, returns the previous value.

According to the L<Apache::RequestRec> documentation:

For example instead of using C<$r->print()> to send the response body, one could send the data directly to the first output filter. The following function C<send_response_body()> does just that:

	 use APR::Brigade ();
	 use APR::Bucket ();
	 use Apache2::Filter ();

	 sub send_response_body 
	 {
		 my( $r, $data ) = @_;

		 my $bb = APR::Brigade->new( $r->pool,
									 $r->connection->bucket_alloc );

		 my $b = APR::Bucket->new( $bb->bucket_alloc, $data );
		 $bb->insert_tail( $b );
		 $r->output_filters->fflush( $bb );
		 $bb->destroy;
	 }

In fact that's what C<$r->read()> does behind the scenes. But it also knows to parse HTTP headers passed together with the data and it also implements buffering, which the above function does not.
       
=head2 params( key => value )

Get the request parameters (using case-insensitive keys) by mimicing the OO interface of L<CGI::param>.

It can take as argument, only a key and it will then retrive the corresponding value, or it can take a key and value pair.

If the value is an array, this will set multiple entry of the key for each value provided.

This uses Apache L<APR::Table> and works for both POST and GET methods.

If the methods received was a GET method, this method returns the value of the B<query> method instead.

=head2 path_info( string )

Get/set the C<PATH_INFO>, what is left in the path after the URI --> filename translation.

Return a string as the current value.

=head2 payload()

Returns the json data decoded into a perl structure. This is set at object initiation phase and calls the B<data> method to read the incoming data and decoded it into perl internal utf8.

=head2 per_dir_config()

Get the dir config vector. Returns a L<Apache2::ConfVector> object.

For an in-depth discussion, refer to the Apache Server Configuration Customization in Perl chapter.

=head2 pnotes()

Share Perl variables between Perl HTTP handlers.

	 # to share variables by value and not reference, $val should be a lexical.
	 $old_val  = $r->pnotes( $key => $val );
	 $val      = $r->pnotes( $key );
	 $hash_ref = $r->pnotes();

Note: sharing variables really means it. The variable is not copied.  Only its reference count is incremented. If it is changed after being put in pnotes that change also affects the stored value. The following example illustrates the effect:

	 my $v=1;                     my $v=1;
	 $r->pnotes( 'v'=>$v );       $r->pnotes->{v}=$v;
	 $v++;                        $v++;
	 my $x=$r->pnotes('v');       my $x=$r->pnotes->{v};
	 
=head2 pool()

Returns the pool associated with the request as a L<APR::Pool> object.

=head2 preferred_language( array ref )

Given an array reference of supported languages, this method will get the client accepted languages and derived the best match, ie the client preferred language.

It returns a string representing a language code.

=head2 prev()

Pointer to the previous request if this is an internal redirect.

Returns a L<Apache2::RequestRec> blessed reference to the previous (internal) request structure or "undef" if there is no previous request.

=head2 protocol()

Get a string identifying the protocol that the client speaks, such as C<HTTP/1.0> or C<HTTP/1.1>

=head2 proxyreq()

Get/set the proxyrec request record member and optionally adjust other related fields.

Valid values are: PROXYREQ_NONE, PROXYREQ_PROXY, PROXYREQ_REVERSE, PROXYREQ_RESPONSE

According to the L<Apache2::RequestRec> documentation:

For example to turn a normal request into a proxy request to be handled on the same server in the "PerlTransHandler" phase run:

	 my $real_url = $r->unparsed_uri;
	 $r->proxyreq(Apache2::Const::PROXYREQ_PROXY);
	 $r->uri($real_url);
	 $r->filename("proxy:$real_url");
	 $r->handler('proxy-server');

Also remember that if you want to turn a proxy request into a non-proxy request, it's not enough to call:

	 $r->proxyreq(Apache2::Const::PROXYREQ_NONE);

You need to adjust "$r->uri" and "$r->filename" as well if you run that code in "PerlPostReadRequestHandler" phase, since if you don't -- "mod_proxy"'s own post_read_request handler will override your settings (as it will run after the mod_perl handler).

And you may also want to add

	 $r->set_handlers(PerlResponseHandler => []);

so that any response handlers which match apache directives will not run in addition to the mod_proxy content handler.

=head2 push_handlers( name => code reference )

Add one or more handlers to a list of handlers to be called for a given phase.

	 $ok = $r->push_handlers($hook_name => \&handler);
	 $ok = $r->push_handlers($hook_name => ['Foo::Bar::handler', \&handler2]);

It returns a true value on success, otherwise a false value

Examples:

A single handler:

	 $r->push_handlers(PerlResponseHandler => \&handler);

Multiple handlers:

	 $r->push_handlers(PerlFixupHandler => ['Foo::Bar::handler', \&handler2]);

Anonymous functions:

	 $r->push_handlers(PerlLogHandler => sub { return Apache2::Const::OK });

See L<Apache::RequestUtil> for more information.

=head2 query()

Check the query string sent in the http request, which obviously should be a GET, but not necessarily, and parse it with L<URI::Query> and return a hash reference.

=head2 query_string( query string )

Actually calls B<args> from L<Apache2::RequestRec> behind the scene.

This get/set the request QUERY string.

=head2 read()

Read data from the client and returns the number of characters actually read.

	 $cnt = $r->read($buffer, $len);
	 $cnt = $r->read($buffer, $len, $offset);

This method shares a lot of similarities with the Perl core C<read()> function. The main difference in the error handling, which is done via L<APR::Error> exceptions

See L<Apache2::RequestIO> for more information.

=head2 referer()

Returns the value of the Referer http header, if any.

=head2 remote_addr()

Returns the remote host socket address

This checks which version of Apache is running, because the Apache2 mod_perl api has changed.

=head2 remote_host()

Returns the remote client host name.

=head2 remote_ip()

Returns the ip address of the client, ie remote host making the request.

It returns a string representing an ip address,

=head2 reply( code integer, hash reference )

This method is used to return a json reply back to the client.

It takes a http constant integer value representing the http status code and a hash reference containing the C<message> property with a string to be sent.

It will convert the perl hash into a json string and return it to the client after setting the http response code.

This method is actually discouraged in favour of the equivalent one B<reply> in L<Net::API::REST>, which is more powerful and versatile.

=head2 request()

Returns the embedded L<Apache2::RequestRec> object provided initially at object initiation.

=head2 request_time()

Time when the request started in second since epoch.

=head2 server()

Get the L<Apache2::ServerRec> object for the server the request $r is running under.

=head2 server_admin()

Returns the server admin as provided by L<Apache2::ServerRec>

=head2 server_hostname()

Returns the server host name as provided by L<Apache2::ServerRec>

=head2 server_name()

Get the current request's server name

See L<Apache2::RequestUtil> for more information.

=head2 server_port()

Get the current server port

See L<Apache2::RequestUtil> for more information.

=head2 server_version

=head2 set_basic_credentials( user_name, password )

Populate the incoming request headers table ("headers_in") with authentication headers for Basic Authorization as if the client has submitted those in first place:

	$r->set_basic_credentials( $username, $password );

See L<Apache2::RequestUtil> for more information.

=head2 set_handlers()

Set a list of handlers to be called for a given phase. Any previously set handlers are forgotten.

See L<Apache2::RequestUtil> for more information.

	 $ok = $r->set_handlers($hook_name => \&handler);
	 $ok = $r->set_handlers($hook_name => ['Foo::Bar::handler', \&handler2]);
	 $ok = $r->set_handlers($hook_name => []);
	 $ok = $r->set_handlers($hook_name => undef);

=head2 slurp_filename()

Slurp the contents of C<$req->filename>:

This returns a scalar reference instead of the actual string. To get the string, use B<content>

Note that if you assign to "$req->filename" you need to update its stat record.

=head2 socket()

Get/set the client socket and returns a L<APR::Socket> object.

This calls the B<client_socket> method of the L<Apache2::Connection> package.

=head2 status( [ integer ] )

Get/set the reply status for the client request.

Normally you would use some L<Apache2::Const> constant, e.g. L<Apache2::Const::REDIRECT>.

From the L<Apache2::RequestRec> documentation:

Usually you will set this value indirectly by returning the status code as the handler's function result. However, there are rare instances when you want to trick Apache into thinking that the module returned an C<Apache2::Const:OK> status code, but actually send the browser a non-OK status. This may come handy when implementing an HTTP proxy handler. The proxy handler needs to send to the client, whatever status code the proxied server has returned, while returning L<Apache2::Const::OK> to Apache. e.g.:

         $r->status( $some_code );
         return( Apache2::Const::OK );

See also C<$r->status_line>, which. if set, overrides C<$r->status>.

=head2 status_line( string )

Get/set the response status line. The status line is a string like C<200 Document follows> and it will take precedence over the value specified using the C<$r->status()> described above.

According to the L<Apache2::RequestRec> documentation:

When discussing C<$r->status> we have mentioned that sometimes a handler runs to a successful completion, but may need to return a different code, which is the case with the proxy server. Assuming that the proxy handler forwards to the client whatever response the proxied server has sent, it'll usually use C<status_line()>, like so:

	 $r->status_line( $response->code() . ' ' . $response->message() );
	 return( Apache2::Const::OK );

In this example $response could be for example an "HTTP::Response" object, if "LWP::UserAgent" was used to implement the proxy.

This method is also handy when you extend the HTTP protocol and add new response codes. For example you could invent a new error code and tell Apache to use that in the response like so:

	 $r->status_line( "499 We have been FooBared" );
	 return( Apache2::Const::OK );

Here 499 is the new response code, and We have been FooBared is the custom response message.

=head2 subprocess_env()

Get/set the Apache C<subprocess_env> table, or optionally set the value of a named entry.

From the L<Apache2::RequestRec> documentation:

When called in VOID context with no arguments, it populate %ENV with special variables (e.g. $ENV{QUERY_STRING}) like mod_cgi does.

When called in a non-VOID context with no arguments, it returns an "APR::Table object".

When the $key argument (string) is passed, it returns the corresponding value (if such exists, or "undef". The following two lines are equivalent:

	 $val = $r->subprocess_env($key);
	 $val = $r->subprocess_env->get($key);

When the $key and the $val arguments (strings) are passed, the value is set. The following two lines are equivalent:

	 $r->subprocess_env($key => $val);
	 $r->subprocess_env->set($key => $val);

The "subprocess_env" "table" is used by "Apache2::SubProcess", to pass environment variables to externally spawned processes. It's also used by various Apache modules, and you should use this table to pass the environment variables. For example if in "PerlHeaderParserHandler" you do:

	  $r->subprocess_env(MyLanguage => "de");

you can then deploy "mod_include" and write in .shtml document:

	  <!--#if expr="$MyLanguage = en" -->
	  English
	  <!--#elif expr="$MyLanguage = de" -->
	  Deutsch
	  <!--#else -->
	  Sorry
	  <!--#endif -->

=head2 the_request()

Get or set the first HTTP request header as a string. For example:

	GET /foo/bar/my_path_info?args=3 HTTP/1.0

=head2 type()

Returns the content type of the request received. This value is set at object initiation phase.

=head2 unparsed_uri()

The URI without any parsing performed.

If for example the request was:

	 GET /foo/bar/my_path_info?args=3 HTTP/1.0

"$r->uri" returns:

	 /foo/bar/my_path_info

whereas "$r->unparsed_uri" returns:

	 /foo/bar/my_path_info?args=3

=head2 uri()

Returns a C<URI> object representing the full uri of the request.

This is different from the original L<Apache2::RequestRec> which only returns the path portion of the URI.

So, to get the path portion using our B<uri> method, one would simply do C<$req->uri->path()>

=head2 user()

Get the user name, if an authentication process was successful. Or set it.

For example, let's print the username passed by the client:

	 my( $res, $sent_pw ) = $req->get_basic_auth_pw;
	 return( $res ) if( $res != Apache2::Const::OK );
	 print( "User: ", $r->user );

=head2 user_agent()

Returns the user agent, ie the browser signature as provided in the request headers received under the http header C<User-Agent>

=head2 variables()

When parsing the endpoint sought by the client request, there may be some variable such as:

	/org/jp/llc/12/directors/23/profile

In this case, llc has an id value of 12 and the director an id value of 23. They will be recorded as variables as instructed by the route map set by the package using L<Net::API::REST>

Note that this is actually not used anymore and superseded by the L<Net::API::REST::Endpoint> package.

=head2 _find_bin( string )

Given a binary, this will search for it in the path.

=head2 _split_str( string, [ separator ] )

Given a string and an optional separator, which revert to C<;> by default, this helper method will split the string.

This splitting can be tricky because the separator value itself may be enclosed in the string and surrounded by parenthesis.

=head2 _try( object type, method name, @_ )

Given an object type, a method name and optional parameters, this attempts to call it.

Apache2 methods are designed to die upon error, whereas our model is based on returning C<undef> and setting an exception with L<Module::Generic::Exception>, because we believe that only the main program should be in control of the flow and decide whether to interrupt abruptly the execution, not some sub routines.

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
