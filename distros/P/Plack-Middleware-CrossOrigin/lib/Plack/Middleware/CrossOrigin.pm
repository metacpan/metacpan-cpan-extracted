package Plack::Middleware::CrossOrigin;
use strict;
use warnings;

our $VERSION = '0.014';
$VERSION =~ tr/_//d;

use 5.008;
use parent qw(Plack::Middleware);

use Plack::Util;
use Plack::Util::Accessor qw(
    origins
    headers
    methods
    max_age
    expose_headers
    credentials
    continue_on_failure
);

my @simple_headers = qw(
    Accept
    Accept-Language
    Content-Language
);
my @simple_response_headers = qw(
    Cache-Control
    Content-Language
    Content-Type
    Expires
    Last-Modified
    Pragma
);
my @common_headers = qw(
    Cache-Control
    Depth
    If-Modified-Since
    User-Agent
    X-File-Name
    X-File-Size
    X-Requested-With
    X-Prototype-Version
);

# RFC 7231
my @http_methods = qw(
    GET
    HEAD
    POST
    PUT
    DELETE
    CONNECT
    OPTIONS
    TRACE
);

# RFC 5789
my @rfc_5789_methods = qw(
    PATCH
);

my @webdav_methods = qw(
    CANCELUPLOAD
    CHECKIN
    CHECKOUT
    COPY
    DELETE
    GETLIB
    LOCK
    MKCOL
    MOVE
    OPTIONS
    PROPFIND
    PROPPATCH
    PUT
    REPORT
    UNCHECKOUT
    UNLOCK
    UPDATE
    VERSION-CONTROL
);

my @all_methods = ( @http_methods, @rfc_5789_methods, @webdav_methods );

sub prepare_app {
    my ($self) = @_;

    $self->origins([$self->origins || ()])
        unless ref $self->origins;

    $self->methods([$self->methods || @all_methods])
        unless ref $self->methods;

    $self->headers([$self->headers || @common_headers])
        unless ref $self->headers;

    $self->expose_headers([$self->expose_headers || ()])
        unless ref $self->expose_headers;

    $self->{origins_h} = { map { $_ => 1 } @{ $self->origins } };
    ($self->{origins_re}) =
        map qr/\A(?:$_)\z/,
        join '|',
        map +(
            join '[a-z0-9.-]*',
            map quotemeta,
            split /\*/, $_, -1
        ),
        @{ $self->origins };

    $self->{methods_h} = { map { $_ => 1 } @{ $self->methods } };
    $self->{headers_h} = { map { lc $_ => 1 } @{ $self->headers } };
    $self->{expose_headers_h} = { map { $_ => 1 } @{ $self->expose_headers } };
}

sub call {
    my ($self, $env) = @_;
    my $origin = $env->{HTTP_ORIGIN};
    my $continue_on_failure;
    if ($origin) {
        $continue_on_failure = $self->continue_on_failure;
    }
    # for preflighted GET requests, some WebKit versions don't
    # include Origin with the actual request.  Fixed in current versions
    # of WebKit, Chrome, and Safari.
    # Work around it using the Referer header.
    # https://bugs.webkit.org/show_bug.cgi?id=50773
    # http://code.google.com/p/chromium/issues/detail?id=57836
    elsif ($env->{REQUEST_METHOD} eq 'GET'
        && $env->{HTTP_USER_AGENT}
        && $env->{HTTP_USER_AGENT} =~ m{\bAppleWebKit/(\d+\.\d+)}
        && $1 < 534.19
        && $env->{HTTP_REFERER}
        && $env->{HTTP_REFERER} =~ m{\A ( \w+://[^/]+ )}msx
    ) {
        $origin = $1;
        $continue_on_failure = 1;
    }
    else {
        return _with_vary($self->app->($env));
    }

    my $request_method  = $env->{HTTP_ACCESS_CONTROL_REQUEST_METHOD};
    my $request_headers = $env->{HTTP_ACCESS_CONTROL_REQUEST_HEADERS};
    my @request_headers = $request_headers ? (split /,\s*/, $request_headers) : ();
    my $preflight       = $env->{REQUEST_METHOD} eq 'OPTIONS' && $request_method;

    my $fail = $continue_on_failure && !$preflight ? $self->app : \&_response_forbidden;

    my $allowed_origins_h   = $self->{origins_h};
    my $allowed_methods     = $self->methods;
    my $allowed_methods_h   = $self->{methods_h};
    my $allowed_headers     = $self->headers;
    my $allowed_headers_h   = $self->{headers_h};
    my $expose_headers      = $self->expose_headers;
    my $expose_headers_h    = $self->{expose_headers_h};

    my @headers;

    if (not ($allowed_origins_h->{'*'} || $origin =~ $self->{origins_re} ) ) {
        return _with_vary($fail->($env));
    }

    if ($preflight) {
        if ( $allowed_methods_h->{'*'} ) {
            $allowed_methods = [$request_method];
        }
        elsif ( ! $allowed_methods_h->{$request_method} ) {
            return _response_forbidden();
        }
        if ( $allowed_headers_h->{'*'} ) {
            $allowed_headers = \@request_headers;
        }
        elsif ( grep { ! defined } @{$allowed_headers_h}{map lc, @request_headers} ) {
            return _response_forbidden();
        }
    }
    if ($self->credentials) {
        push @headers, 'Access-Control-Allow-Credentials' => 'true';
    }
    elsif ($allowed_origins_h->{'*'}) {
        $origin = '*';
    }
    push @headers, 'Access-Control-Allow-Origin' => $origin;

    my $res;
    if ($preflight) {
        if (defined $self->max_age) {
            push @headers, 'Access-Control-Max-Age' => $self->max_age;
        }
        push @headers, 'Access-Control-Allow-Methods' => join ', ', @$allowed_methods;
        push @headers, 'Access-Control-Allow-Headers' => join ', ', @$allowed_headers;

        $res = _response_success();
    }
    else {
        $res = $self->app->($env);
    }

    return $self->response_cb($res, sub {
        my $res = shift;

        if (! _vary_headers($res->[1])->{origin}) {
            push @{ $res->[1] }, 'Vary' => 'Origin';
        }

        if ($expose_headers_h->{'*'}) {
            my %headers = @{ $res->[1] };
            delete @headers{@simple_response_headers};
            $expose_headers = [sort keys %headers];
        }

        push @headers, 'Access-Control-Expose-Headers' => join ', ', @$expose_headers;

        push @{ $res->[1] }, @headers;
    });
}

sub _response_forbidden {
    [403, ['Content-Type' => 'text/plain', 'Content-Length' => 9, 'Vary' => 'Origin'], ['forbidden']];
}

sub _response_success {
    [200, [ 'Content-Type' => 'text/plain' ], [] ];
}

sub _with_vary {
    my ($res) = @_;
    return Plack::Util::response_cb($res, sub {
        my $res = shift;

        if (! _vary_headers($res->[1])->{origin}) {
            push @{ $res->[1] }, 'Vary' => 'Origin';
        }
    });
}

sub _vary_headers {
    my ($headers) = @_;

    my %vary =
        map { s/\A\s+//; s/\s+\z//; ( lc, 1) }
        map +(split /,/),
        Plack::Util::header_get($headers, 'Vary');

    return \%vary;
}

1;
__END__

=head1 NAME

Plack::Middleware::CrossOrigin - Adds headers to allow Cross-Origin Resource Sharing

=head1 SYNOPSIS

    # Allow any WebDAV or standard HTTP request from any location.
    builder {
        enable 'CrossOrigin', origins => '*';
        $app;
    };

    # Allow GET and POST requests from any location, cache results for 30 days.
    builder {
        enable 'CrossOrigin',
            origins => '*', methods => ['GET', 'POST'], max_age => 60*60*24*30;
        $app;
    };

=head1 DESCRIPTION

Adds Cross Origin Request Sharing headers used by modern browsers
to allow C<XMLHttpRequest> to work across domains.  This module
will also help protect against CSRF attacks in some browsers.

This module attempts to fully conform to the CORS spec, while
allowing additional flexibility in the values specified for the of
the headers.

The module also ensures that the response contains a C<Vary: Origin>
header to avoid potential issues with caches.

=head1 CORS REQUESTS IN BRIEF

There are two types of CORS requests.  Simple requests, and preflighted
requests.

=head2 Simple Requests

A simple request is one that could be generated by a standard HTML
form.  Either a C<GET> or C<POST> request, with no additional
headers.  For these requests, the server processes the request as
normal, and attaches the correct CORS headers in the response.  The
browser then decides based on those headers whether to allow the
client script access to the response.

=head2 Preflighted Requests

If additional headers are specified, or a method other than C<GET>
or C<POST> is used, the request must be preflighted.  This means
that the browser will first send a special request to the server
to check if access is allowed.  If the server allows it by responding
with the correct headers, the actual request is then performed.

=head1 CSRF Protection

Some browsers will also provide same headers with cross domain
C<POST> requests from HTML forms.  These requests will also be
checked against the allowed origins and rejected before they reach
the rest of your Plack application.

=head1 CONFIGURATION

=over 8

=item origins

A list of allowed origins.  Origins should be formatted as a URL
scheme and host, with no path information. (C<http://www.example.com>)
'C<*>' can be specified to allow access from any location.  Wildcards
(C<*>) can also be included in in the host to match any part of a host name
(e.g. C<https://*.example.com>).  At least one origin must bust be specified
for this middleware to have any effect.  This will be matched against the
C<Origin> request header, and will control the C<Access-Control-Allow-Origin>
response header.  If the origin does not match, the request is aborted.

=item headers

A list of allowed request headers.  'C<*>' can be specified to allow
any headers.  Controls the C<Access-Control-Allow-Headers> response
header.  Includes a set of headers by default to simplify working
with WebDAV and AJAX frameworks:

=over 4

=item * C<Cache-Control>

=item * C<Depth>

=item * C<If-Modified-Since>

=item * C<User-Agent>

=item * C<X-File-Name>

=item * C<X-File-Size>

=item * C<X-Prototype-Version>

=item * C<X-Requested-With>

=back

=item methods

A list of allowed methods.  'C<*>' can be specified to allow any
methods.  Controls the C<Access-Control-Allow-Methods> response
header.  Defaults to all of the standard HTTP and WebDAV methods.

=item max_age

The max length in seconds to cache the response data for.  Controls
the C<Access-Control-Max-Age> response header.  If not specified,
the web browser will decide how long to use.

=item expose_headers

A list of allowed headers to expose to the client. 'C<*>' can be
specified to allow the browser to see all of the response headers.
Controls the C<Access-Control-Expose-Headers> response header.

=item credentials

Whether the resource will be allowed with user credentials (cookies,
HTTP authentication, and client-side SSL certificates) supplied.
Controls the C<Access-Control-Allow-Credentials> response header.

=item continue_on_failure

Normally, simple requests with an Origin that hasn't been allowed
will be stopped before they continue to the main app.  If this
option is set, the request will be allowed to continue, but no CORS
headers will be added to the response.  This matches how non-allowed
requests would be handled if this module was not used at all.

This disables the CSRF protection and is not recommended.  It could
be needed for applications that need to allow cross-origin HTML
form C<POST>s without whitelisting domains.

=back

=head1 BROWSER SUPPORT

Different browsers have different levels of support for CORS headers.

=over 8

=item Gecko (Firefox, Seamonkey)

Initially supported in Gecko 1.9.1 (Firefox 3.5).  Supports the
complete CORS spec for C<XMLHttpRequest>s.

Does not yet provide the C<Origin> header for CSRF protection
(L<Bugzilla #446344|https://bugzilla.mozilla.org/show_bug.cgi?id=446344>).

=item WebKit (Safari, Google Chrome)

Initially supported in Safari 4 and Chrome 3. Supports the complete
CORS spec.

The C<expose_headers> feature has been supported since WebKit v535.18
(Safari 6, Chrome 18). Preflighted requests were buggy prior to
WebKit v534.19 (Safari 5.1, Chrome 11), but this module uses a
workaround where possible (using the C<Referer> header).

Also provides the C<Origin> header for CSRF protection starting
with WebKit v528.5 (Chrome 2, Safari 4).

=item Internet Explorer

Initially supported in IE8.  Not supported with the standard
C<XMLHttpRequest> object.  A separate object, C<XDomainRequest>,
must be used.  Only C<GET> and C<POST> methods are allowed.  No
extra headers can be added to the request.  Neither the status code
or any headers aside from C<Content-Type> can be retrieved from the
response.

IE10 supports CORS via the standard C<XMLHttpRequest> object.

=item Opera

Opera and Opera Mobile support CORS since version 12.

=back

=head1 SEE ALSO

=head2 CORS Resources

=over 4

=item * L<W3C Spec for Cross-Origin Resource Sharing|http://www.w3.org/TR/cors/>

=item * L<W3C Spec for Cross-Origin Resource Sharing - Implementation Considerations|http://www.w3.org/TR/cors/#resource-implementation>

=item * L<Mozilla Developer Center - HTTP Access Control|https://developer.mozilla.org/En/HTTP_access_control>

=item * L<Mozilla Developer Center - Server-Side Access Control|https://developer.mozilla.org/En/Server-Side_Access_Control>

=item * L<Cross browser examples of using CORS requests|http://www.nczonline.net/blog/2010/05/25/cross-domain-ajax-with-cross-origin-resource-sharing/>

=item * L<MSDN - XDomainRequest Object|http://msdn.microsoft.com/en-us/library/cc288060%28v=vs.85%29.aspx>

=item * L<XDomainRequest - Restrictions, Limitations and Workarounds|http://blogs.msdn.com/b/ieinternals/archive/2010/05/13/xdomainrequest-restrictions-limitations-and-workarounds.aspx>

=item * L<Wikipedia - Cross-Origin Resource Sharing|http://en.wikipedia.org/wiki/Cross-Origin_Resource_Sharing>

=item * L<CORS advocacy|http://enable-cors.org/>

=back

=head2 CSRF Resources

=over 4

=item * L<Wikipedia - Cross-site request forgery|http://en.wikipedia.org/wiki/Cross-site_request_forgery>

=item * L<Stanford Web Security Research - Cross-Site Request Forgery|http://seclab.stanford.edu/websec/csrf/>

=item * L<WebKit Bugzilla - Add origin header to POST requests|https://bugs.webkit.org/show_bug.cgi?id=20792>

=item * L<Mozilla Bugzilla - Implement Origin header CSRF mitigation|https://bugzilla.mozilla.org/show_bug.cgi?id=446344>

=back

=head2 Related Technologies

=over 4

=item * L<Cross-domain policy file for Flash|http://www.adobe.com/devnet/articles/crossdomain_policy_file_spec.html>

=item * L<Wikipedia - JSONP|http://en.wikipedia.org/wiki/JSONP>

=back

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2011 the Plack::Middleware::CrossOrigin L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
