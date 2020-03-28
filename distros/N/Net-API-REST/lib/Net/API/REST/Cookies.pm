# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Cookies.pm
## Version 0.2.4
## Copyright(c) 2019- DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/10/08
## Modified 2019/12/15
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Cookies;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
	use APR::Pool ();
	use APR::Request::Cookie;
	use APR::Request::Apache2;
	use TryCatch;
	use Cookie::Baker ();
	use Scalar::Util;
	our $VERSION = '0.2.4';
};

sub init
{
	my $self = shift( @_ );
	my $req;
	$req = shift( @_ ) if( @_ && ( @_ % 2 ) );
	$self->SUPER::init( @_ );
	$self->{request} = $req if( $req );
	return( $self->error( "No Net::API::REST::Request object was provided." ) ) if( !$self->{request} );
	$self->{_cookies} = {};
	return( $self );
}

sub delete
{
	my $self = shift( @_ );
	my $name = shift( @_ );
	return if( !CORE::length( $name ) );
	my $ref = $self->{_cookies};
	return if( !CORE::exists( $ref->{ $name } ) );
	## Remove cookie and return the previous entry
	return( CORE::delete( $ref->{ $name } ) );
}

sub exists
{
	my $self = shift( @_ );
	my $name = shift( @_ );
	return( $self->error( "No cookie name was provided to check if it exists." ) ) if( !CORE::length( $name ) );
	my $ref = $self->{_cookies};
	return( CORE::exists( $ref->{ $name } ) );
}

sub fetch
{
	my $self = shift( @_ );
	my $ref = $self->{_cookies};
	$self->message( 3, "Fetching cookie from Apache headers: ", $self->request->as_string );
	my $cookies = {};
	try
	{
		$self->message( 3, "Getting Apache pool object." );
		my $pool = $self->_request->pool;
		$self->message( 3, "Apache pool object is: '$pool'" );
		$self->message( 3, "Getting an APR Table object instance." );
		# my $o = APR::Request::Apache2->handle( $self->request->pool );
		my $o = APR::Request::Apache2->handle( $self->_request );
		if( $o->jar_status =~ /^(?:Missing input data|Success)$/ )
		{
			$self->message( 3, "Object is '$o'. Returning the jar. Object has method 'jar'? ", ( $o->can( 'jar' ) ? 'yes' : 'no' ) );
			my $j = $o->jar;
			foreach my $cookie_name ( keys( %$j ) )
			{
				$cookies->{ $cookie_name } = $j->{ $cookie_name };
			}
			$self->messagef( 3, "%d cookies found using APR::Request::Apache2.", scalar( keys( %$cookies ) ) );
		}
		else
		{
			$self->message( 3, "Malformed cookie found: ", $o->jar_status );
			my $cookie_header = $self->request->headers( 'Cookie' );
# 			foreach my $cookie ( CORE::split( /\;[[:blank:]]*/, $cookie_header ) )
# 			{
# 				if( CORE::index( $cookie, '=' ) != -1 )
# 				{
# 					my( $c_name, $c_value ) = CORE::split( /[[:blank:]]*=[[:blank:]]*/, $cookie, 2 );
# 					$cookies->{ $c_name } = $c_value;
# 				}
# 				else
# 				{
# 					CORE::warn( "Warning only: unable to find an = sign to split cookie name from its value. Original data is: $cookie\n" );
# 				}
# 			}
		}
	}
	catch( $e )
	{
		$self->message( 3, "An error occurred while trying to get cookies using APR::Request::Apache2, reverting to Cookie::Baker" );
	}
	my $cookie_header = $self->request->headers( 'Cookie' );
	$self->message( 3, "Raw cookie header found is '$cookie_header'" );
	if( !scalar( keys( %$cookies ) ) && $cookie_header )
	{
		$cookies = Cookie::Baker::crush_cookie( $cookie_header );
		$self->messagef( 3, "%d cookies found using Cookie::Baker: %s", scalar( keys( %$cookies ) ), join( ', ', sort( keys( %$cookies ) ) ) );
	}
	## We are called in void context like $jar->fetch which means we fetch the cookies and add them to our stack internally
	if( !defined( wantarray() ) )
	{
		foreach my $cookie_name ( keys( %$cookies ) )
		{
			$ref->{ $cookie_name } = $cookies->{ $cookie_name };
		}
	}
	return( $cookies );
}

sub get { return( shift->{_cookies}->{ $_[0] } ); }

sub make
{
	my $self = shift( @_ );
	my $opts = {};
	$opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
	return( $self->error( "Cookie name was not provided." ) ) if( !$opts->{name} );
	$opts->{request} = $self->request;
	$opts->{debug} = $self->debug;
	$self->message( 3, "Creating cookie with following parameters: ", sub{ $self->dumper( $opts ) } );
	my $c = Net::API::REST::Cookie->new( $opts ) ||
	return( $self->pass_error( Net::API::REST::Cookie->error ) );
	return( $c );
}

sub request { return( shift->_set_get_object( 'request', 'Net::API::REST::Request', @_ ) ); }

sub set
{
	my $self = shift( @_ );
	my( $name, $object ) = @_;
	return( $self->error( "No cookie name was provided to set." ) ) if( !CORE::length( $name ) );
	return( $self->error( "Cookie value should be an object." ) ) if( !Scalar::Util::blessed( $object ) );
	return( $self->error( "Cookie object does not have any as_string method." ) ) if( !$object->can( 'as_string' ) );
	my $ref = $self->{_cookies};
	$ref->{ $name } = $object->value;
	$self->request->err_headers( 'Set-Cookie', $object->as_string );
}

sub _request { return( shift->request->request ); }

package Net::API::REST::Cookie;
BEGIN
{
	use parent qw( Module::Generic );
	use APR::Request ();
	use DateTime;
	use Net::API::REST::DateTime;
	use Scalar::Util ();
	use TryCatch;
	use overload '""' => sub { shift->as_string() }, fallback => 1;
};

sub init
{
	my $self = shift( @_ );
	no overloading;
	$self->{request}	= '';
	$self->{name}		= '';
	$self->{value}		= '';
	$self->{comment}	= '';
	$self->{commentURL}	= '';
	$self->{domain}		= '';
	$self->{expires}	= '';
	$self->{http_only}	= '';
	$self->{max_age}	= '';
	$self->{path}		= '';
	$self->{port}		= '';
	$self->{same_site}	= '';
	$self->{secure}		= '';
	$self->{version}	= '';
	$self->{_init_strict_use_sub} = 1;
	$self->SUPER::init( @_ );
	return( $self->error( "No Net::API::REST::Request object was provided." ) ) if( !$self->{request} );
	return( $self->error( "Net::API::REST::Request value provided is not an object." ) ) if( !Scalar::Util::blessed( $self->{request} ) );
	return( $self->error( "request value provided is not a Net::API::REST::Request object." ) ) if( !$self->{request}->isa( 'Net::API::REST::Request' ) );
	$self->message( 3, "Returning cookie with value: '", $self->as_string, "'." );
	return( $self );
}

# sub as_string { return( shift->APR::Request::Cookie::as_string ); }
## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
sub as_string 
{
	my $self = shift( @_ );
	return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) );
	my $name = $self->name;
	$name = APR::Request::encode( $name ) if( $name =~ m/[^a-zA-Z\-\.\_\~]/ );
	my $value = $self->value;
	## Not necessary to encode, but customary and practical
	if( CORE::length( $value ) )
	{
		my $wrapped_in_double_quotes = 0;
		if( $value =~ /^\"([^\"]+)\"$/ )
		{
			$value = $1;
			$wrapped_in_double_quotes = 1;
		}
		$value = APR::Request::encode( $value );
		$value = sprintf( '"%s"', $value ) if( $wrapped_in_double_quotes );
	}
	my @parts = ( "${name}=${value}" );
	push( @parts, sprintf( 'Domain=%s', $self->domain ) );
	push( @parts, sprintf( 'Port=%d', $self->port ) ) if( $self->port );
	push( @parts, sprintf( 'Path=%s', $self->path ) ) if( $self->path );
	## Could be empty. If not specified, it would be a session cookie
	if( my $t = $self->expires )
	{
		( my $dt_str = "$t" ) =~ s/\bUTC\b/GMT/;
		$self->message( 3, "Setting the expiration timestamp to '$dt_str'." );
		push( @parts, sprintf( 'Expires=%s', $dt_str ) );
	}
	## Number of seconds until the cookie expires
	## A zero or negative number will expire the cookie immediately.
	## If both Expires and Max-Age are set, Max-Age has precedence.
	push( @parts, sprintf( 'Max-Age=%d', $self->max_age ) ) if( CORE::length( $self->max_age ) );
	if( $self->same_site =~ /^(?:lax|strict|none)/i )
	{
		push( @parts, sprintf( 'SameSite=%s', ucfirst( lc( $self->same_site ) ) ) );
	}
	push( @parts, 'Secure' ) if( $self->secure );
	push( @parts, 'HttpOnly' ) if( $self->http_only );
	$self->message( 3, "cookie components are: ", sub{ $self->dumper( \@parts ) });
	my $c = join( '; ', @parts );
	$self->message( 3, "Returning cookie string: '$c'." );
	$self->{_cache_value} = $c;
	CORE::delete( $self->{_reset} );
	return( $c );
}

## A Version 2 cookie, which has been deprecated by protocol
## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub comment { return( shift->_set_get_scalar( 'comment', @_ ) ); }

## A Version 2 cookie, which has been deprecated by protocol
## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub commentURL { return( shift->_set_get_scalar( 'commentURL', @_ ) ); }

sub domain { return( shift->reset->_set_get_scalar( 'domain', @_ ) ); }

# sub expires { return( shift->APR::Request::Cookie::expires( @_ ) ); }
## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
## Example: Fri, 13 Dec 2019 02:27:28 GMT
sub expires
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->reset( @_ );
		my $exp = shift( @_ );
		$self->message( 3, "Received expiration value of '$exp'." );
		my $dt;
		if( $exp =~ /^\d+$/ )
		{
			$self->message( 3, "Value is actually a unix timestamp." );
			try
			{
				$dt = DateTime->from_epoch( epoch => $exp, time_zone => 'local' );
			}
			catch( $e )
			{
				return( $self->error( "An error occurred while setting the cookie expiration date time based on the unix timestamp '$exp'." ) );
			}
		}
		elsif( $exp =~ /^([\+\-]?\d+)([YMDhms])$/ )
		{
			$self->message( 3, "Value is actually a variable time." );
			my $interval =
			{
				's' => 1,
				'm' => 60,
				'h' => 3600,
				'D' => 86400,
				'M' => 86400 * 30,
				'Y' => 86400 * 365,
			};
			my $offset = ( $interval->{$2} || 1 ) * int( $1 );
			my $ts = time() + $offset;
			$dt = DateTime->from_epoch( epoch => $ts, time_zone => 'local' );
		}
		elsif( lc( $exp ) eq 'now' )
		{
			$self->message( 3, "Value is actually a special keyword." );
			$dt = DateTime->now;
		}
		else
		{
			$self->message( 3, "Don't know what to do with '$exp'. Using provided value as is." );
			$dt = "$exp";
		}
		$dt = $self->_header_datetime( $dt ) if( Scalar::Util::blessed( $dt ) && $dt->isa( 'DateTime' ) );
		$self->{expires} = $dt;
	}
	return( $self->{expires} );
}

sub http_only { return( shift->reset->_set_get_scalar( 'http_only', @_ ) ); }

sub httponly { return( shift->reset->http_only( @_ ) ); }

sub is_tainted { return( shift->_set_get_scalar( 'is_tainted', @_ ) ); }

sub max_age { return( shift->reset->_set_get_scalar( 'max_age', @_ ) ); }

sub maxage { return( shift->max_age( @_ ) ); }

# sub name { return( shift->_set_get_scalar( 'name', @_ ) ); }
sub name
{
	my $self = shift( @_ );
	if( @_ )
	{
		$self->reset( @_ );
		my $name = shift( @_ );
		## https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
		if( $name =~ /[\(\)\<\>\@\,\;\:\\\"\/\[\]\?\=\{\}]/ )
		{
			return( $self->error( "A cookie name can only contain US ascii characters. Cooki name provided was '$name'." ) );
		}
		$self->{name} = $name;
	}
	return( $self->{name} );
}

sub path { return( shift->reset->_set_get_scalar( 'path', @_ ) ); }

sub port { return( shift->reset->_set_get_scalar( 'port', @_ ) ); }

sub request { return( shift->_set_get_object( 'request', 'Net::API::REST::Request', @_ ) ) }

sub reset
{
	my $self = shift( @_ );
	$self->{_reset} = scalar( @_ ) if( !CORE::length( $self->{_reset} ) );
	return( $self );
}

sub same_site { return( shift->reset->_set_get_scalar( 'same_site', @_ ) ); }

sub samesite { return( shift->same_site( @_ ) ); }

sub secure { return( shift->reset->_set_get_scalar( 'secure', @_ ) ); }

sub value { return( shift->reset->_set_get_scalar( 'value', @_ ) ); }

## Deprecated. Was a version 2 cookie spec: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub version { return( shift->_set_get_scalar( 'version', @_ ) ); }

sub _header_datetime
{
	my $self = shift( @_ );
	my $dt;
	if( @_ )
	{
		return( $self->error( "Date time provided ($dt) is not an object." ) ) if( !Scalar::Util::blessed( $_[0] ) );
		return( $self->error( "Object provided (", ref( $_[0] ), ") is not a DateTime object." ) ) if( !$_[0]->isa( 'DateTime' ) );
		$dt = shift( @_ );
		$self->message( 3, "Using the DateTime provided to us ($dt)." );
	}
	$self->message( 3, "Generating a new DateTime object." ) if( !defined( $dt ) );
	$dt = DateTime->now if( !defined( $dt ) );
	my $fmt = Net::API::REST::DateTime->new;
	$dt->set_formatter( $fmt );
	$self->message( 3, "Returning datetime object '$dt'." );
	return( $dt );
}

1;

__END__

=encoding utf8

=head1 NAME

Net::API::REST::Cookies - Cookie Jar and cookie management

=head1 SYNOPSIS

	use Net::API::REST::Cookies;
	my $jar = Net::API::REST::Cookies->new( request => $self, debug => $self->debug ) ||
	return( $self->error( "An error occurred while trying to get the cookie jar." ) );
	$jar->fetch;
	if( $jar->exists( 'my-cookie' ) )
	{
		# do something
	}
	# get the cookie
	my $sid = $jar->get( 'my-cookie' );
	# set a new cookie
	$jar->set( 'my-cookie' => $cookie_object );
	# Remove cookie from jar
	$jar->delete( 'my-cookie' );
	
	return( $jar->make({
		name => 'my-cookie',
		domain => 'example.com',
		value => 'sid1234567',
		path => '/',
		expires => '+10D',
		## or alternatively
		maxage => 864000
		## to make it exclusively accessible by regular http request and not ajax
		http_only => 1,
		## should it be used under ssl only?
		secure => 1,
	}) );

=head1 VERSION

    v0.2.4

=head1 DESCRIPTION

This is a module to handle cookies sent from the web browser, and also to create new cookie to be returned by the server to the web browser.

The reason for this module is because Apache2::Cookie does not work well in decoding cookies, and C<Cookie::Baker> C<Set-Cookie> timestamp format is wrong. They use Mon-09-Jan 2020 12:17:30 GMT where it should be, as per rfc 6265 Mon, 09 Jan 2020 12:17:30 GMT

Also C<APR::Request::Cookie> and C<Apache2::Cookie> which is a wrapper around C<APR::Request::Cookie> return a cookie object that returns the value of the cookie upon stringification instead of the full C<Set-Cookie> parameters. Clearly they designed it with a bias leaned toward collecting cookies from the browser.

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<request>

This is a required parameter to be sent with a value set to a C<Net::API::REST::Request> object

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 delete( cookie_name )

Given a cookie name, this will remove it from the cookie jar.

However, this will NOT remove it from the web browser by sending a Set-Cookie header.

It returns the value of the cookie removed.

=head2 exists( cookie_name )

Given a cookie name, this will check if it exists.

=head2 fetch()

Retrieve all possible cookies from the http request received from the web browser.

It returns an hash reference of cookie name => cookie value

=head2 get( cookie_name )

Given a cookie name, this will retrieve its value and return it.

=head2 set( cookie_name, cookie_value )

Given a cookie name, and a cookie object, this adds it or replace the previous one if any.

This will also add the cookie to the outgoing http headers using the C<Set-Cookie> http header.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

https://git.deguest.jp/jack/Net-API-REST

=head1 SEE ALSO

C<Apache2::Cookies>, C<APR::Request::Cookie>, C<Cookie::Baker>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
