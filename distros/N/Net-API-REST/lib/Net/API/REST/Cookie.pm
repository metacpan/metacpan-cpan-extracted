##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Cookie.pm
## Version v0.2.9
## Copyright(c) 2019-2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/10/08
## Modified 2021/09/08
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Cookie;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use APR::Request ();
    use DateTime;
    use Net::API::REST::DateTime;
    use Scalar::Util ();
    use Nice::Try;
    use overload '""' => sub { shift->as_string() }, fallback => 1;
    our $VERSION = 'v0.2.9';
};

sub init
{
    my $self = shift( @_ );
    no overloading;
    $self->{request}    = '';
    $self->{name}       = '';
    $self->{value}      = '';
    $self->{comment}    = '';
    $self->{commentURL} = '';
    $self->{domain}     = '';
    $self->{expires}    = '';
    $self->{http_only}  = '';
    $self->{max_age}    = '';
    $self->{path}       = '';
    $self->{port}       = '';
    $self->{same_site}  = '';
    $self->{secure}     = '';
    $self->{version}    = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self->error( "No Net::API::REST::Request object was provided." ) ) if( !$self->{request} );
    return( $self->error( "Net::API::REST::Request value provided is not an object." ) ) if( !Scalar::Util::blessed( $self->{request} ) );
    return( $self->error( "request value provided is not a Net::API::REST::Request object." ) ) if( !$self->{request}->isa( 'Net::API::REST::Request' ) );
    $self->message( 3, "Returning cookie with value: '", $self->as_string, "'." );
    return( $self );
}

# sub as_string { return( shift->APR::Request::Cookie::as_string ); }
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
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
    push( @parts, sprintf( 'Domain=%s', $self->domain ) ) if( $self->domain );
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

# A Version 2 cookie, which has been deprecated by protocol
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub comment { return( shift->_set_get_scalar( 'comment', @_ ) ); }

# A Version 2 cookie, which has been deprecated by protocol
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
sub commentURL { return( shift->_set_get_scalar( 'commentURL', @_ ) ); }

sub domain { return( shift->reset->_set_get_scalar( 'domain', @_ ) ); }

# sub expires { return( shift->APR::Request::Cookie::expires( @_ ) ); }
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
# Example: Fri, 13 Dec 2019 02:27:28 GMT
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

# Deprecated. Was a version 2 cookie spec: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie2
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

Net::API::REST::Cookie - Cookie Object

=head1 SYNOPSIS

    use Net::API::REST::Cookies;
    my $cookie = Net::API::REST::Cookie->new(
        name => 'my-cookie',
        domain => 'example.com',
        value => 'sid1234567',
        path => '/',
        expires => '+10D',
        # or alternatively
        maxage => 864000
        # to make it exclusively accessible by regular http request and not ajax
        http_only => 1,
        # should it be used under ssl only?
        secure => 1,
        request => $request_obj, # Net::API::REST::Request object
    );

=head1 VERSION

    v0.2.9

=head1 DESCRIPTION

This module represents a cookie. This can be used as a standalone module, or can be managed as part of the cookie jar L<Net::API::REST::Cookies>

The object is overloaded and will call L</as_string> upon stringification.

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<request>

This is a required parameter to be sent with a value set to a L<Net::API::REST::Request> object

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=item I<name>

=item I<value>

=item I<comment>

=item I<commentURL>

=item I<domain>

=item I<expires>

=item I<http_only>

=item I<max_age>

=item I<path>

=item I<port>

=item I<same_site>

=item I<secure>

=item I<version>

=back

=head2 as_string

Returns a string representation of the object.

    my $cookie_string = $cookie->as_string;
    # or
    my $cookie_string = "$cookie";
    my-cookie="sid1234567"; Domain=example.com; Path=/; Expires=Mon, 09 Jan 2020 12:17:30 GMT; Secure; HttpOnly

The returned value is cached so the next time, it simply return the cached version and not re-process it. You can reset it by calling L</reset>.

=head2 comment

    $cookie->comment( 'Some comment' );
    my $comment = $cookie->comment;

Sets or gets the optional comment for this cookie. This was used in version 2 of cookies but has since been deprecated.

=head2 commentURL

    $cookie->commentURL( 'https://example.com/some/where.html' );
    my $comment = $cookie->commentURL;

Sets or gets the optional comment URL for this cookie. This was used in version 2 of cookies but has since been deprecated.

=head2 domain

    $cookie->domain( 'example.com' );
    my $dom = $cookie->domain;

Sets or gets the domain for this cookie.

=head2 expires

Sets or gets the expiration date and time for this cookie.

The value provided can be one of:

=over 4

=item unix timestamp.

For example: C<1631099228>

=item variable time.

For example: C<30s> (30 seconds), C<5m> (5 minutes), C<12h> (12 hours), C<30D> (30 days), C<2M> (2 months), C<1Y> (1 year)

However, this is not sprintf, so you cannot combine them, thus B<you cannot do this>: C<5m1D>

=item C<now>

Special keyword

=item In last resort, the value provided will be used as-is

=back

Ultimately, a L<DateTime> will be derived from those values, or C<undef> will be returned and an error will be set.

The L<DateTime> object will be set with a formatter to allow a stringification that is compliant with rfc6265.

And you can use L</max_age> alternatively.

See also L<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date>

=head2 http_only

Sets or gets the boolean for C<httpOnly>

=head2 httponly

Alias for L</http_only>

=head2 is_tainted

Sets or gets the boolean value

=head2 max_age

Sets or gets the integer value for C<Max-Age>

=head2 maxage

Alias for L</max_age>

=head2 name

Sets or gets the cookie name.

As per the L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie>, a cookie name cannot contain any of the following charadcters:

    \(\)\<\>\@\,\;\:\\\"\/\[\]\?\=\{\}

=head2 path

Sets or gets the path.

=head2 port

Sets or gets the port number.

=head2 reset

Set the reset flag to true, which will force L</as_string> to recompute the string value of the cookie.

=head2 same_site

Sets or gets the boolean value for C<Same-Site>.

See L<rfc 6265|https://datatracker.ietf.org/doc/html/draft-west-first-party-cookies-07> for more information.

=head2 samesite

Alias for L</same_site>.

=head2 secure

Sets or gets the boolean value for C<Secure>.

=head2 value

Sets or gets the value for this cookie.

=head2 version

Sets or gets the cookie version. This was used in version 2 of the cookie standard, but has since been deprecated.

=head2 _header_datetime

Given a L<DateTime> object, or by default will instantiate a new one, and this will set its formatter to L<Net::API::REST::DateTime> to ensure the stringification produces a rfc6265 compliant datetime string.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

https://gitlab.com/jackdeguest/Net-API-REST

=head1 SEE ALSO

L<Apache2::Cookies>, L<APR::Request::Cookie>, L<Cookie::Baker>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
