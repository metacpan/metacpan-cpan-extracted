package Punk::OAuth2::Util;

use 5.024;
use strict;
use warnings;

use Punk::OAuth2;

our $VERSION = '0.03';


1;

__END__

=head1 NAME

Punk::OAuth2::Util - shared helpers for Punk::OAuth2

=head1 SYNOPSIS

	# the functions live in the Punk::OAuth2 namespace, not this one
	my $esc  = Punk::OAuth2::uri_escape('a b&c');       # a%20b%26c
	my $base = Punk::OAuth2::base_url($c, \%config);
	my $path = Punk::OAuth2::same_origin_path($return)
		or return $c->redirect('/');

	my ($ok, $why) = Punk::OAuth2::safe_url($url);
	die "refusing $url: $why" unless $ok;

=head1 DESCRIPTION

The small shared pieces the provider, the authorization server and the
plugin all need: percent-encoding, form bodies, the external base URL,
the SSRF guard, the open-redirect guard, and the seam that lets the
same code run blocking or on an event loop.

They are implemented in XS and installed into the B<C<Punk::OAuth2>>
package, not into this one - this module exists to load them and to be
where they are written down. Nothing is exported.

None of this is public API. It is documented because three of these
functions are security checks, and a security check nobody can read is
one nobody can audit. Treat the interfaces as unstable.

=head1 FUNCTIONS

=head2 uri_escape

	my $encoded = Punk::OAuth2::uri_escape($string);

Percent-encodes everything outside the RFC 3986 unreserved set
(C<A-Z>, C<a-z>, C<0-9>, C<->, C<.>, C<_>, C<~>), using upper-case hex.
Operates on bytes, so encode wide characters to UTF-8 first if that is
what you mean.

Deliberately not C<URI::Escape>: this encodes the unreserved set and
nothing else, with no escape-set argument to get wrong at a call site.

=head2 _form

	my $body = Punk::OAuth2::_form(\%pairs);

Builds an C<application/x-www-form-urlencoded> body from a hashref of
scalars. Keys are sorted, both sides percent-encoded, pairs joined with
C<&>. Undef values are skipped entirely rather than sent empty, which
is how optional token-request fields are left out.

Sorted because a deterministic body is testable; the ordering carries
no meaning.

=head2 same_origin_path

	my $safe = Punk::OAuth2::same_origin_path($path);

The open-redirect guard. Returns C<$path> if it is a same-origin
relative path, otherwise C<undef>. It must:

=over 4

=item *

start with C</>,

=item *

not start with C<//>, which is protocol-relative and would leave the
site,

=item *

contain no C0 control byte (C<\x00> to C<\x1f>) or C<DEL>, which covers
CR and LF forging a response header, and covers TAB, CR and LF being
B<removed> by the browser before it parses the URL - C<"/\tevil.example">
reaching a browser as C<"//evil.example"> is the same open redirect
spelled differently,

=item *

contain no backslash, which a browser treats as C</> under a special
scheme, so C<"/\\evil.example"> is protocol-relative too. A path that
really wants one spells it C<%5C>.

=back

The last two rules are deliberately blunt. The set of bytes a URL parser
drops or folds is not fixed and not the same everywhere, so this does not
try to enumerate it: it refuses the whole class rather than the two
members of it that were known to bite.

This is what a C<?return=> destination is put through before anything
redirects to it. Note it returns the path rather than a boolean, so the
result can be used directly and there is no way to test one value and
redirect to another.

=head2 base_url

	my $base = Punk::OAuth2::base_url($c, \%config);

The externally visible base URL, as C<scheme://host> with no trailing
slash. This is what redirect URIs and issuer identifiers are built
from, so it has to be the URL the browser used and not the one the
socket saw.

A configured C<base_url> in C<%config> wins outright, with one trailing
slash stripped. Otherwise it comes from the request environment:
C<HTTP_X_FORWARDED_PROTO> and C<HTTP_X_FORWARDED_HOST> B<only> when
C<%config> sets C<trust_proxy>, then C<psgi.url_scheme> (defaulting to
C<https>) and C<HTTP_HOST>. The scheme is lower-cased.

The C<trust_proxy> gate is the point of the function. Those headers are
client-supplied unless a proxy is overwriting them, so honouring them
by default would let anyone rewrite the issuer and redirect URIs of a
login by sending a header. Croaks if no host can be determined, rather
than guessing.

=head2 safe_url

	my ($ok, $why) = Punk::OAuth2::safe_url($url);
	my ($ok, $why) = Punk::OAuth2::safe_url($url, $allow_local);

The SSRF guard, applied to any URL that arrived from a third party -
in practice, everything an OIDC discovery document offers. Returns
C<(1)> when the URL is safe to fetch, or C<(0, $reason)> when it is
not.

By default it requires C<https>, rejects credentials embedded in the
URL, rejects loopback hosts, and then resolves the host and rejects it
if B<any> address it resolves to is private. Checking every address
rather than the first is what makes a DNS name that answers with one
public and one private address useless.

Private means IPv4 C<10/8>, C<127/8>, C<0/8>, C<169.254/16>,
C<172.16/12> and C<192.168/16>, or IPv6 C<::1>, C<fe80::/10>,
C<fc00::/7>.

A true C<$allow_local> relaxes this to "https anywhere, or http to
loopback", for local identity providers in development and tests.

C<$reason> is one of: C<not an absolute URL>, C<credentials in URL>,
C<no host>, C<https required>, C<loopback host>, C<unresolvable host>,
C<private address>, or C<http is only allowed to loopback>.

Note the DNS lookup: this resolves at check time, and something else
connects afterwards. It closes the obvious hole, not a determined
rebinding attack.

=head2 await

	my $value = Punk::OAuth2::await($c, $maybe_future);

The seam that lets one body of code serve both worlds. Given a
L<Punk::Future> it calls C<< $c->await >>, which parks the worker under
Hyperman instead of blocking it; given any other object with a C<get>
method it calls that; given anything else it hands the value straight
back.

This is why the provider and server code has no branches for "are we on
an event loop" - it awaits unconditionally, and a plain value awaits to
itself.

=head1 SEE ALSO

L<Punk::OAuth2::Provider>, whose endpoint discovery is the main
consumer of C<safe_url>, and L<Punk::Plugin::OAuth2>, whose login
routes use C<same_origin_path> and C<base_url>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
