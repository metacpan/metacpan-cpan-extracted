package Prancer::Session::State::Cookie;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.05';

use Plack::Session::State::Cookie;
use parent qw(Plack::Session::State::Cookie);

1;

=head1 NAME

Prancer::Session::State::Cookie

=head1 SYNOPSIS

This package implements a session state handler that will keep track of
sessions by adding a cookie into the response headers and reading cookies in
the request headers. You must enable this if you want sessions to work.

To use this session state handler, add this to your configuration file:

    session:
        state:
            driver: Prancer::Session::State::Cookie
            options:
                key: PSESSION
                path: /
                domain: .example.com
                expires: 1800
                secure: 1
                httponly: 1

=head1 OPTIONS

=over 4

=item key

The name of the cookie. The default is B<PSESSION>.

=item path

The path of the cookie. This defaults to "/".

=item domain

The domain for the cookie. If this is not set then it will not be included in
the cookie.

=item expires

The expiration time of the cookie in seconds. If this is not set then it will
not be included in the cookie which means that sessions will expire at the end
of the user's browser session.

=item secure

The secure flag for the cookie. If this is not set then it will not be included
in the cookie. If this is set to a true value then the cookie will only be
transmitted over secure connections.

=item httponly

The HttpOnly flag for the cookie. If this is not set then it will not be
included in the cookie. If this is set to a true value then the cookie will
only be accessible by the server and not by, say, JavaScript.

=back

=cut
