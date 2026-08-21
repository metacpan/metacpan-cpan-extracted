package Punk::CORS;

use 5.010;
use strict;
use warnings;
use Punk (); 

our $VERSION = '0.27';

sub _chain {
    my ($future, $cfg, $allow) = @_;
    return $future->then(sub {
        my ($resp) = @_;
        _decorate($resp, $cfg, $allow);   # a plain return settles the chain
        return $resp;
    });
}

1;

__END__

=head1 NAME

Punk::CORS - cross-origin resource sharing

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    cors;                                    # a public API: * , no credentials

    cors origins     => [ 'https://app.example.com' ],
         credentials => 1,
         headers     => [qw(Content-Type X-CSRF-Token)],
         expose      => [qw(X-Request-Id)],
         max_age     => 600,
         paths       => [ '/api' ];

=head1 DESCRIPTION

Answers preflights and adds the cross-origin headers, from inside the C
dispatcher.

Both halves happen where they have to. A preflight is answered B<before
routing>, because C<OPTIONS> on a path with no C<OPTIONS> route would
otherwise be the router's C<405>. Responses are decorated on the way out
of the dispatcher rather than in an after-dispatch hook, because C<404>
and C<405> never build a context and would otherwise go out bare - which
is exactly when a browser most needs to be told it may read the status.

=head2 What it is not

CORS is not access control. It tells a B<browser> what script on another
origin may read; nothing else honours it, and curl has never cared. An
endpoint that must not be reached by a given caller needs a guard, not a
header.

In particular it is not a replacement for L<Punk::CSRF>. A credentialed
cross-origin C<POST> that CORS permits still has to carry a live token.
The two answer different questions - "may this script read the reply"
and "did this request come from our own page" - and an application that
takes cookies wants both.

=head1 THE KEYWORD

=over 4

=item * C<origins> - C<'*'>, a single origin, an arrayref of exact origins,
or a coderef called with the request's origin. The coderef may return true
(echo the origin) or a replacement origin. Default C<'*'>.

=item * C<credentials> - send C<Access-Control-Allow-Credentials: true>.
B<Requires explicit origins>: browsers refuse credentials with C<'*'>, and
reflecting whatever origin arrives while allowing credentials is the classic
CORS hole - every site gets to read your users' authenticated responses. The
keyword croaks at C<to_app> rather than let it be written.

=item * C<headers> - the C<Access-Control-Allow-Headers> list for preflights.
Omitted, the requested headers are echoed.

=item * C<expose> - response headers script may read beyond the safelisted
ones.

=item * C<max_age> - how long a preflight may be cached, in seconds
(default 600).

=item * C<paths> - path prefixes CORS applies to. C<< paths => ['/api'] >>
is how an application serves HTML same-origin and its API cross-origin.

=item * C<methods> - override the preflight's method list. See below for why
you probably should not.

=back

C<cors 0> turns it off. It also reads a C<cors:> block from
F<config/punk.yml>.

=head2 Allow-Methods comes from the router

A preflight is answered with the methods that B<path> actually serves,
taken from the same routing table that produces C<Allow> on a C<405> - so
it includes API operations and can never promise a method the application
does not have. A preflight for a method the path does not answer is
refused with C<403> rather than waved through to fail later.

C<methods> overrides this for the case the router cannot see: a mounted
PSGI application whose own routes are opaque to Punk.

=head2 Vary

C<Vary: Origin> goes on every response whose C<Allow-Origin> depends on the
request's origin - anything but a flat C<'*'>. Without it a shared cache
will happily serve one origin's response to another, which is a
cache-poisoning bug wearing a CORS costume.

=head1 SEE ALSO

L<Punk>, L<Punk::CSRF>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
