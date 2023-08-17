# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Cookies.pm
## Version v1.0.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/10/08
## Modified 2023/06/10
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
    use parent qw( Cookie::Jar );
    use vars qw( $VERSION );
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

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

    v1.0.0

=head1 DESCRIPTION

This is a module to handle cookies sent from the web browser, and also to create new cookie to be returned by the server to the web browser.

As of version C<1.0.0>, this module inherits all of its methods from L<Cookie::Jar>. Please check its documentation directly.

The reason for this module is because Apache2::Cookie does not work well in decoding cookies, and L<Cookie::Baker> C<Set-Cookie> timestamp format is wrong. They use Mon-09-Jan 2020 12:17:30 GMT where it should be, as per rfc 6265 Mon, 09 Jan 2020 12:17:30 GMT

Also L<APR::Request::Cookie> and L<Apache2::Cookie> which is a wrapper around L<APR::Request::Cookie> return a cookie object that returns the value of the cookie upon stringification instead of the full C<Set-Cookie> parameters. Clearly they designed it with a bias leaned toward collecting cookies from the browser.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie::Jar>, L<Cookie>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
