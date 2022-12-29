# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Cookies.pm
## Version v0.2.9
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/10/08
## Modified 2022/06/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Cookies;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use APR::Pool ();
    use APR::Request::Cookie;
    use APR::Request::Apache2;
    use Net::API::REST::Cookie;
    use Nice::Try;
    use Cookie::Baker ();
    use Scalar::Util;
    our $VERSION = 'v0.2.9';
};

use strict;
use warnings;

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
#           foreach my $cookie ( CORE::split( /\;[[:blank:]]*/, $cookie_header ) )
#           {
#               if( CORE::index( $cookie, '=' ) != -1 )
#               {
#                   my( $c_name, $c_value ) = CORE::split( /[[:blank:]]*=[[:blank:]]*/, $cookie, 2 );
#                   $cookies->{ $c_name } = $c_value;
#               }
#               else
#               {
#                   CORE::warn( "Warning only: unable to find an = sign to split cookie name from its value. Original data is: $cookie\n" );
#               }
#           }
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

1;
# NOTE: pod
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

    v0.2.9

=head1 DESCRIPTION

This is a module to handle cookies sent from the web browser, and also to create new cookie to be returned by the server to the web browser.

The reason for this module is because Apache2::Cookie does not work well in decoding cookies, and L<Cookie::Baker> C<Set-Cookie> timestamp format is wrong. They use Mon-09-Jan 2020 12:17:30 GMT where it should be, as per rfc 6265 Mon, 09 Jan 2020 12:17:30 GMT

Also L<APR::Request::Cookie> and L<Apache2::Cookie> which is a wrapper around L<APR::Request::Cookie> return a cookie object that returns the value of the cookie upon stringification instead of the full C<Set-Cookie> parameters. Clearly they designed it with a bias leaned toward collecting cookies from the browser.

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<request>

This is a required parameter to be sent with a value set to a L<Net::API::REST::Request> object

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

=head2 make

Provided with some parameters and this will instantiate a new L<Net::API::REST::Cookie> object with those parameters and return the new object.

=head2 set( cookie_name, cookie_value )

Given a cookie name, and a cookie object, this adds it or replace the previous one if any.

This will also add the cookie to the outgoing http headers using the C<Set-Cookie> http header.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

https://gitlab.com/jackdeguest/Net-API-REST

=head1 SEE ALSO

L<Apache2::Cookies>, L<APR::Request::Cookie>, L<Cookie::Baker>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
