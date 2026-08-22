package Punk::Headers;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

sub _chain {
    my ($future, $pairs) = @_;
    return $future->then(sub {
        my ($resp) = @_;
        _decorate($resp, $pairs);   # a plain return settles the chain
        return $resp;
    });
}

1;

__END__

=head1 NAME

Punk::Headers - security response headers

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    headers;                       # the safe default set

    headers 'Content-Security-Policy'   => "default-src 'self'",
            'Strict-Transport-Security' => 'max-age=31536000',
            'X-Frame-Options'           => 'DENY';

    headers 'X-Frame-Options' => undef;   # keep the rest, drop this one

=head1 DESCRIPTION

Adds a frozen set of response headers to everything the application sends,
from inside the C dispatcher.

The decoration happens on the way out of the dispatcher rather than in an
after-dispatch hook, for the reason L<Punk::CORS> gives: C<404> and C<405>
never build a context, and a browser reads a Content-Security-Policy off an
error page exactly as it would off a real one. CORS preflight replies are
covered too.

=head2 Set-if-absent

A header the response already carries wins, case-insensitively. A handler
(or a hook, or CORS) that sets its own C<X-Frame-Options> for one route has
said something more specific than the application-wide policy, and the
policy does not repeat or contradict it.

=head2 The defaults

The bare keyword ships only headers that are safe on any application:

    X-Content-Type-Options: nosniff
    X-Frame-Options: SAMEORIGIN
    Referrer-Policy: strict-origin-when-cross-origin

C<Content-Security-Policy> and C<Strict-Transport-Security> are deliberately
not defaults. A CSP invented by a framework breaks every inline script and
style it has never seen, and HSTS is a commitment to serve HTTPS for as long
as its C<max-age> promises - months, on any value worth sending. Both belong
to the application, spelled out.

=head1 THE KEYWORD

    headers;                        # the default set
    headers %pairs;                 # defaults, overridden and extended
    headers \%pairs;                # the same, as a hashref
    headers 0;                      # off

Keys are literal header names, values are literal header strings. A value of
C<undef> removes that header from the default set. A reference value croaks
at keyword time. C<headers 0> turns the feature off.

It also reads a C<headers:> block from F<config/punk.yml>; C<headers: true>
is the bare form.

=head1 SCOPED POLICIES

    my $admin = under '/admin' => $guard;
    $admin->headers('X-Frame-Options' => 'DENY',
                    'Referrer-Policy' => undef);

An C<under> scope takes the same pairs and applies them only to requests
under its prefix - ahead of the application-wide policy, so a scope can
tighten a header, add one, or (with C<undef>) drop one for its subtree.
Scopes nest, and the longest prefix wins a name. Because the policy rides
the response path rather than the route, a C<404> under the prefix carries
it too.

Order of precedence for one header name, most specific first: whatever the
response already carries (a handler's own C<< $c->header >>), the
longest-prefix scope that mentions it, then the application-wide policy.

=head1 SEE ALSO

L<Punk>, L<Punk::CORS>, L<Punk::CSRF>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
