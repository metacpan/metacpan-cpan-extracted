##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Cookie.pm
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
package Net::API::REST::Cookie;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Cookie );
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

    v1.0.0

=head1 DESCRIPTION

This module represents a cookie. This can be used as a standalone module, or can be managed as part of the cookie jar L<Cookie::Jar>

This module inherits all of its methods from L<Cookie>. Please check its documentation directly.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie>, L<Cookie::Jar>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
