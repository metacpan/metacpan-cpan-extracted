package Punk::Auth::Password;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.17';

# The runtime cost. Deliberately a package variable so a test suite can
# `local $Punk::Auth::Password::ITERATIONS = 1_000;` and stay fast; the
# `auth` keyword's iterations option and an explicit argument both win
# over it.
our $ITERATIONS = 60_000;

1;

__END__

=head1 NAME

Punk::Auth::Password - password hashing

=head1 SYNOPSIS

    use Punk::Auth::Password;

    my $stored = Punk::Auth::Password::hash($plain);
    my $ok     = Punk::Auth::Password::verify($plain, $stored);

    if ($ok && Punk::Auth::Password::needs_rehash($stored)) {
        $stored = Punk::Auth::Password::hash($plain);   # upgrade in place
    }

    my $token  = Punk::Auth::Password::token;           # to mail
    my $digest = Punk::Auth::Password::token_digest($token);   # to store

=head1 DESCRIPTION

PBKDF2-HMAC-SHA256 in C, over the SHA-256 this distribution already bundles
for sessions. No library dependency; salts come from the same entropy source
the CSRF tokens use (getentropy where the build found it, /dev/urandom
otherwise - a failure croaks rather than degrade).

The stored form is

    pbkdf2-sha256$<iterations>$<salt base64>$<key base64>

with a 16-byte salt and a 32-byte derived key. The iteration count travels in
the string, so C<verify> always uses the cost a hash was created with and
raising the default needs no migration: C<needs_rehash> reports the old rows
and a login re-hashes with the plaintext in hand.

Every function is also callable as a class method
(C<< Punk::Auth::Password->verify(...) >>); the invocant is skipped.

=head1 FUNCTIONS

=head2 hash($plain, $iterations?)

The stored string. Cost is the explicit argument, else the localizable
C<$Punk::Auth::Password::ITERATIONS> (default 60_000).

=head2 verify($plain, $stored)

True when the password matches. Constant-time over the derived key; an
unparseable or undef stored value is simply false, so a user row with no
password (an invited or federated-only account) can be handed straight in.

=head2 needs_rehash($stored, $iterations?)

True when the stored cost is below the current one, and true for anything
unparseable or missing - failing toward a rehash is always safe, because the
caller only acts on it after a successful C<verify>.

=head2 token

32 random bytes as unpadded url-safe base64 - 43 characters. The plaintext
half of a single-use token: mail it, never store it.

=head2 token_digest($token)

Lowercase SHA-256 hex of the token - the only form storage sees. Looking a
token up by its digest means a leaked table cannot be replayed.

=head1 SEE ALSO

L<Punk::Auth>, L<Punk::Session>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
