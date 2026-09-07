package Punk::Challenge::Token;

use 5.010;
use strict;
use warnings;
use Punk::Challenge ();    # one dist, one bootstrap

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Challenge::Token - the puzzle and the clearance

=head1 SYNOPSIS

    my %cfg = ( secret => 'k', bits => 16, ttl => 3600, puzzle_ttl => 300 );
    my $subject = Punk::Challenge::Token->subject('192.0.2.7');   # 192.0.2.0/24

    my $puzzle   = Punk::Challenge::Token->issue(\%cfg, $subject, bits => 16);
    my $bits     = Punk::Challenge::Token->verify(\%cfg, $subject, $puzzle, $nonce);

    my $cookie   = Punk::Challenge::Token->clear(\%cfg, $subject, bits => $bits);
    my $ok       = Punk::Challenge::Token->cleared(\%cfg, $subject, $cookie);

    my ($got, $why) = Punk::Challenge::Token->verify(\%cfg, $subject, $solution);

=head1 DESCRIPTION

Issue and verify, without a plugin or an application. This is the module a
test or a command line reaches for; from a request, the plugin is the way in,
and it supplies the configuration and derives the subject from the request.

Everything here is state-free. There is no table, no cache and no replay set.
A solved puzzle presented twice within C<puzzle_ttl> is accepted twice, and
that buys the presenter nothing: a second clearance for the same subject with
the same expiry as the first, which the presenter already holds. What a
replay set would defend, sharing a clearance across a botnet, C<bind>
defends instead.

=head2 The configuration

The same hash the C<plugin> line takes, validated the same way: C<secret> is
required and may be a list, newest first; C<bits>, C<ttl>, C<puzzle_ttl> and
C<bind> have their defaults. See L<Punk::Plugin::Challenge/OPTIONS>.

=head2 The wire shapes

A puzzle is one string, safe in a header, a query string, a data attribute
and JSON without escaping:

    v1.<ts>.<bits>.<salt>.<mac>

A solution is the puzzle, a dot, and a decimal nonce such that the SHA-256
of the whole solution string begins with C<bits> zero bits:

    v1.<ts>.<bits>.<salt>.<mac>.<nonce>

A clearance is the cookie value:

    v1.<exp>.<bits>.<mac>

C<ts> is the issue time and C<exp> the absolute expiry, both epoch seconds.
C<bits> is the difficulty, 1 to 22. C<salt> makes two puzzles issued in the
same second to the same subject distinct; it is not random, because a
puzzle is public the moment it is issued and the MAC is what makes it
unforgeable. C<mac> is the first sixteen bytes of an HMAC-SHA256 under the
secret, base64url, over the other fields and the subject:

    "puzzle\0" . $subject . "\0" . $ts  . "\0" . $bits . "\0" . $salt
    "clear\0"  . $subject . "\0" . $exp . "\0" . $bits

Different domain strings, so a puzzle MAC is never a valid clearance MAC
over the same fields.

The subject a token is bound to is never written into it. It is an input to
the MAC, so a token presented from a different subject fails the MAC and the
verifier cannot tell that case from a forgery, which is the point: there is
nothing in the token for a client to edit.

The version prefix is there so a later release can change any of it without
a flag day: a C<v1> cookie under a C<v2> plugin is simply not a clearance,
and the client solves once more.

=head1 METHODS

=head2 key

Thirty-two random bytes as base64url, for the plugin's C<secret>: what
C<punk challenge key> prints. Croaks when no entropy source is available
rather than returning anything an attacker could predict.

=head2 subject($addr, $bind)

The subject an address has under a binding: C<prefix>, the default, is the
/24 of an IPv4 address and the /64 of an IPv6 one; C<ip> is the address
exactly; C<none> is the empty string. An address that is neither IPv4 nor
IPv6 text is used exactly as given.

=head2 issue(\%cfg, $subject, %opts)

A fresh puzzle, signed with the first secret. C<bits> overrides the
configuration's; C<now> overrides the clock, for a test.

=head2 verify(\%cfg, $subject, $puzzle, $nonce, %opts)

The puzzle's own difficulty when the solution is correct for this subject,
else C<undef>. C<$nonce> C<undef> means C<$puzzle> already carries it. In
list context a second value names which check refused: C<shape>, C<stale>,
C<future>, C<mac>, C<bits> or C<hash>; C<ok> when none did.

The checks run cheapest first: the shape, with every field's length capped
before anything is computed; freshness, C<ts> within C<puzzle_ttl> of now
and not in the future by more than sixty seconds; the MAC, recomputed for
this subject against each secret in turn and compared in constant time;
C<bits> at least what C<bits> in the options demands, the configuration's
when unsaid; then one hash of the solution. Two hashes for a correct
solution, one for a wrong one.

=head2 clear(\%cfg, $subject, %opts)

A clearance for this subject at C<bits>, expiring C<ttl> from C<now>.

=head2 cleared(\%cfg, $subject, $value, %opts)

The clearance's difficulty when it is valid for this subject, unexpired,
and at or above C<bits>, else C<undef>. In list context the reason follows:
C<shape>, C<expired>, C<mac> or C<bits>. One HMAC and two comparisons.
C<bits> is in the clearance so that raising a rule's difficulty invalidates
the clearances that were bought cheaper, immediately, with no state.

=head1 SEE ALSO

L<Punk::Plugin::Challenge>, L<Punk::Challenge::Solver>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
